---
name: llama-cu
description: Operate and test macOS desktop apps through accessibility controls and window screenshots. Use for native UI interaction, filling forms, and verifying visible app behavior while the user works in another app.
compatibility: macOS 14 or later. Needs llama-cu on PATH, Accessibility permission, and Screen Recording permission.
---

# llama-cu

Use `llama-cu` for desktop UI tasks. Prefer an app's existing CLI or API
when the task does not require interacting with or verifying its UI.
Commands print compact text; add `--json` for structured results.

## Discover the target

Run `llama-cu doctor` before the first interaction. If a permission is
missing, ask the user to grant it to the app named in the result under
System Settings > Privacy & Security. `doctor --prompt` opens the prompts.
Permission setup is not a reason to try another input mechanism.

Choose a unique session name for the task and pass `--session NAME` on
every call. Pass `--background` too, even though it is the default, to
override inherited legacy environment settings. Commands may run in
separate shells, so do not depend on an earlier `export`.

Select the requested app with `get-app`, using its name, bundle ID, or
`.app` path. Check `list-apps --running` if the identity is ambiguous. For
testing, use the task's dedicated app instance and disposable data. A
session isolates stored targets and element IDs, not app focus or data;
two sessions cannot independently drive the same app instance.

For example, replace this app path and session name with the task's values:

```sh
llama-cu --background --session greendale-form doctor
llama-cu --background --session greendale-form get-app /path/to/Greendale.app
llama-cu --background --session greendale-form get-ax-state-and-screenshot
```

## Observe before choosing an action

Read the tree and open the returned PNG with the host's image-viewing tool.
The tree supplies control identities, values, and actions; the screenshot
shows the rendered result and controls missing from accessibility.

Select the intended window with `--window ID` when needed. Later reads and
`--observe` stay on that window. A dialog may appear among the other
windows; select its ID explicitly before interacting with it.

Use IDs from the latest tree. Every tree read, including `--observe`,
replaces them. Coordinates and element frames are screenshot pixels from
the selected window's top-left corner, including when scaled. Do not use
desktop coordinates or apply a second Retina scaling factor.

## Act on the observed control

- Prefer `click --element ID` and exposed accessibility actions. Use
  `set-value --element ID` to replace a field marked `settable`.
- Use `type-text` when the app needs typing events. Verify the intended
  control has focus within the app; the app need not be frontmost. Avoid
  sending a long sequence through a step that can open a dialog or move focus.
- Use coordinate clicks, scrolling, or dragging when the needed control is
  absent from the tree. Take fresh coordinates after scrolling or layout changes.
- Add `--observe` to actions to obtain the next state and screenshot in
  the same call. Choose the next action from that result.

Read [commands.md](references/commands.md) for text selection, key syntax,
menu actions, output fields, and observation limits. Use
`llama-cu <command> --help` for the full argument list.

## Verify the outcome

Check the result the task requires: the field value changed, the expected
dialog opened, the saved item appeared, or the rendered layout matches.
A successful command only confirms that the tool attempted the action;
apps can ignore background events. A changed field alone does not prove
that a form was submitted or its data persisted.

An `observeError` or `screenshotError` can accompany a successful action.
Recover observation before retrying the mutation: it may already have
taken effect. If the UI is still animating, observe again before deciding.
Report what was verified and which parts remain unverified.

## Recover without taking over the desktop

| Situation | Next step |
|---|---|
| `stale_element` or a missing control | Read a fresh tree and resolve the control again. Increase `--max-nodes` or scroll if the tree is truncated. |
| `window_not_found` | Inspect the app's windows and explicitly select the intended replacement. Do not reuse old coordinates or IDs. |
| `background_unavailable` | Read the reason: the window may lack internal keyboard focus, be hidden/minimized/on another Space, or the operation may be unsupported. Use an exposed accessibility alternative where applicable. |
| Action succeeds but nothing changes | Reobserve, then try a supported semantic alternative. Do not repeatedly send the same unverified action. |
| `app_blocked` | Stop operating that app; do not work around the restriction. |

Read [app-notes.md](references/app-notes.md) when using browser/Electron
content, menus, or controls that ignore input. If no supported background
path remains, report the specific limitation. Foreground input requires
the user's authorization to take over the desktop; never select it as an
automatic fallback. App actions can themselves activate windows or change
the shared clipboard, so avoid known disruptive actions during background work.
