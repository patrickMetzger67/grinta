#!/bin/sh
# App Store Connect rejects FFI frameworks (notably objective_c.framework)
# that still contain an x86_64 simulator slice or an IOSSIMULATOR
# LC_BUILD_VERSION tag on arm64. Run after Flutter "Thin Binary".
set -eu

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

APP_PATH="${TARGET_BUILD_DIR:?}/${WRAPPER_NAME:?}"
if [ ! -d "$APP_PATH" ]; then
  echo "strip_simulator_slices: app bundle not found at $APP_PATH"
  exit 0
fi

MINOS="${IPHONEOS_DEPLOYMENT_TARGET:-15.0}"
SDK="${SDK_VERSION:-18.0}"

strip_binary() {
  bin="$1"
  if [ ! -f "$bin" ]; then
    return 0
  fi

  info="$(lipo -info "$bin" 2>/dev/null || true)"
  tmp="${bin}.thin"

  if echo "$info" | grep -q 'x86_64'; then
    echo "strip_simulator_slices: removing x86_64 from $bin"
    lipo -remove x86_64 "$bin" -output "$tmp"
    mv "$tmp" "$bin"
  fi
  if lipo "$bin" -verify_arch i386 >/dev/null 2>&1; then
    echo "strip_simulator_slices: removing i386 from $bin"
    lipo -remove i386 "$bin" -output "$tmp"
    mv "$tmp" "$bin"
  fi

  # Platform 7 = iOS Simulator. Apple rejects that tag even on arm64-only binaries.
  if otool -l "$bin" 2>/dev/null | grep -A6 LC_BUILD_VERSION | grep -q 'platform 7'; then
    echo "strip_simulator_slices: retagging $bin as iOS device (minos $MINOS sdk $SDK)"
    xcrun vtool -arch arm64 -set-build-version ios "$MINOS" "$SDK" -replace -output "$tmp" "$bin"
    mv "$tmp" "$bin"
  fi
}

find "$APP_PATH" -name '*.framework' -type d | while IFS= read -r framework; do
  plist="$framework/Info.plist"
  [ -f "$plist" ] || continue
  name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true)"
  [ -n "$name" ] || continue
  bin="$framework/$name"
  [ -f "$bin" ] || continue

  strip_binary "$bin"

  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "$EXPANDED_CODE_SIGN_IDENTITY" != "-" ]; then
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" \
      --preserve-metadata=identifier,entitlements,flags --timestamp=none "$framework" >/dev/null
  fi
done
