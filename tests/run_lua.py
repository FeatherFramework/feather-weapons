"""Run current Lua 5.4 specs in isolated VMs; no RedM or database required."""
import argparse
import os
from pathlib import Path
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--lupa-dir', type=Path)
args = parser.parse_args()
if args.lupa_dir:
    sys.path.insert(0, str(args.lupa_dir.resolve()))
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
runtime_files = [root / 'fxmanifest.lua', root / 'config.lua']
for folder in ('client', 'server', 'shared', 'translations'):
    runtime_files.extend((root / folder).rglob('*.lua'))
syntax = LuaRuntime()
for path in sorted(runtime_files):
    syntax.execute('assert(load(...))', path.read_text(encoding='utf-8-sig'), '@' + path.as_posix())
print(f'PASS Lua 5.4 syntax ({len(runtime_files)} files)', flush=True)

suites = sorted((root / 'tests').glob('*spec.lua'))
if not suites:
    raise SystemExit('No current Lua specs found')
for path in suites:
    print(f'Running {path.relative_to(root).as_posix()}', flush=True)
    isolated = LuaRuntime(unpack_returned_tuples=True)
    isolated.globals().arg = isolated.table_from({1: root.as_posix()})
    isolated.execute('dofile(...)', path.as_posix())
print(f'PASS {len(suites)} isolated Lua specs', flush=True)
