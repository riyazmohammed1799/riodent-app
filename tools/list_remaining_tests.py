import json

with open(r'c:\Users\riyaz\riodent_claude\qa_test_cases_v2_extracted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

cases = data['Test Cases'][1:]
by_mod = {}
for c in cases:
    mod = c.get('B', 'Unknown')
    by_mod.setdefault(mod, []).append(c)

mods_to_show = [
    'Auth - Doctor', 'Auth - Admin', 'Profile', 'Doctor - Home',
    'Doctor - Booking', 'Time Slots', 'Doctor - Requests',
    'Admin - Bookings', 'Admin - Dashboard', 'Admin - Doctors, Technicians, Settings',
    'End-to-End', 'UI Quality', 'Security & Rules', 'Performance & Scale'
]

for mod in mods_to_show:
    test_list = by_mod.get(mod, [])
    print(f"\n==========================================")
    print(f"MODULE: {mod} ({len(test_list)} tests)")
    print(f"==========================================")
    for c in test_list:
        print(f"[{c.get('A')}] {c.get('F')} (Priority: {c.get('D')}, Suite: {c.get('E')})")
        print(f"   Expected: {c.get('H')}")
