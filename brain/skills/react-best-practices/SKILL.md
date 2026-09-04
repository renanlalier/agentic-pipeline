---
name: react-best-practices
description: Use this skill whenever the repository you are running in is a React project. Covers component conventions, hooks, state, tests with Testing Library, and basic accessibility. Do not use in repositories that are not React.
---

# React — best practices

This is a stack capability skill: teaches HOW to work well in a React
project. It does not tell you what you can or cannot do — that is in
`system.md`, which this skill does not replace.

## Components

- Functional components with Hooks. Do not introduce class components.
- One component per file, file name matching the component name
  (`App.jsx` exports `App`).
- Props typed via PropTypes or JSDoc when the repository does not use
  TypeScript; follow what already exists in the repository before
  choosing.

## Hooks

- Never call a Hook inside a conditional, loop, or nested function.
- `useEffect` always has an explicit dependency array — do not omit it.
- Extract reusable logic into a custom Hook (`useSomething`) instead of
  duplicating `useEffect`/`useState` across components.

## State

- Local state (`useState`) for what only that component and its direct
  children need. Do not lift state to a global level without a real
  sharing need.

## Tests

- Testing Library: test visible user behavior (text on screen, response
  to a click), not internal implementation details.
- Never use a CSS class selector or DOM structure as a primary
  assertion — prefer `getByRole` and `getByText`.

## Basic accessibility

- Every interactive element must be reachable by keyboard.
- An image with semantic content gets `alt`; a decorative image gets
  `alt=""`.

## Signal that something is wrong

If you find yourself manipulating the DOM directly
(`document.querySelector` inside a component) outside a documented
exceptional case, stop — this almost always means the problem should
be solved with state or a React ref, not direct DOM access.
