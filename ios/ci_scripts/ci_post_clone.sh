#!/bin/sh

# Xcode Cloud post-clone hook.
# 빈 CI 머신에 Flutter SDK 를 깔고 Generated.xcconfig 와 Pods 를 만들어둔다.
# 로컬 노트북 환경과 동일한 Flutter 버전(3.41.7)을 고정해서 빌드 차이를 차단.

set -e
set -x

FLUTTER_VERSION="3.41.7"

echo "Installing Flutter ${FLUTTER_VERSION}"
git clone https://github.com/flutter/flutter.git -b "${FLUTTER_VERSION}" --depth 1 "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter precache --ios

echo "Resolving pub dependencies"
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

echo "Installing CocoaPods"
cd ios
pod install

echo "Post-clone done"
