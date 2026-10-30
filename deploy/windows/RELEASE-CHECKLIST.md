# FutureWings Windows delivery

Run from the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\package-futurewings.ps1
```

For the Qt Creator custom process step, use `powershell.exe` with arguments:

```text
-NoProfile -ExecutionPolicy Bypass -File "C:\futurewing\qgc_clean\tools\package-futurewings.ps1"
```

Replace the old `cpack; Copy-Item` command. This script builds FutureWings Release,
deploys to a fresh directory, checks executable hashes, and copies the installer
to `D:\futurewing_installers` only on success. Its adjacent `.manifest.json`
records the installer/executable hashes. Staging directories remain available
for inspection and can be removed manually when no longer needed.

The first run downloads the current Microsoft x64 VC++ redistributable from
`https://aka.ms/vc14/vc_redist.x64.exe` into the build directory. The script checks
its Microsoft signature and minimum version, and records its hash. For offline
packaging, pass `-VCRedistPath` with an already downloaded official package.

The installer installs the VC++ x64 runtime before removing an earlier app.
Runtime/driver failures stop installation; exit code 3010 marks a reboot as needed.
Driver details are written to `%TEMP%\FutureWings-driver-install.log`.

Packaging success does not constitute functional acceptance. Record these checks
against the exact installer SHA-256 on a clean Windows machine:

- Install without Qt, Visual Studio, source folders or development PATH entries.
- Start as an ordinary user using the installed Start Menu shortcut.
- Check maps, instruments, images and settings persistence after restart.
- Connect UDP and verify actual MAVLink telemetry updates and reconnect behavior.
- Connect a serial device; verify driver, port selection and telemetry reception.
- Exercise GStreamer video if included in the delivery scope.
- Verify upgrade preserves settings; test uninstall and reboot when requested.

Mark unavailable hardware or environments as **not verified**. Never infer these
results from `--simple-boot-test` or compilation success.
