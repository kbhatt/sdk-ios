#!/bin/bash
VERSION=${1-unknown}
CONFIG=${2-Debug}
SDK=${3-5.1}

function build {
  rm -rf build/$CONFIG-*
  xcodebuild -target $1 -configuration $CONFIG -sdk iphonesimulator$SDK build
  xcodebuild -target $1 -configuration $CONFIG -sdk iphoneos$SDK build
  lipo -create build/Debug-iphoneos/lib$1.a build/Debug-iphonesimulator/lib$1.a -o build/lib$1-$VERSION.a
  echo "Built library: lib$1-$VERSION.a"
}

rm -rf build
build MonkeyTalk
build MonkeyTalkMediaPlayer
