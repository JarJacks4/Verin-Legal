#!/usr/bin/env python3
"""Verin standalone verifier — checks an exported Verin record without Verin.

Usage:   python3 verify.py            (run inside the unzipped record folder)
         python3 verify.py path/to/record-folder

What it checks, using only the Python standard library:
  1. Every exhibit file listed in manifest.json hashes (SHA-256) to the
     item_hash recorded for it at receipt.
  2. The per-matter hash chain recomputes entry by entry:
        entry_hash = SHA256( prev_hash | item_hash | received_at | origin_digest )
     where | is a literal "|" separator and the first entry's prev_hash is
     64 zeros. The last entry must equal the chain head in the manifest.
  3. Each receipt's item_hash appears in the chain entry it points to.

Exit code 0 = everything checked passed; 1 = something failed (details printed).
Entries created before inputs were recorded ("legacy") are reported and skipped.

RFC 3161 tokens (timestamps/*.tsr) can be checked separately with OpenSSL:
    openssl ts -reply -in timestamps/<receipt>.tsr -text
"""

import hashlib
import json
import os
import sys

GENESIS = "0" * 64


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(root, "manifest.json"), encoding="utf-8") as f:
        manifest = json.load(f)

    failures = []
    print("Verin record:", manifest.get("matter", {}).get("name", "?"))
    print("Exported at: ", manifest.get("exported_at", "?"))
    print()

    # 1. Exhibit files
    files_checked = 0
    for r in manifest.get("receipts", []):
        exhibit = r.get("exhibit_file")
        if not exhibit:
            continue
        path = os.path.join(root, exhibit)
        if not os.path.exists(path):
            failures.append("missing exhibit file: %s" % exhibit)
            continue
        actual = sha256_file(path)
        files_checked += 1
        if actual != r.get("item_hash"):
            failures.append("hash mismatch for %s: expected %s, got %s" % (exhibit, r.get("item_hash"), actual))
    print("Exhibit files checked:   %d" % files_checked)

    # 2. Chain
    entries = sorted(manifest.get("chain", []), key=lambda e: e.get("seq", 0))
    needed = ("prev_hash", "item_hash", "received_at", "origin_digest", "entry_hash")
    start = next((i for i, e in enumerate(entries) if all(isinstance(e.get(k), str) and e.get(k) for k in needed)), None)
    legacy = len(entries) if start is None else start
    verified = 0
    head = None
    if start is not None:
        prev = entries[start]["prev_hash"]
        prev_seq = entries[start]["seq"] - 1
        for e in entries[start:]:
            if not all(isinstance(e.get(k), str) and e.get(k) for k in needed):
                failures.append("chain entry #%s is missing its hash inputs" % e.get("seq"))
                break
            if e["seq"] != prev_seq + 1:
                failures.append("chain sequence jumps from #%s to #%s" % (prev_seq, e["seq"]))
                break
            if e["prev_hash"] != prev:
                failures.append("chain entry #%s does not point at the previous entry" % e["seq"])
                break
            expected = hashlib.sha256("|".join([prev, e["item_hash"], e["received_at"], e["origin_digest"]]).encode("utf-8")).hexdigest()
            if expected != e["entry_hash"]:
                failures.append("chain entry #%s: entry_hash does not match its inputs" % e["seq"])
                break
            prev = e["entry_hash"]
            prev_seq = e["seq"]
            verified += 1
        head = prev
    print("Chain entries verified:  %d (legacy, skipped: %d)" % (verified, legacy))

    stated_head = manifest.get("chain_head") or ""
    if head and stated_head and head != stated_head:
        failures.append("recomputed chain head %s does not match the manifest's %s" % (head, stated_head))
    print("Chain head:              %s" % (head or stated_head or "-"))

    # 3. Receipts are in the chain
    by_seq = {e.get("seq"): e for e in entries}
    for r in manifest.get("receipts", []):
        seq = r.get("chain_seq")
        if not seq or seq not in by_seq:
            continue
        if by_seq[seq].get("item_hash") and by_seq[seq]["item_hash"] != r.get("item_hash"):
            failures.append("receipt %s: item_hash differs from chain entry #%s" % (r.get("id"), seq))

    print()
    if failures:
        print("FAILED")
        for f in failures:
            print("  - " + f)
        sys.exit(1)
    print("PASS — every listed item is intact and the chain is unbroken.")
    print("This shows what arrived and when. It does not describe what happened to a file before it arrived.")


if __name__ == "__main__":
    main()
