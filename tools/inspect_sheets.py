import json

with open(r'c:\Users\riyaz\riodent_claude\qa_test_cases_v2_extracted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=== OVERVIEW SHEET ===")
for r in data['Overview'][:15]:
    print(r)

print("\n=== TEST CASES HEADER & FIRST 5 ROWS ===")
header_row = data['Test Cases'][0]
print("Headers:", header_row)
for r in data['Test Cases'][1:6]:
    print(r)

print("\n=== ISSUES & CHANGES HEADER & FIRST 5 ROWS ===")
issues_header = data['Issues & Changes'][0]
print("Issues Headers:", issues_header)
for r in data['Issues & Changes'][1:6]:
    print(r)
