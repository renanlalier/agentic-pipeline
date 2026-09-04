---
name: evaluate-eligible-repositories
description: Use this skill whenever you need to decide which product repositories are affected by a demand. Covers how to read the real fingerprint of each eligible repository (GitHub description, README, language) received in the prompt and decide relevance by judgment, not keyword matching.
---

# Evaluating eligible repositories

Tactical knowledge. Complements `system.md`, never replaces it.

## What you receive

The prompt includes, for each eligible repository, a block with the
name, the suggested logical role, a domain summary given by the
platform, the repository's actual GitHub description, the primary
language, and a README excerpt — all fetched live when this execution
started.

## Procedure

1. Read the demand carefully, focusing on what it describes
   technically: which behavior is broken or must change, and in which
   layer that likely lives.
2. For each eligible repository, compare what the demand describes with
   what the description, README, and language of that repository suggest
   it does. Don't look for the exact word from the demand — judge
   whether the domain is the same.
3. Apply the `implies` rules from the capability map: if a repository
   clearly belongs, check whether it typically pulls another along.
4. Never propose a repository not in the eligible list you received —
   even if the demand names it explicitly.
5. When uncertain whether to include or exclude, include it and explain
   the uncertainty in `notes`. Too-broad scope is corrected by the human
   at HITL 1; missing scope becomes late, expensive rework.

## Good justification practices

Each `reason` in the `repos` array must cite what specifically in the
fingerprint (the description, README, or demand) led to inclusion —
"seems related" is not an acceptable justification.
