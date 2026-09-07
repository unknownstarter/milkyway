#!/usr/bin/env python3
"""릴리즈 노트 md 하나를 App Store Connect의 4개 로케일에 밀어넣는다.

배경: 0.2.8에서 4개 국어를 열면서 스토어 리스팅 로케일이 ko/en-US/ja/zh-Hans 4개가
됐다. 새 버전마다 **로케일마다 각각** What's New를 채워야 심사 제출 버튼이 열린다.
하나라도 비면 "This field is required"로 막힌다. 매번 손으로 4번 붙여넣지 않으려고 만듦.

사전 준비 (upload_testflight.sh와 동일한 자격증명을 쓴다)
  1) ~/.appstoreconnect/private_keys/AuthKey_<KeyID>.p8
  2) ~/.appstoreconnect/upload.env 에 ASC_KEY_ID / ASC_ISSUER_ID

사용
  python3 scripts/push_release_notes.py                 # pubspec 버전으로 What's New만
  python3 scripts/push_release_notes.py --description   # 설명글까지 같이
  python3 scripts/push_release_notes.py --dry-run       # 뭐가 올라갈지만 확인
  python3 scripts/push_release_notes.py --version 0.2.9 --notes docs/release/0.2.9-release-notes.md

의존성 없음. JWT 서명은 openssl CLI + 표준 라이브러리로 한다
(cryptography/pyjwt 설치를 강요하지 않으려고).
"""

import argparse
import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUNDLE_ID = 'com.whatif.milkyway'
API = 'https://api.appstoreconnect.apple.com/v1'

# md의 (ko) 같은 표기 -> App Store Connect 로케일 코드.
LOCALE_MAP = {
    'ko': 'ko',
    'en': 'en-US',
    'en-us': 'en-US',
    'ja': 'ja',
    'zh': 'zh-Hans',
    'zh-hans': 'zh-Hans',
}

# 사용자 노출 카피 금지 기호 (CLAUDE.md 카피 부호 룰).
FORBIDDEN = {
    '—': 'em dash',
    '–': 'en dash',
    '·': '중간점',
    '“': '곡선따옴표', '”': '곡선따옴표',
    '‘': '곡선따옴표', '’': '곡선따옴표',
    '…': '말줄임표',
}

MAX_LEN = 4000  # whatsNew / description 둘 다 4000자

# 메타데이터를 고칠 수 있는 버전 상태. 심사 대기/심사 중에는 ASC가 잠근다.
EDITABLE_STATES = {
    'PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED',
    'METADATA_REJECTED', 'INVALID_BINARY', 'PENDING_DEVELOPER_RELEASE',
    'READY_FOR_REVIEW',
}


def die(msg):
    print(f'❌ {msg}', file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------- 자격증명 / JWT

def load_credentials():
    env_path = os.path.expanduser('~/.appstoreconnect/upload.env')
    if not os.path.exists(env_path):
        die(f'{env_path} 없음. ASC_KEY_ID / ASC_ISSUER_ID 필요')
    values = {}
    with open(env_path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, v = line.split('=', 1)
            values[k.strip()] = v.strip().strip('"').strip("'")
    key_id = values.get('ASC_KEY_ID')
    issuer_id = values.get('ASC_ISSUER_ID')
    if not key_id or not issuer_id:
        die('ASC_KEY_ID / ASC_ISSUER_ID 비어있음')
    key_path = os.path.expanduser(
        f'~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8')
    if not os.path.exists(key_path):
        die(f'{key_path} 없음')
    return key_id, issuer_id, key_path


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode()


def der_to_raw(der: bytes) -> bytes:
    """openssl이 뱉는 DER ECDSA 서명(SEQUENCE{INTEGER r, INTEGER s})을
    JWS가 요구하는 raw r||s 64바이트로 바꾼다."""
    if der[0] != 0x30:
        raise ValueError('DER SEQUENCE 아님')
    # 길이 필드 건너뛰기(짧은 형식/긴 형식 둘 다).
    idx = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    out = b''
    for _ in range(2):
        if der[idx] != 0x02:
            raise ValueError('DER INTEGER 아님')
        length = der[idx + 1]
        value = der[idx + 2: idx + 2 + length]
        idx += 2 + length
        value = value.lstrip(b'\x00')          # 선행 0 제거
        out += value.rjust(32, b'\x00')        # 32바이트로 좌측 0 패딩
    return out


def make_jwt(key_id, issuer_id, key_path) -> str:
    header = {'alg': 'ES256', 'kid': key_id, 'typ': 'JWT'}
    now = int(time.time())
    payload = {'iss': issuer_id, 'iat': now, 'exp': now + 19 * 60,
               'aud': 'appstoreconnect-v1'}
    signing_input = (b64url(json.dumps(header, separators=(',', ':')).encode())
                     + '.'
                     + b64url(json.dumps(payload, separators=(',', ':')).encode()))
    proc = subprocess.run(
        ['openssl', 'dgst', '-sha256', '-sign', key_path, '-binary'],
        input=signing_input.encode(), capture_output=True)
    if proc.returncode != 0:
        die(f'openssl 서명 실패: {proc.stderr.decode().strip()}')
    return signing_input + '.' + b64url(der_to_raw(proc.stdout))


# ---------------------------------------------------------------- API

def call(token, method, url, body=None):
    req = urllib.request.Request(url, method=method)
    req.add_header('Authorization', f'Bearer {token}')
    if body is not None:
        req.add_header('Content-Type', 'application/json')
        req.data = json.dumps(body).encode()
    try:
        with urllib.request.urlopen(req) as res:
            raw = res.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors='replace')
        try:
            errors = json.loads(detail).get('errors', [])
            detail = '\n  '.join(
                f"{x.get('title')}: {x.get('detail')}" for x in errors)
        except Exception:
            pass
        die(f'{method} {url}\n  HTTP {e.code}\n  {detail}')


# ---------------------------------------------------------------- md 파싱

def _blocks_in(section: str) -> dict:
    """'## 한국어 (ko)' 다음의 첫 코드펜스 내용을 로케일별로 뽑는다."""
    out = {}
    pattern = re.compile(
        r'^##\s+.*?\(([A-Za-z\-]+)\)\s*$(.*?)(?=^##\s|\Z)',
        re.MULTILINE | re.DOTALL)
    for m in pattern.finditer(section):
        tag = m.group(1).lower()
        locale = LOCALE_MAP.get(tag)
        if not locale:
            continue
        fence = re.search(r'```[a-zA-Z]*\n(.*?)```', m.group(2), re.DOTALL)
        if fence:
            out[locale] = fence.group(1).strip('\n')
    return out


def parse_notes(path):
    """(whatsNew dict, description dict) 반환. 둘 다 로케일 -> 본문."""
    if not os.path.exists(path):
        die(f'{path} 없음')
    text = open(path, encoding='utf-8').read()
    # 최상위 '# ' 헤딩으로 자른다. 첫 섹션 = 릴리즈 노트, '앱 소개/Description' = 설명글.
    parts = re.split(r'^#\s+(.+)$', text, flags=re.MULTILINE)
    whats_new, description = {}, {}
    for i in range(1, len(parts), 2):
        title, body = parts[i], parts[i + 1]
        if re.search(r'앱 소개|Description', title, re.IGNORECASE):
            description = _blocks_in(body)
        elif not whats_new:
            whats_new = _blocks_in(body)
    return whats_new, description


def check_copy(field, locale, body, strict=True):
    problems = []
    for ch, name in FORBIDDEN.items():
        if ch in body:
            problems.append(f'{name} ({ch!r})')
    if len(body) > MAX_LEN:
        problems.append(f'{len(body)}자 (상한 {MAX_LEN})')
    if problems:
        msg = f'{field}/{locale}: ' + ', '.join(sorted(set(problems)))
        if strict:
            die(f'{msg}\n  --skip-copy-check 로 건너뛸 수 있지만 카피를 고치는 게 맞다')
        print(f'  ⚠ {msg}')


# ---------------------------------------------------------------- main

def pubspec_version():
    for line in open(os.path.join(ROOT, 'pubspec.yaml'), encoding='utf-8'):
        if line.startswith('version:'):
            return line.split(':', 1)[1].strip().split('+')[0]
    die('pubspec.yaml에서 version 못 찾음')


def main():
    ap = argparse.ArgumentParser(
        description='릴리즈 노트 md -> App Store Connect 4개 로케일')
    ap.add_argument('--version', help='버전 문자열 (기본: pubspec.yaml)')
    ap.add_argument('--notes', help='md 경로 (기본: docs/release/<버전>-release-notes.md)')
    ap.add_argument('--description', action='store_true',
                    help='설명글(Description)도 함께 갱신')
    ap.add_argument('--only-description', action='store_true',
                    help='설명글만 갱신(What is New 건드리지 않음)')
    ap.add_argument('--dry-run', action='store_true', help='올리지 않고 내용만 출력')
    ap.add_argument('--skip-copy-check', action='store_true',
                    help='AI 금지 기호/길이 검사 건너뛰기')
    ap.add_argument('--force', action='store_true',
                    help='버전 상태가 수정 불가처럼 보여도 일단 시도')
    args = ap.parse_args()

    version = args.version or pubspec_version()
    notes = args.notes or os.path.join(
        ROOT, 'docs', 'release', f'{version}-release-notes.md')

    whats_new, description = parse_notes(notes)
    want_whats_new = not args.only_description
    want_description = args.description or args.only_description

    if want_whats_new and not whats_new:
        die(f'{notes} 에서 릴리즈 노트 코드블록을 못 찾음')
    if want_description and not description:
        die(f'{notes} 에서 앱 소개(Description) 코드블록을 못 찾음')

    print(f'▶ 버전 {version}')
    print(f'  노트  {os.path.relpath(notes, ROOT)}')
    for field, data, wanted in (('whatsNew', whats_new, want_whats_new),
                                ('description', description, want_description)):
        if not wanted:
            continue
        print(f'  {field}: {", ".join(sorted(data))}')
        for locale, body in data.items():
            check_copy(field, locale, body, strict=not args.skip_copy_check)

    if args.dry_run:
        for field, data, wanted in (('whatsNew', whats_new, want_whats_new),
                                    ('description', description, want_description)):
            if not wanted:
                continue
            for locale in sorted(data):
                print(f'\n--- {field} / {locale} ---\n{data[locale]}')
        print('\n(dry-run, 아무것도 올리지 않음)')
        return

    token = make_jwt(*load_credentials())

    apps = call(token, 'GET', f'{API}/apps?filter[bundleId]={BUNDLE_ID}')['data']
    if not apps:
        die(f'번들 ID {BUNDLE_ID} 앱을 못 찾음')
    app_id = apps[0]['id']

    versions = call(token, 'GET',
                    f'{API}/apps/{app_id}/appStoreVersions'
                    f'?filter[versionString]={version}')['data']
    if not versions:
        die(f'App Store Connect에 {version} 버전이 없음. ASC에서 버전을 먼저 만들 것')
    ver = versions[0]
    state = ver['attributes'].get('appStoreState') or \
        ver['attributes'].get('appVersionState')
    print(f'  상태  {state}')
    if state not in EDITABLE_STATES and not args.force:
        die(f'{version}는 지금 {state} 라 메타데이터가 잠겨 있다.\n'
            '  App Store Connect에서 심사 제출을 취소(Remove from Review)한 뒤 다시 실행하거나,\n'
            '  --force 로 그냥 시도해볼 수 있다(대부분 409로 거절된다)')

    locs = call(token, 'GET',
                f"{API}/appStoreVersions/{ver['id']}/appStoreVersionLocalizations"
                )['data']
    by_locale = {x['attributes']['locale']: x['id'] for x in locs}

    updated = 0
    for locale, loc_id in sorted(by_locale.items()):
        attrs = {}
        if want_whats_new and locale in whats_new:
            attrs['whatsNew'] = whats_new[locale]
        if want_description and locale in description:
            attrs['description'] = description[locale]
        if not attrs:
            print(f'  - {locale}: md에 내용 없음, 건너뜀')
            continue
        call(token, 'PATCH', f'{API}/appStoreVersionLocalizations/{loc_id}',
             {'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id,
                       'attributes': attrs}})
        print(f'  ✅ {locale}: {", ".join(sorted(attrs))}')
        updated += 1

    missing = sorted(set(whats_new) - set(by_locale)) if want_whats_new else []
    if missing:
        print(f'  ⚠ ASC에 없는 로케일(무시됨): {", ".join(missing)}')

    print(f'\n✅ {updated}개 로케일 갱신 완료. App Store Connect에서 확인 후 제출.')


if __name__ == '__main__':
    main()
