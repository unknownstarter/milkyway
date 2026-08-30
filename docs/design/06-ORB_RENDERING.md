# 06 - 오브 렌더링: 프래그먼트 셰이더 설계 (재사용 문서)

> 상태: 설계 (2026-08-30) · 다른 프로젝트에서도 "고품질 절차적 구(球)/행성/오브"가 필요하면 이 문서 그대로 이식.
> 배경: 초기에 PNG 레이어(core/glass) + 네이티브 그라데이션 안개로 만들었으나 **품질이 근사치**(유리·안개가 물리적으로 안 맞고, 티어별 정적 자산 12장). → **단일 프래그먼트 셰이더**로 GPU 실시간 렌더로 전환.

## 0. 목표
밤하늘 유리구 안에 은하가 돌고, 유리 반사(광원 고정)와 프레넬 림, 바깥 안개가 물리적으로 자연스러운 **프리미엄 오브**. 티어(6단계)별로 색/밀도/나선팔이 uniform으로 동적. 자산 = `.frag` 하나(초경량).

## 1. 방법 비교 & 결정
| 방법 | 품질 | 무게 | 동적 | 미리보기(flutter_test) | 결정 |
|---|---|---|---|---|---|
| 네이티브 그라데이션/BoxShadow | 낮음(근사) | 0 | O | O | ❌ 게으른 hack |
| PNG 레이어(core/glass) | 중 | 12장 320KB | 티어만 | O(캡처) | 과도기 |
| Lottie(JSON) | 중상 | 중 | 제한 | 대체로 O | 3D 유리엔 부적합 |
| Rive(.riv) | 높음 | 소 | O(상태머신) | 대체로 O | 디자이너/에셋 필요 |
| **프래그먼트 셰이더(GLSL)** | **최고** | **.frag 1개** | **완전(uniform)** | ❌(헤드리스 렌더 X) | ✅ **채택** |

셰이더 채택. 유일한 비용 = flutter_test로 미리보기 불가 → **시뮬레이터 스샷 검증**(§4).

## 2. 셰이더 설계 (`shaders/orb.frag`)
좌표: `uv = FlutterFragCoord().xy / uSize`; 중심화 `p = (uv*2-1)`, 종횡비 보정. `r = length(p)`.

**구 재구성(3D 노멀)**: 구 내부 `r < 1`에서 `z = sqrt(1 - r*r)` → 표면 노멀 `N = normalize(vec3(p, z))`. 이걸로 3D 조명.

**은하(회전 레이어)** — 구 표면 좌표를 `uTime`으로 회전:
- 극좌표 `ang = atan(p.y,p.x) + uTime*SPEED`, `rad = r`.
- **나선팔**: `arm = cos(ang*uArms + rad*SPIRAL - uTime*SPEED)` → 팔 밝기.
- **성운**: `fbm(rotate(p)*scale)` (옥타브 5 고정) → 구름. 색 = `mix(uCore, uTier, fbm)`.
- **별필드**: `hash(floor(p*grid))` 임계 → 점별(밀도 `uDensity`). 중심일수록 밝게(`1-rad`).
- 합성: 성운 + 팔 + 별, 중심 코어 글로우(`uCore`, `smoothstep`).

**유리(고정 레이어)** — 광원 방향 `L = normalize(vec3(-0.4,0.5,0.8))` **상수(안 돎)**:
- **프레넬 림**: `fres = pow(1.0 - N.z, 3.0)` → 가장자리 빛.
- **스펙큘러**: `spec = pow(max(dot(reflect(-L,N), V), 0), 40)` (V=viewDir≈(0,0,1)) → 좌상단 하이라이트.
- **깊이 음영**: 가장자리(`r→1`)로 갈수록 어둡게 → 3D 볼륨.

**안개(구 바깥)** — `r > 1`: `fog = exp(-(r-1)*FALL) * uTier` → 부드러운 방사형 haze. `uGlow`(호흡)로 밝기 변조.

**엣지 AA**: `alpha = smoothstep(1.0+FEATHER, 1.0-FEATHER, r)` (구), 안개는 fog 알파.

**합성 순서**: 안개(바깥) → 은하(회전) → 유리 하이라이트(고정) → 깊이음영.

**Uniforms**:
```
uniform vec2  uSize;      // 위젯 픽셀 크기
uniform float uTime;      // 회전 + 애니메이션(초)
uniform float uGlow;      // 0..1 안개/글로우 호흡
uniform vec3  uTier;      // 티어 액센트색
uniform vec3  uCore;      // 코어색
uniform float uArms;      // 나선팔 수(0=성운, 2~4)
uniform float uDensity;   // 별/성운 밀도
uniform float uSeed;      // 티어별 변주
```

## 3. Flutter 통합
- `pubspec.yaml`:
  ```yaml
  flutter:
    shaders:
      - shaders/orb.frag
  ```
- 로드: `final program = await ui.FragmentProgram.fromAsset('shaders/orb.frag');`
- 렌더: `CustomPainter`에서 `shader = program.fragmentShader()..setFloat(...)..setFloat(...)`; `canvas.drawRect(rect, Paint()..shader = shader)`.
- 애니메이션: `AnimationController`(반복) → `paint`마다 `setFloat(uTime, controller.lastElapsedDuration)`; `shouldRepaint => true`.
- 티어: 위젯 파라미터 → uniform. `ShaderOrb(tier, size, animate)` 위젯으로 캡슐화(OrbView 대체).
- **RepaintBoundary로 감싸** 형제 재페인트 격리(별 배경 등).

## 4. 검증 (셰이더는 flutter_test로 미리보기 불가)
- flutter_test는 **헤드리스 소프트웨어 렌더** → 프래그먼트 셰이더 실행 안 됨(빈 화면/에러). 골든/캡처 검증 불가.
- **시뮬레이터 스샷으로 검증**: `flutter run`(디버그, 시뮬) → 오브 화면 진입 → `xcrun simctl io booted screenshot /tmp/x.png` → 눈으로. (글래스앱바 반복검증 때 쓴 방식과 동일)
- Impeller(iOS 기본 렌더러)에서 실제로 도는지 실기기/시뮬 필수. Android(Vulkan/GLES)도 별도 확인.

## 5. 레슨런 & 주의점 ⚠️ (이슈 반드시 터짐)
1. **Impeller vs Skia 셰이더 차이**: Flutter 기본=Impeller. 일부 GLSL 관용구(특정 내장함수, 정밀도)가 Skia와 다르게 동작/컴파일 실패. Impeller 기준으로 작성 + 실기기 검증. `flutter run --enable-impeller`(기본).
2. **`FlutterFragCoord()` 사용**: `gl_FragCoord` 직접 쓰지 말고 Flutter 헬퍼. 좌표계/Y축 뒤집힘 주의.
3. **uniform은 float/vec만**: 배열/구조체/텍스처(sampler) 없이 순수 절차적으로. sampler2D는 `program.fragmentShader()`에 `setImageSampler`로 별도(여기선 불필요).
4. **정밀도**: 별 해시(`fract(sin(dot)*K)`)는 highp 필요. mediump면 큰 좌표에서 별이 뭉개짐/줄무늬. 좌표를 작게 유지.
5. **동적 루프 제한**: 모바일 GPU는 가변 길이 루프에 약함. FBM 옥타브는 **상수(#define OCT 5)** 로 언롤.
6. **성능**: 픽셀당 매 프레임 연산. 큰 오브 + 무거운 FBM = GPU 부담. (a) 구+안개 바깥 픽셀 조기 `discard`/알파0, (b) 옥타브 최소, (c) 위젯 크기 과대 금지, (d) 리스트/썸네일에선 셰이더 대신 정적 이미지 폴백.
7. **셰이더 컴파일 타이밍**: `.frag`는 빌드시 컴파일. 수정 후 **hot reload로 반영 안 될 수 있음 → hot restart/재빌드**. 첫 로드 `fromAsset`은 async → 로딩 상태 처리.
8. **flutter_test 미지원**: 위 §4. 자동 회귀테스트는 로직(uniform 계산)만, 픽셀은 시뮬.
9. **애니메이션 타임 랩**: `uTime`을 무한 증가시키면 float 정밀도 손실(수백초 후 떨림). `uTime = elapsed % PERIOD`로 래핑.
10. **엣지 앨리어싱**: 셰이더 출력엔 MSAA 없음 → 구 경계 `smoothstep`으로 소프트 AA 필수(안 하면 계단).
11. **폴백**: 셰이더 컴파일/로드 실패 시(구형 기기/렌더러) 정적 PNG로 폴백하는 안전장치.

## 6. 재사용 가이드 (다른 프로젝트 이식)
- 필요 파일: `shaders/orb.frag` + `ShaderOrb` 위젯(약 80줄) + pubspec `shaders:` 등록.
- 파라미터화: 색/밀도/나선/속도를 uniform으로 → 어떤 "구/행성/에너지 오브"든 재사용.
- 검증 파이프라인: 시뮬 스샷(§4)을 프로젝트 README에 명시(팀원이 헤매지 않게).
- 성능 예산: 목표 기기에서 60fps 확인, 안 되면 옥타브/크기 조정 or 정적 폴백.

---
## 구현 순서
1. `shaders/orb.frag` 작성(§2) + pubspec 등록.
2. `ShaderOrb` 위젯(§3) — OrbView 대체(같은 인터페이스: tier/size/animate).
3. 시뮬 스샷 검증(§4) + 튜닝(색/밀도/속도/안개).
4. 티어 6단계 uniform 매핑 확인.
5. PNG 레이어 자산/네이티브 안개 제거.
