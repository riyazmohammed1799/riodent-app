import json

with open(r'c:\Users\riyaz\riodent_claude\qa_test_cases_v2_extracted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

cases = data['Test Cases'][1:]

# Group cases by module
by_mod = {}
for c in cases:
    mod = c.get('B', 'Unknown')
    by_mod.setdefault(mod, []).append(c)

for mod, test_list in by_mod.items():
    print(f"\n==========================================")
    print(f"MODULE: {mod} ({len(test_list)} tests)")
    print(f"==========================================")
    for c in test_list:
        print(f"[{c.get('A')}] {c.get('F')} (Priority: {c.get('D')}, Suite: {c.get('E')})")
        print(f"   Steps: {repr(c.get('G'))[:100]}...")
        print(f"   Expected: {repr(c.get('H'))[:100]}...")
