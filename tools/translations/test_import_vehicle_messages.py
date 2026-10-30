import json
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

from import_vehicle_messages import merge


class ImportTests(unittest.TestCase):
    def test_preserve_deduplicate_and_escape(self):
        with tempfile.TemporaryDirectory() as folder:
            ts = Path(folder) / "test.ts"
            pending = Path(folder) / "pending.jsonl"
            original = ('<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>\n'
                        '<TS version="2.1" language="zh_CN"><context><name>VehicleMessages</name>'
                        '<message><source>Known</source><translation>已有译文</translation></message>'
                        '</context></TS>')
            ts.write_text(original, encoding="utf-8")
            record = lambda text: json.dumps({"context": "VehicleMessages", "source": text})
            pending.write_text('\n'.join([record("Known"), record("New <value> & %1"),
                                          record("New <value> & %1"), '{partial']), encoding="utf-8")
            self.assertEqual(merge(pending, ts, True), (1, 1))
            self.assertEqual(ts.read_text(encoding="utf-8"), original)
            self.assertEqual(merge(pending, ts), (1, 1))
            tree = ET.parse(ts)
            messages = tree.findall("./context/message")
            self.assertEqual(messages[0].findtext("translation"), "已有译文")
            self.assertEqual(messages[1].findtext("source"), "New <value> & %1")
            self.assertEqual(messages[1].find("translation").get("type"), "unfinished")
            saved = ts.read_bytes()
            self.assertEqual(merge(pending, ts), (0, 1))
            self.assertEqual(ts.read_bytes(), saved)

    def test_create_context_and_keep_other_context(self):
        with tempfile.TemporaryDirectory() as folder:
            ts = Path(folder) / "test.ts"
            pending = Path(folder) / "pending.jsonl"
            ts.write_text('<TS><context><name>Other</name><message><source>Same</source>'
                          '<translation>其他上下文</translation></message></context></TS>', encoding="utf-8")
            pending.write_text(json.dumps({"context": "VehicleMessages", "source": "Same"}), encoding="utf-8")
            self.assertEqual(merge(pending, ts), (1, 0))
            self.assertEqual(len(ET.parse(ts).findall("context")), 2)

    def test_registry_retains_known_sources_and_escapes_cpp(self):
        with tempfile.TemporaryDirectory() as folder:
            ts = Path(folder) / "test.ts"
            pending = Path(folder) / "pending.jsonl"
            registry = Path(folder) / "catalog.h"
            ts.write_text('<TS><context><name>VehicleMessages</name><message><source>Known</source>'
                          '<translation>已完成</translation></message></context></TS>', encoding="utf-8")
            pending.write_text(json.dumps({"context": "VehicleMessages", "source": 'New "quoted" %1'}), encoding="utf-8")
            merge(pending, ts, True, registry)
            self.assertFalse(registry.exists())
            merge(pending, ts, registry=registry)
            header = registry.read_text(encoding="utf-8")
            self.assertIn('"Known"', header)
            self.assertIn('"New \\"quoted\\" %1"', header)
            self.assertEqual(merge(pending, ts, registry=registry), (0, 0))
            self.assertEqual(registry.read_text(encoding="utf-8"), header)


if __name__ == "__main__":
    unittest.main()
