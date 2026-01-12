# smooth-scroll-browsers-windows
Intercepts mouse wheel ticks in selected browser processes and re-emits them as multiple smaller deltas using an ease-out curve. Includes tray toggle and hotkey.

Small utility script that makes mouse wheel scrolling feel smoother in popular browsers on Windows by splitting each wheel “tick” into multiple smaller deltas with an easing curve.

## What it does

- Intercepts `WheelUp` / `WheelDown` only when an allowed browser window is active
- Re-emits the scroll as a sequence of smaller wheel deltas (`mouse_event`) with an easing curve (ease-out)
- Provides a tray menu and a hotkey toggle

This does **not** modify the browser itself. It changes how wheel input is re-emitted while the target app is focused.

## Requirements

- Windows 10/11
- AutoHotkey **v2** installed

## Files

- `smooth_scroll.ahk` — the script

## Install & Run

1. Install AutoHotkey v2
2. Save the script as `smooth_scroll.ahk`
3. Run it:
   - Double-click the `.ahk` file, or
   - Right-click → **Run Script**

When running, an AutoHotkey icon appears in the system tray.

## Usage

- Scroll in a supported browser (Chrome/Edge/Firefox/Opera/Brave by default)
- In other apps, the wheel behaves normally

### Toggle (Enable/Disable)

- Hotkey: **Ctrl + Alt + S**
- Or tray menu: **Enabled**

### Stop

- Tray icon → **Exit**

## Configuration

Edit these variables at the top of `smooth_scroll.ahk`:

- `TargetApps`  
  List of process names to apply smoothing to. Add/remove entries as needed.

- `Steps`  
  Number of micro-steps per wheel tick (typical: 6–12).

- `DelayMs`  
  Delay between micro-steps in milliseconds (typical: 6–12).

- `InertiaFactor`  
  Multiplier for total scroll per tick:
  - `1.0` = same total distance, only smoother
  - `>1.0` = slightly more “inertia” (can overscroll)
  - `<1.0` = less scroll

- `EasingMode`  
  Easing curve used to distribute deltas across micro-steps:
  - `easeOutCubic` (default)
  - `easeOutQuad`

## How it works (high level)

For each wheel tick:
1. Compute the total wheel delta (typically 120 per tick)
2. Split it into `Steps` parts using weights derived from an ease-out function:
   - `weight_i = Ease(i/Steps) - Ease((i-1)/Steps)`
3. Emit each part with a short delay (`DelayMs`) in between

## Known limitations

- This primarily targets **mouse wheel** events. Precision touchpad scrolling may behave differently depending on drivers/app.
- May conflict with other tools that also hook/rewrite wheel events.
- Some apps/pages may still feel “steppy” if `Steps` is too low or if the page is heavy; adjust `Steps`/`DelayMs`.

## License

Choose a license that fits your needs (MIT is common for small utilities).
