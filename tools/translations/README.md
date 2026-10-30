# MAVLink message translations

`VehicleMessageTranslator` translates display text in the `VehicleMessages` Qt
translation context. The raw MAVLink packet, `textMessageReceived` signal, error
classification, and telemetry logs retain the original text. This currently
covers the STATUSTEXT path, not PX4 EVENT descriptions.

Untranslated text is collected in:

    <Qt AppLocalDataLocation>/translations/vehicle_messages_pending.jsonl

For Windows, this is under `%LOCALAPPDATA%`; the application/organization names
determine its subdirectory (FutureWings, NiceWing, etc.). Find it with PowerShell:

```powershell
Get-ChildItem $env:LOCALAPPDATA -Filter vehicle_messages_pending.jsonl -Recurse -ErrorAction SilentlyContinue
```

The collector deduplicates sources across runs, limits collection to 5000
messages, and keeps example text plus system/component/severity metadata.
Explicit templates normalize test sequence numbers and battery IDs. Other
messages are exact matches: do not replace numbers generically, since that can
change a message's meaning. When English is selected, candidates may include
messages already translated in Chinese; the importer skips existing TS entries.

Import candidates from the repository root:

```powershell
py tools/translations/import_vehicle_messages.py --pending "C:\path\to\vehicle_messages_pending.jsonl" --dry-run
py tools/translations/import_vehicle_messages.py --pending "C:\path\to\vehicle_messages_pending.jsonl"
```

The importer adds missing messages to `translations/qgc_source_zh_CN.ts` in the
`VehicleMessages` context as `<translation type="unfinished"></translation>`.
Existing translations are never replaced. Fill the translations, mark them
finished in Qt Linguist, and rebuild the app. Collection does not translate text
automatically or modify the installed application's bundled QM file.

The importer also updates `src/Vehicle/VehicleMessageCatalog.h` with
`QT_TRANSLATE_NOOP` entries, so lupdate can find runtime sources on future scans.
Commit both the catalog header and the TS file after importing/reviewing.

Seed translations include `test_popup`, `test_popup dialog`, and the sample
battery warning. New firmware messages require a matching translated entry or
an explicitly coded template. Unknown text stays unchanged.

Importer checks:

```powershell
py -m unittest discover -s tools/translations -p "test_*.py"
```
