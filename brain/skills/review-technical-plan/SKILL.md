---
name: review-technical-plan
description: >
  Guides the Tech Lead in reviewing an engineer's technical plan against the
  Task Brief and Integration Contracts. Produces an approval or a revision
  request with specific, actionable feedback.
---

# Skill: Review Technical Plan

## When this skill applies

When your prompt contains `MODE: PLAN_REVIEW`, you are reviewing an engineer's
proposed technical plan. Your job is to determine whether the plan is complete,
correct, and consistent with the approved Integration Contracts.

## Goal

The engineer has no further access to you during implementation. Your review
is the final gate before code is written. A plan you approve defines exactly
what gets built — approve only what you would be confident implementing yourself.

## Evaluation checklist

Work through each dimension in order. For each one, cite specific evidence from
the plan (or note its absence).

### 1. Brief coverage

Does the plan address **every item** in the `## Task Brief` section of the
sub-issue body?

- Flag any brief item that the plan ignores, defers without explanation, or
  describes at a level too vague to implement.
- A plan that covers 80% of the brief is not approvable — the missing 20% will
  become a surprise during implementation.

### 2. Contract conformance

Does the plan use **exactly the endpoints, event names, and payload schemas**
defined in the `## Integration Contracts` section?

- Flag any endpoint path, HTTP method, field name, or schema that the plan
  describes differently from the contract.
- Flag any endpoint the plan calls that is not in the contracts.
- Flag any response field the plan expects that is not in the contracts.
- A plan that adds its own interpretation of a contract is not approvable.

### 3. Scope correctness

Is every item the plan proposes within **this repository's responsibility**?

- The `## Task Brief` has an "Out of scope for this repo" section — verify
  the plan does not propose work listed there.
- Flag any work that belongs to the counterpart repository.
- Flag any infrastructure, schema migration, or shared library change that was
  not explicitly assigned to this repo in the brief.

### 4. Execution order

Is the sequence of implementation steps **internally consistent**?

- Can each step start without depending on work from a later step?
- If the plan calls an external endpoint: does the plan account for the
  possibility that the counterpart repo's implementation is not yet deployed?
  (e.g., using feature flags, mocks, or conditional fallbacks during development)
- Flag circular dependencies or steps whose order would leave the system in a
  broken intermediate state.

### 5. Error handling

Does the plan address **failure modes** for every contract integration?

For REST contracts, check:
- What does the plan do when the endpoint returns a 4xx (e.g., 401, 422, 404)?
- What does the plan do on a 5xx or timeout?

For event contracts, check:
- What happens if the event is malformed or has unexpected fields?
- What happens if the consumer is temporarily unavailable?

A plan that only describes the happy path is not approvable.

### 6. Testability

Can the plan's implementation be **verified without manual intervention**?

- Does the plan mention how each contract integration will be tested?
  (e.g., unit test with mock, integration test against real endpoint, contract test)
- Does the plan describe how to verify that the error-handling paths work?
- A plan with no testing strategy is not approvable — "we'll test it later" is
  not a strategy.

---

## Outcome

After applying the checklist, reach one of two conclusions:

### Approve

If all six dimensions pass:
- Summarize what the plan gets right (one paragraph).
- End with `<!-- codex:status:approved -->`.

### Request revision

If one or more dimensions fail:
- List each failing dimension as a numbered item.
- For each failure, quote the specific plan text (or note its absence) and
  explain exactly what must be added or corrected.
- Do not approve partially — if even one dimension fails, the plan is not ready.
- End with `<!-- codex:status:revision-needed -->`.

### Escalate

If the sub-issue body is missing the Task Brief or Integration Contracts entirely,
you cannot perform a meaningful review. Escalate:
- Explain what is missing.
- End with `<!-- codex:status:escalated -->`.

---

## Rules

- **Never approve a plan that violates the Integration Contracts.** A conformant
  implementation of a wrong plan creates integration failures at runtime.
- **Cite evidence.** Every finding must reference a specific line or section of
  the plan or the contracts. Vague findings ("the plan is incomplete") are not
  actionable.
- **Be specific about what to fix.** A revision request must give the engineer
  enough information to fix the plan without asking you again.
- **Do not propose new contracts.** If a contract is missing, escalate — you
  are reviewing the plan, not defining new scope.
