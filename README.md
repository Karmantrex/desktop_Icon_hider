# Desktop Icons Manager

A lightweight macOS automation script that automatically shows and hides desktop icons based on the time of day. No third-party apps, no dependencies — just a single shell script and a native macOS LaunchAgent.

---

## What It Does

- **Hides** desktop icons from **10 PM to 8 AM**
- **Shows** desktop icons from **8 AM to 10 PM**
- Runs automatically at login
- Checks every 5 minutes, but only restarts Finder when the state actually needs to change
- Manages its own LaunchAgent — no manual plist editing required

---

## Requirements

- macOS (tested on Ventura and later)
- Bash (pre-installed on all Macs)
- No third-party dependencies

---

## Installation

### 1. Choose a permanent location for the script

Pick a folder you won't move or delete. This is important because the LaunchAgent stores the script path at setup time.

Good examples:
```bash
~/.scripts/
~/scripts/
~/Documents/scripts/
```

Create the folder if it doesn't exist:
```bash
mkdir -p ~/.scripts
```

### 2. Place the script in that folder

```bash
mv desktop_icons_manager.sh ~/.scripts/desktop_icons_manager.sh
```

### 3. Make it executable

```bash
chmod +x ~/.scripts/desktop_icons_manager.sh
```

### 4. Start the automation

```bash
~/.scripts/desktop_icons_manager.sh start
```

You should see:
```
Desktop icon automation started.
```

### 5. Confirm it is running

```bash
~/.scripts/desktop_icons_manager.sh status
```

Expected output:
```
Running - icons will hide 10 PM to 8 AM.
```

---

## Commands

| Command | What it does |
|---|---|
| `start` | Creates the LaunchAgent, registers it, and applies the correct icon state immediately |
| `stop` | Unregisters the LaunchAgent, removes the plist, and restores icons to visible |
| `status` | Reports whether the automation is currently running or stopped |

### Usage

```bash
/path/to/desktop_icons_manager.sh start
/path/to/desktop_icons_manager.sh stop
/path/to/desktop_icons_manager.sh status
```

---

## Moving the Script

If you need to move the script to a different folder after setup, always follow this order:

```bash
# 1. Stop the automation first
/current/path/desktop_icons_manager.sh stop

# 2. Move the script
mv /current/path/desktop_icons_manager.sh /new/path/desktop_icons_manager.sh

# 3. Start again from the new location
/new/path/desktop_icons_manager.sh start
```

Skipping `stop` before moving will leave the LaunchAgent pointing at a path that no longer exists, and the automation will silently break.

---

## How It Works

The script uses three macOS-native mechanisms:

**`defaults write com.apple.finder CreateDesktop`** — the system key that controls whether desktop icons are rendered. Setting it to `false` hides all icons; `true` shows them.

**`killall Finder`** — restarts Finder to apply the changed setting. The script only does this when the state actually needs to change, so Finder is not needlessly restarted every 5 minutes.

**LaunchAgent** — a plist registered in `~/Library/LaunchAgents/` that tells macOS to run the script at login (`RunAtLoad`) and on a 5-minute interval (`StartInterval 300`). The script creates and manages this file automatically.

---

## Important Notes

> **Save as plain UTF-8 text.**
> If you copy this script from a web page or rich-text editor, it may contain invisible non-breaking spaces that cause bash errors like `command not found`. Always save as a plain `.sh` text file.

> **Finder will restart briefly at transition times.**
> At 8 AM and 10 PM, Finder restarts for a moment to apply the state change. Open Finder windows will close temporarily. Active file copies are not affected since the state check prevents unnecessary restarts.

> **Do not run `start` from a temporary location.**
> The LaunchAgent records the exact path of the script at the time `start` is run. Running it from `Downloads` and then deleting that file will break the automation.

---

## Uninstalling

Run stop to cleanly remove the LaunchAgent and restore icons:

```bash
/path/to/desktop_icons_manager.sh stop
```

Then delete the script file itself. That's it — nothing else is left behind.

---

## Schedule at a Glance

| Time | Icon State |
|---|---|
| 8 AM | Icons appear |
| 10 PM | Icons hide |
| Every 5 min | State checked (Finder only restarts if a change is needed) |
| Every login | State applied automatically |
