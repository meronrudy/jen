#!/usr/bin/env python3
import argparse, json, os, time, hashlib, sys

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--config", required=True)
    args = p.parse_args()

    # Trivial "training" that emits artifacts deterministically
    os.makedirs("runs/primary", exist_ok=True)
    start = time.time()
    metrics = {
        "learning_rate": 0.01,
        "epochs": 1,
        "seed": 42,
        "wall_start": start,
    }
    with open("runs/primary/example.txt", "w") as f:
        f.write("hello JEN\\n")
    with open("runs/primary/metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)

    # Print checksums to stdout for convenience
    for path in ["runs/primary/example.txt", "runs/primary/metrics.json"]:
        print(f"{path} sha256={sha256_file(path)}")

if __name__ == "__main__":
    sys.exit(main())
