---
name: brainstorming
description: Use this skill whenever a demand does not yet have a clear enough scope to become technical work. Guides refinement through questions, one at a time, until the human explicitly approves a written final scope. Do not skip this skill even for demands that seem simple.
source: "Adapted from obra/superpowers (skills/brainstorming), MIT License. https://github.com/obra/superpowers"
---

# Brainstorming — asynchronous Socratic refinement

The original skill (superpowers) assumes a live chat where the agent
asks and the person replies in the same session. Here the medium is
asynchronous — each issue comment is a separate turn, with its own
agent execution. The discipline is the same; the mechanics change.

## The hard gate

No sub-issue, no code, no repository proposal happens before a scope
has been presented in writing AND explicitly approved by the human.
This applies even when the demand seems obvious — it is precisely in
"obvious" demands that unexamined assumptions cost the most later.

## Classify before asking

Before the first question, classify the demand mentally:

- **Spike / investigation** — the right answer isn't code; it's an
  investigation. Say so and propose investigating instead of asking.
- **Bounded** — clear scope, few variables. One or two confirmation
  questions are enough before presenting the scope.
- **Architectural** — a decision that shapes multiple repositories or
  changes a contract between them. Deserves more rounds before closing.

## One question per turn

Never accumulate a list of questions in a single comment. Ask the
single most important thing still open. This is slower in number of
turns, but each human response is easier to give — and you learn from
each answer before deciding the next question.

## Presenting the scope

When you believe you have enough, don't ask "can I proceed?" without
showing what will be built. Write the scope in writing, short, from
the point of view of what changes for the user — then ask for explicit
approval.

## What counts as approval

A clear affirmative response to a scope that YOU already presented in
the previous turn. Never treat silence, a question back, or a vague
comment as approval — that is exactly the kind of unexamined assumption
this skill exists to prevent.

## On concluding

The approved scope becomes the canonical description of the demand for
every downstream agent — especially the Tech Lead, who never re-reads
the entire conversation. Write it thinking of that: someone who will
only read the Scope field, not the comment history, must be able to act
on it.
