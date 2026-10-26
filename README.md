# CPS Counter for Noctalia

A [Noctalia](https://noctalia.dev) bar widget that always shows your left and
right mouse clicks per second (1-second sliding window), e.g. `L 7  R 2`.
Hover for the session peak; click the widget to reset it.

## Requirements

- Noctalia with plugin API ≥ 28
- `python3`
- Your user in the `input` group (the widget reads mouse buttons from `/dev/input`):
  ```sh
  sudo usermod -aG input $USER   # then log out and back in
  ```

## Install

```sh
noctalia msg plugins source add cps git https://github.com/OnlySven/noctalia-plugin-cps
noctalia msg plugins enable sviatyipavlo/cps
```

Then add the **CPS Counter** widget from the bar's Add-widget picker, or put
`"sviatyipavlo/cps:counter"` into a bar section in `settings.toml`, e.g.:

```toml
[bar.default]
start = [ "launcher", "workspaces", "sviatyipavlo/cps:counter" ]
```

## How it works

`cps/scripts/cps.py` finds every mouse evdev node via `/proc/bus/input/devices`
(rescanning every 3 s for hotplugged mice), counts `BTN_LEFT` / `BTN_RIGHT`
presses and streams `<left> <right>` lines only when the counts change. The
Luau widget just renders them, so it costs almost nothing.

Touchpad taps are synthesized by libinput, not the kernel, so only physical
clicks are counted.
