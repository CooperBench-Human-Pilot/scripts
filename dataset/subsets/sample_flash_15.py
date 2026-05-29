import json
import random

with open("flash_dataset.json") as f:
    data = json.load(f)

# Collect all (task, pair) combos
all_pairs = []
for task in data["tasks"]:
    for pair in task["pairs"]:
        all_pairs.append((task, pair))

random.seed(42)
selected = random.sample(all_pairs, 15)

# Rebuild tasks list preserving only selected pairs
tasks_map = {}
for task, pair in selected:
    key = (task["repo"], task["task_id"])
    if key not in tasks_map:
        tasks_map[key] = {"repo": task["repo"], "task_id": task["task_id"], "pairs": []}
    tasks_map[key]["pairs"].append(pair)

output = {
    "name": "flash_15",
    "description": "15-pair random sample from flash dataset",
    "stats": {
        "tasks": len(tasks_map),
        "pairs": 15,
        "repos": len({task["repo"] for task in tasks_map.values()}),
    },
    "tasks": list(tasks_map.values()),
}

with open("flash_15_dataset.json", "w") as f:
    json.dump(output, f, indent=2)

print(f"Saved {len(selected)} pairs across {output['stats']['tasks']} tasks to flash_15_dataset.json")
