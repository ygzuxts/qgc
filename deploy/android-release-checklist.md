# NiceWing Android Release

Output directory: `D:\futurewinginstallers` (no underscore).

In Qt Creator select the Android arm64-v8a kit and `Release-nicewing-android`.
Set `QGC_QT_ANDROID_MIN_SDK_VERSION` to `28` and reconfigure CMake. Keep these
build steps in order:

1. Build the NiceWing native target.
2. Build Android APK; sign with the existing `android_release2.keystore`.
3. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File D:\package_nicewing.ps1`.

The final step checks the fixed APK path, package name, ABI, Release status,
CMake version, minimum SDK, original release certificate and native ELF build ID.
It refuses stale or differently signed APKs, then copies the APK and writes a
SHA-256 manifest. It never searches other brands/build folders or signs with a
fallback key. Enter signing passwords in Qt Creator; do not save them in scripts.

For a command-line native rebuild and fresh unsigned APK:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\package-nicewing-android.ps1 -BuildUnsigned
```

This produces `NiceWing-android-release-unsigned.apk` without replacing the signed
release. It must be signed with the original certificate before delivery.
The version code/name come from CMake via the generated manifest, without a
second hardcoded Gradle version. Increment the CMake app version for later releases.

Record installation/upgrade, maps/instruments, UDP telemetry, USB serial and video
on real supported devices. A valid signature or complete build does not verify
those functions. This configuration uses Qt Multimedia, not GStreamer.

Known portability gap: the installed Qt 6.8.3 Android QtCore library has 4 KB
ELF LOAD alignment. Do not mark 16 KB page-size devices as supported without
replacing/rebuilding incompatible Qt/third-party libraries and testing them.
Changing only the application's linker flags cannot fix prebuilt dependencies.
See https://developer.android.com/guide/practices/page-sizes.
