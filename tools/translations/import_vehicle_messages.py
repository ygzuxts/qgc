"""Merge observed MAVLink text into the TS catalog without changing existing entries."""
import argparse
import json
import os
from pathlib import Path
import re
import tempfile
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape


def merge(pending: Path, catalog: Path, dry_run: bool = False, registry: Path | None = None) -> tuple[int, int]:
    original = catalog.read_bytes()
    text = original.decode("utf-8-sig")
    root = ET.fromstring(text)
    contexts = [c for c in root.findall("context") if c.findtext("name") == "VehicleMessages"]
    if len(contexts) > 1:
        raise ValueError("Duplicate VehicleMessages contexts; merge them before importing")
    known = {m.findtext("source", "") for c in contexts for m in c.findall("message")}
    additions = {}
    skipped = 0
    for line in pending.read_text(encoding="utf-8-sig").splitlines():
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
            source = entry.get("source")
            if (entry.get("context") != "VehicleMessages" or not isinstance(source, str)
                    or not source.strip() or len(source) > 4096
                    or any(ord(c) < 32 and c not in "\t\r\n" for c in source)):
                raise ValueError("Invalid message record")
        except (ValueError, AttributeError):
            skipped += 1
            continue
        if source not in known:
            additions[source] = True
    # Keep runtime sources visible to future lupdate scans, which otherwise
    # discard strings that cannot be found in QML/C++ source code.
    if registry is not None:
        registry_text = ('#pragma once\n\n#include <QtCore/QCoreApplication>\n\n'
                         '// Maintained by tools/translations/import_vehicle_messages.py for lupdate.\n'
                         'namespace VehicleMessageCatalog {\ninline const char* const sources[] = {\n')
        registry_text += ''.join(
            '    QT_TRANSLATE_NOOP("VehicleMessages", ' + json.dumps(source, ensure_ascii=True) + '),\n'
            for source in sorted(known | additions.keys()))
        registry_text += '};\n}\n'
        if not dry_run:
            registry.write_text(registry_text, encoding="utf-8")
    if not additions:
        return 0, skipped
    newline = "\r\n" if b"\r\n" in original else "\n"
    block = "".join(
        f"    <message>{newline}"
        f"      <source>{escape(source)}</source>{newline}"
        f"      <translation type=\"unfinished\"></translation>{newline}"
        f"    </message>{newline}"
        for source in sorted(additions)
    )
    if contexts:
        for match in re.finditer(r"<context\b[^>]*>.*?</context>", text, re.S):
            if ET.fromstring(match.group()).findtext("name") == "VehicleMessages":
                offset = match.end() - len("</context>")
                text = text[:offset] + block + text[offset:]
                break
        else:
            raise ValueError("Cannot locate VehicleMessages context")
    else:
        block = (f"  <context>{newline}    <name>VehicleMessages</name>{newline}"
                 + block + f"  </context>{newline}")
        offset = text.rfind("</TS>")
        if offset < 0:
            raise ValueError("Missing TS closing tag")
        text = text[:offset] + block + text[offset:]
    ET.fromstring(text)
    if not dry_run:
        data = text.encode("utf-8")
        if original.startswith(b"\xef\xbb\xbf"):
            data = b"\xef\xbb\xbf" + data
        name = None
        try:
            with tempfile.NamedTemporaryFile(dir=catalog.parent, delete=False) as temp:
                name = temp.name
                temp.write(data)
            os.replace(name, catalog)
        finally:
            if name and os.path.exists(name):
                os.unlink(name)
    return len(additions), skipped


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pending", type=Path, required=True, help="Collected JSONL file")
    parser.add_argument("--ts", type=Path, default=Path(__file__).resolve().parents[2] / "translations/qgc_source_zh_CN.ts")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--registry", type=Path, default=Path(__file__).resolve().parents[2] / "src/Vehicle/VehicleMessageCatalog.h")
    args = parser.parse_args()
    count, skipped = merge(args.pending, args.ts, args.dry_run, args.registry)
    print(f"{'Would add' if args.dry_run else 'Added'} {count} unfinished entries; skipped {skipped} invalid records.")
