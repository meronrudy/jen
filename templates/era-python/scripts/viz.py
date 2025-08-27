#!/usr/bin/env python3
import json, os, sys

def main():
    os.makedirs("figures", exist_ok=True)
    src = "runs/primary/metrics.json"
    dst = "figures/figure1.txt"
    if not os.path.exists(src):
        print("Missing metrics; did you run train?", file=sys.stderr)
        return 1
    with open(src) as f:
        data = json.load(f)
    with open(dst, "w") as f:
        f.write(f"Figure1 placeholder: epochs={data.get(epochs)}, lr={data.get(learning_rate)}\\n")
    print(f"Wrote {dst}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
