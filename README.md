# fastest-dock

fastest-dock removes the hover delay before the auto-hidden macOS Dock starts to slide in. It is one POSIX shell script that changes `com.apple.dock` preferences and restarts the Dock, and it changes the slide animation only when a speed is passed.

## Usage

Apply the change:

```bash
curl -fsSL https://raw.githubusercontent.com/AndreiDurlea/fastest-dock/main/fastest-dock.sh | sh
```

Restore the previous behaviour:

```bash
curl -fsSL https://raw.githubusercontent.com/AndreiDurlea/fastest-dock/main/fastest-dock.sh | sh -s restore
```

Pass a delay in seconds after `apply` to keep a short wait, for example `sh -s apply 0.05`. A second number changes the animation speed, for example `sh -s apply 0 0.5`. From a clone, run `sh fastest-dock.sh apply [delay] [speed]` or `sh fastest-dock.sh restore`.

| Mode | Parameter | Type | Default | Effect |
| --- | --- | --- | --- | --- |
| `apply` | `delay` | seconds, non-negative number | `0` | Written to `autohide-delay`. |
| `apply` | `speed` | multiplier, non-negative number | omitted | Written to `autohide-time-modifier`. When omitted, the key returns to its value from before the first `apply`. |
| `restore` | none | none | none | Deletes both keys and writes back the values saved by the first `apply`. |
| `help` | none | none | none | Prints the usage. |

`apply` and `restore` restart the Dock with `killall Dock`. An invalid number exits with status 1 and an unknown mode with status 2. The script exits with status 1 on systems other than macOS.

## Preferences

`autohide-delay` is the time in seconds between the cursor reaching the screen edge and the Dock starting to slide in. `autohide-time-modifier` multiplies the duration of the slide animation, where `0` removes the animation and `1` matches the macOS default.

The values below were measured on macOS 26.5.1 (Darwin 25.5.0) as the time until the Dock window entered or left the screen, with 3 runs per row.

| `autohide-delay` | `autohide-time-modifier` | Show after | Hide after |
| --- | --- | --- | --- |
| unset | unset | 0.155 s | 0.25 s |
| `1` | unset | 1.005 s | 0.25 s |
| `0` | unset | 0.01 s | 0.25 s |
| `0` | `0.5` | 0.01 s | 0.13 s |
| `0` | `2` | 0.01 s | 0.49 s |
| `0` | `0.15` | 0.01 s | under 0.01 s |

The changes are visible only when "Automatically hide and show the Dock" is on in System Settings > Desktop & Dock. `apply` prints a note when it is off.

## Backup

The first `apply` reads both keys with `defaults read` and stores each existing value in `~/Library/Application Support/fastest-dock/`. Later `apply` runs keep that backup, so `restore` returns to the values from before the first `apply`.

`restore` runs `defaults delete` on both keys, writes back any saved value and removes the backup folder. A key that was unset before the first `apply` stays unset, which brings back the macOS default.

## License

Apache License 2.0. See [LICENSE](LICENSE).
