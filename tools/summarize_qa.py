import json

with open(r'c:\Users\riyaz\riodent_claude\qa_test_cases_v2_extracted.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print("=== ALL 24 ISSUES ===")
for r in data['Issues & Changes'][1:]:
    print(f"[{r.get('A', '')}] ({r.get('B', '')}) {r.get('C', '')}")
    print(f"     Change: {r.get('E', '')}")
    print(f"     Test IDs: {r.get('F', '')}\n")

print("=== MODULE BREAKDOWN IN TEST CASES ===")
from collections import Counter
modules = Counter()
priorities = Counter()
types = Counter()
suites = Counter()

for r in data['Test Cases'][1:]:
    modules[r.get('B', 'Unknown')] += 1
    priorities[r.get('D', 'Unknown')] += 1
    types[r.get('C', 'Unknown')] += 1
    suites[r.get('E', 'Unknown')] += 1

print("\nModules:")
for k, v in modules.items():
    print(f"  {k}: {v}")

print("\nPriorities:")
for k, v in priorities.items():
    print(f"  {k}: {v}")

print("\nSuites:")
for k, v in suites.items():
    print(f"  {k}: {v}")
