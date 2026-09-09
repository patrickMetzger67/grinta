# App Store 409 — `objective_c.framework` simulator slice

## Symptom

```
Validation failed (409)
Invalid executable. The "Runner.app/Frameworks/objective_c.framework/objective_c"
executable references an unsupported platform in the x86_64 slice.
Simulator platforms aren't permitted.
```

## Cause

`path_provider_foundation` **2.6.0+** depends on `objective_c` (Dart FFI native
assets). That framework can ship an **x86_64 / IOSSIMULATOR** slice into the
release IPA. Apple rejects it. Builds that used **2.5.1** (no `objective_c`)
uploaded fine (e.g. `1.0.23+23`).

## Fix in this repo

`pubspec.yaml` pins:

```yaml
dependency_overrides:
  path_provider_foundation: 2.5.1
```

After changing the pin:

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

Bump the `+build` number before re-uploading to App Store Connect.

## Do not

- Unzip the IPA, `lipo` the binary, and re-zip (breaks code signature).
- Leave `path_provider_foundation` on 2.6.x without a post-archive
  `lipo` + `vtool` + re-export pipeline (fragile).

## References

- https://github.com/dart-lang/native/issues/2989
- Stack Overflow: pin `path_provider_foundation: 2.5.1`
