"""Inventory literal STATUSTEXT calls; dynamic expressions remain review items.

Run in WSL: python3 /mnt/c/futurewing/qgc_clean/tools/translations/scan_px4_messages.py
    --root ~/PX4-Autopilot --out /mnt/c/futurewing/qgc_clean/tools/translations/px4_inventory
"""
import argparse
import ast
import collections
import json
from pathlib import Path
import re
import subprocess

TOKEN = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_]\w*|[^\s]', re.S)
CALL = re.compile(r'mavlink_log_(?:info|warning|critical|emergency|alert|notice|debug)$')


def extract(text):
    tokens = [(m.group(), m.start()) for m in TOKEN.finditer(text)
              if not m.group().startswith(('//', '/*'))]
    for i, (name, offset) in enumerate(tokens):
        if not CALL.fullmatch(name) or i + 1 >= len(tokens) or tokens[i + 1][0] != '(':
            continue
        args, current, depth = [], [], 0
        for value, _ in tokens[i + 2:]:
            if value == ')' and depth == 0:
                args.append(current)
                break
            if value == ',' and depth == 0:
                args.append(current)
                current = []
                continue
            if value in ('(', '[', '{'):
                depth += 1
            elif value in (')', ']', '}'):
                depth -= 1
            current.append(value)
        expression = args[1] if len(args) > 1 else []
        source = None
        if expression and all(v.startswith('"') for v in expression):
            try:
                source = ''.join(ast.literal_eval(v) for v in expression)
            except (ValueError, SyntaxError):
                pass
        yield dict(line=text.count('\n', 0, offset) + 1, call=name,
                   source=source, expression=' '.join(expression),
                   kind='unresolved' if source is None else
                   'template' if re.search(r'%(?!%)', source.replace('%%', '')) else 'literal')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    if not (args.root / 'src').is_dir():
        parser.error('root must contain PX4 src directory')
    records = []
    for path in sorted((args.root / 'src').rglob('*')):
        if path.suffix not in ('.cpp', '.c', '.h', '.hpp'):
            continue
        for record in extract(path.read_text(encoding='utf-8', errors='replace')):
            records.append(dict(file=str(path.relative_to(args.root)), **record))
    args.out.mkdir(parents=True, exist_ok=True)
    def write(name, value):
        (args.out / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write('statustext.json', records)
    fixed = sorted({r['source'] for r in records if r['kind'] == 'literal'})
    (args.out / 'literal_candidates.jsonl').write_text(''.join(
        json.dumps(dict(context='VehicleMessages', source=s), ensure_ascii=False) + '\n'
        for s in fixed), encoding='utf-8')
    version = subprocess.run(['git', '-C', str(args.root), 'describe', '--always', '--dirty'],
                             capture_output=True, text=True)
    summary = dict(revision=version.stdout.strip(), calls=len(records),
                   kinds=dict(collections.Counter(r['kind'] for r in records)),
                   unique_literal_candidates=len(fixed),
                   limitations='Source candidates only; not build-filtered. Dynamic templates and EVENT require separate integration.')
    write('summary.json', summary)
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
