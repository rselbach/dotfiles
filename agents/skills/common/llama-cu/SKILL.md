---
name: llama-cu
description: Operate desktop apps on macOS. List and launch apps, read a window's accessibility tree, take window screenshots, click, drag, scroll, press shortcuts, type, paste rich text, set control values, and select text. Use when a task needs a GUI app instead of a CLI or API.
compatibility: macOS 14 or later. Needs llama-cu on PATH, plus Accessibility and Screen Recording permission for llama-cu.app, or for the app that runs the agent when llama-cu runs outside the app.
---

# llama-cu

`llama-cu` operates desktop apps through the accessibility API, window
screenshots, and synthetic input. Each call is one shell command that prints
compact text. Add `--json` to get JSON.

## Setup

Run `llama-cu doctor` once. If it reports a missing permission, ask the user
to grant it in System Settings > Privacy & Security to the app that
`doctor` names: llama-cu.app, or the app that runs you, such as the
terminal. `llama-cu doctor --prompt` opens the system prompts. When the
permissions belong to the terminal, the user must restart it after granting
Screen Recording.

## Workflow

1. Select the app: `llama-cu get-app Notes`. Use a name, a bundle ID, or a
   `.app` path. If the app is not running, the command launches it. Later
   commands target this app. An exact name wins over a running app with a
   similar name: `get-app Firefox` launches Firefox even if only Firefox
   Developer Edition is running. Check `llama-cu list-apps --running` when in
   doubt.
2. Observe: `llama-cu get-ax-state-and-screenshot`. This prints the element
   tree and writes a PNG. Open the PNG with your read tool to see it.
3. Act on element IDs: `llama-cu click --element 12`. Add `--observe` to
   print the new state and a screenshot after the action, instead of
   running step 2 again.
4. Observe again before the next decision. Each `get-ax-state` replaces the
   previous element IDs. A `stale_element` error means the UI changed: run
   `get-ax-state` again.

Prefer element IDs to coordinates. Use `--at X,Y` only for things missing
from the tree. Coordinates are window-relative screenshot pixels, the same
as the frames in the tree. Large windows are captured scaled down, and the
tree header says so; coordinates still match the screenshot.

## Experimental background mode

When asked to work without taking over the user's pointer, set
`LLAMA_CU_BACKGROUND=true` for every llama-cu invocation, or pass
`--background` on every command. This mode avoids explicit activation,
window raising, and global input posting. There is no agent cursor overlay
yet. Always observe the result: apps can ignore background events or bring
themselves forward in response to an action.

Observe the intended window before sending input; later observations
without `--window` keep showing it. Keyboard events require that window to
have focus within the selected app, and typing stops if it loses focus.
Pointer coordinates must stay inside the selected window, which must be on
screen: not minimized, hidden, or on another Space. Menus outside it and
simultaneous use of the same app are unsupported. Many views ignore
background left clicks at coordinates, so prefer `click --element`.
Browser/Electron content needs further compatibility testing. Command
shortcuts are rejected because inactive apps can silently ignore them; use
accessibility actions on menu items, `select-text`, or `set-value` instead.

`paste` and `perform-secondary-action raise` return
`background_unavailable`; use `type-text` or `set-value` for text.
Background delivery never falls back to moving the real pointer. If an
action fails or is ignored, report the limitation rather than silently
retrying without background mode.

## Reading the tree

```
[8] window "Groceries"
  [9] toolbar
    [10] button "Share" (612,12 30x24) actions=press,showMenu
  [14] text area value="Milk\nEggs" (220,60 600x500) focused settable
  [15] link [Recipes](https://example.com/recipes) (220,570 60x18) actions=press
[30] menu bar
  [31] menu bar item "File" actions=press,cancel
selected text: "Eggs"
```

Each line shows `[id] role "label"`, optional `value=` and `placeholder=`,
the frame `(x,y width x height)`, state flags (`focused`, `selected`,
`disabled`, `settable`, `checked`, `expanded`), and accessibility actions.
`settable` means `set-value` can replace the value. Links with a target show
as `[label](url)`, and web areas show their address as `url=`. The menu bar
comes last. When a menu is open, its items appear under the menu bar item.
A last `selected text:` line shows the focused element's selection.

Each text shows at most 200 characters, then `... (N chars)`. Run
`get-ax-state --text-limit 2000` or `--text-limit max` to read more.

## Commands

| Command | Use |
|---|---|
| `list-apps [--running]` | List installed apps and running PIDs. |
| `get-app <app>` | Select an app; launch it if needed; list its windows. |
| `get-ax-state [--window ID] [--max-nodes N] [--text-limit N\|max]` | Print the element tree of the focused window, or of window `ID`. |
| `get-screenshot [--window ID] [-o FILE]` | Capture the window as PNG. |
| `get-ax-state-and-screenshot` | Do both for the same window. If the capture fails, the tree still prints. |
| `click (--element ID \| --at X,Y) [--button left\|right\|middle] [--count N]` | Click. Use `--count 2` to double-click. |
| `drag --from X,Y --to X,Y` | Drag with the left button. |
| `scroll [--element ID \| --at X,Y] --direction up\|down\|left\|right [--amount LINES]` | Scroll. Without a target, scroll at the window center. |
| `press-key <combo>...` | Press keys in order, such as `cmd+s` or `down down enter`. |
| `type-text <text\|->` | Type into the focused control. |
| `paste [--format plain\|markdown\|html] <text\|->` | Paste through the clipboard, then restore the clipboard. |
| `set-value [--element ID] <value\|->` | Replace a control's value directly. Defaults to the focused control. |
| `select-text [--element ID] <text> [--position select\|before\|after] [--occurrence N]` | Select the match, or put the cursor before or after it. |
| `perform-secondary-action --element ID <action>` | Run an action from the tree, such as `showMenu`, `increment`, or `raise`. |

Every command from `click` to `perform-secondary-action` accepts `--observe`.

## Tips

- A plain left `click --element` uses the element's press action, and a
  double-click (`--count 2`) uses its open action, so both work even when
  the window is covered. In the default foreground mode, other clicks move
  the real pointer and bring the app to the front first.
- Text entry: use `type-text` for short text. Use `paste` for long text or
  formatted text (`--format markdown` or `--format html`). Use `set-value` to
  replace a field outright. Some apps do not notice `set-value`; if the app
  ignores the new value, type instead.
- Pass long text on standard input with `-`:
  `llama-cu paste --format markdown - <<'EOF'` ... `EOF`.
- Key names: modifiers `cmd`, `ctrl`, `alt` or `option`, `shift`, `fn`,
  joined with `+`. Named keys: `enter`, `tab`, `space`, `backspace`,
  `delete`, `escape`, `up`, `down`, `left`, `right`, `home`, `end`, `pageup`,
  `pagedown`, `insert` (the Help key), `f1` to `f20`, and keypad keys `kp_0`
  to `kp_9`, `kp_enter`, `kp_add`, `kp_subtract`, `kp_multiply`,
  `kp_divide`, `kp_decimal`, and `kp_equal`. xdotool names such as `Return`,
  `BackSpace`, `Page_Up`, and `Next` work too. Letters ignore case, so add
  `shift` explicitly.
- To use a menu, click the menu bar item, run `get-ax-state`, and then click
  the menu item. A keyboard shortcut is often faster. Context menus from a
  right-click appear in the tree the same way. Press `escape` to close a
  menu. In Finder, use `click --button right` rather than the `showMenu`
  action, which times out there.
- Browsers and Electron apps build their tree on first request, so the first
  `get-ax-state` can take up to two seconds. If a web area is still empty,
  run it again.
- After an action that changes the UI, such as opening a dialog or
  scrolling, run `get-ax-state` again before you use element IDs or
  coordinates. Some changes animate, so take a fresh look after scrolling.
- The tree stops at 1000 elements and says `truncated`. Raise
  `--max-nodes`, or scroll to the part you need.
- Window IDs come from `get-app` and from the `get-ax-state` header.
- When several agents run at once, give each one its own
  `LLAMA_CU_SESSION`.
- `llama-cu` refuses to operate password managers and fails with
  `app_blocked`. Do not try to reach them another way.
