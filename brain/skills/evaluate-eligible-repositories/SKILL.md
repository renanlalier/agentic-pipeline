---
name: evaluate-eligible-repositories
description: Use this skill whenever you need to decide which product repositories are affected by a demand. Covers how to evaluate the live fingerprint of each eligible repository (GitHub description, README, language) and decide relevance and role by judgment, not keyword matching.
---

# Evaluating eligible repositories

Tactical knowledge. Complements `system.md`, never replaces it.

## What you receive

The prompt includes, for each repository discovered in the organization, a block
with the name, the GitHub description, the primary language, and a README
excerpt — all fetched live when this execution started. Infrastructure repos
(pipeline and intake) are excluded before the prompt reaches you.

## Procedure

1. Read the demand carefully, focusing on what it describes technically: which
   behavior is broken or must change, and in which layer that likely lives.
2. For each repository, compare what the demand describes with what the
   description, README, and language suggest that repository does. Don't look
   for the exact word from the demand — judge whether the domain overlaps.
3. Infer the logical role from what the repository actually does:
   - A repository whose primary language and README indicate a UI layer
     (React, Vue, mobile, etc.) maps to `frontend-engineer`.
   - A repository whose primary language and README indicate an API, service, or
     data layer (Kotlin, Go, Python, Node API, etc.) maps to `backend-engineer`.
   - When uncertain, choose the role that best describes what the repo owns and
     say so in `notes`.
4. Consider cross-layer dependencies: a change to an API contract almost always
   requires a corresponding update in the UI layer that consumes it. When a
   backend repo enters scope due to a contract change, evaluate whether the
   frontend repo is also affected.
5. Never propose a repository that was not included in the eligible list you
   received — even if the demand names it explicitly.
6. When uncertain whether to include or exclude, include it and explain the
   uncertainty in `notes`. Too-broad scope is corrected by the human at HITL 1;
   missing scope becomes late, expensive rework.

## Good justification practices

Each `reason` in the `repos` array must cite what specifically in the
fingerprint (the description, README, or demand) led to inclusion —
"seems related" is not an acceptable justification.

Do not produce any output for repositories you decided to exclude. The `repos`
array must contain only included repositories; excluded ones are silently omitted.
