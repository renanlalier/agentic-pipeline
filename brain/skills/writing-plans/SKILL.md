---
name: writing-plans
description: Use this skill as the FIRST action when starting a sub-issue, before any code editing. Breaks the task into small steps with exact file paths and verification criteria, in the real context of this repository. Iterate with the human via comments until explicit approval — only implement after that.
source: "Adapted from obra/superpowers (skills/writing-plans), MIT License. https://github.com/obra/superpowers"
---

# Writing plans — detailed planning in repository context

This skill runs BEFORE implementation, not during, and is a DIALOGUE,
not a one-shot publication.

## Before listing tasks, map the files

Look at what already exists in this repository before deciding where
the change lands. Identify which files will be created and which will
be modified.

## Small tasks with verification criteria

Each task needs an exact file path, what changes in that file, and how
to verify that step worked.

## If the change touches a contract

Mark it explicitly in the plan and decide the versioning strategy in
the plan itself — do not defer that decision to implementation time.

## Iteration with human approval (hard gate)

No implementation starts before a human explicitly approves the plan
you presented.

- Open decomposition decision or insufficient context → ask ONE
  question instead of assuming.
- Plan ready → publish it in writing and ask for explicit approval.
- Only count as approval a clear affirmative reply to a plan that YOU
  already presented in a prior turn — never silence or vagueness.
- Re-read the entire conversation each turn, not just the last message.

## Signal that the plan is too vague

A task with no file path, or a verification criterion of "it works
correctly" instead of a specific test — it is not ready.
