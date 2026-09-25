#!/bin/sh

# Xcode Cloud post-clone hook.
# 빈 CI 머신에 Flutter SDK 를 깔고 Generated.xcconfig · SPM 패키지 · Pods 를 만들어둔다.
# 로컬 노트북 환경과 동일한 Flutter 버전을 고정해서 빌드 차이를 차단.
#
# ⚠️ 전역 Flutter 를 올릴 때 이 버전도 같이 올려야 한다. 안 올리면 CI 만 조용히
#    옛 SDK 로 빌드해서, SPM 이 적용되지 않은 채 project.pbxproj 의
#    XCLocalSwiftPackageReference 만 남는 어긋난 상태가 된다.

set -e
set -x

FLUTTER_VERSION="3.47.5"

echo "Installing Flutter ${FLUTTER_VERSION}"
git clone https://github.com/flutter/flutter.git -b "${FLUTTER_VERSION}" --depth 1 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version

# SPM 활성화는 pub get 보다 먼저. 이 설정은 사용자 홈(~/.config/flutter/settings)에
# 저장돼 CI 머신에는 없다. 3.47 은 기본값이 켜짐이지만 기본값에 기대지 않고 명시한다.
flutter config --enable-swift-package-manager

flutter precache --ios

echo "Resolving pub dependencies"
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

# SPM 패키지는 ios/Flutter/ephemeral/ 아래라 .gitignore 대상이다. 클린 클론에는
# 없고 pub get 이 재생성한다. 안 생기면 여기서 죽어야 한다. 그냥 두면 Xcode 가
# 패키지 참조를 못 찾는 단계까지 가서 원인이 멀어진다.
SPM_PACKAGE="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
if [ ! -f "$SPM_PACKAGE" ]; then
  echo "ERROR: SPM 패키지가 생성되지 않았다 ($SPM_PACKAGE)."
  echo "flutter config --enable-swift-package-manager 가 pub get 전에 실행됐는지 확인할 것."
  exit 1
fi
echo "SPM package OK"

# CocoaPods 는 아직 필요하다. SPM 미지원 플러그인 8개가 폴백으로 남아 있다.
# 그 8개가 0 이 되면 이 블록을 지운다.
echo "Installing CocoaPods"
cd ios
pod install

echo "Post-clone done"
