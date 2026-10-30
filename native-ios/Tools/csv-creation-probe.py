#!/usr/bin/env python3
"""Stage a disposable native app with a synthetic CSV already selected for UI testing.
Production source is unchanged; only the copied import screen's initial @State differs.
Never pass a private export. Build the printed project, then run the gated UI test.
"""
import json
import pathlib
import shutil
import sys

root = pathlib.Path(__file__).resolve().parents[1]
target = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/wealthone-csv-creation-probe')
target.mkdir(parents=True, exist_ok=False)
for name in ['App', 'Watch', 'Complication', 'RecoveryApp', 'Shared', 'Sources', 'Tests', 'UITests', 'WealthOne.xcodeproj']:
    shutil.copytree(root / name, target / name)
shutil.copy2(root / 'Package.swift', target / 'Package.swift')
csv = 'Date,Total,Assets,Liabilities,First import,Second import,Note,\n1 Jan 2025,300,300,0,100,200,,\n'
view = target / 'App/Views/SettingsViews.swift'
source = view.read_text()
needle = '@State private var document: WealthCSVDocument?'
assert source.count(needle) == 1
source = source.replace(needle, needle + ' = try? WealthCSVDocument.parse(Data(' + json.dumps(csv) + '.utf8))')
source = source.replace('@State private var offerAccountCreation = false', '@State private var offerAccountCreation = true')
view.write_text(source)
print(target / 'WealthOne.xcodeproj')
