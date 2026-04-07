#!/bin/bash

LABEL="com.nick.desktopicons"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
GUI_TARGET="gui/$(id -u)"

show_icons() {
    defaults write com.apple.finder CreateDesktop -bool true
    killall Finder >/dev/null 2>&1
}

hide_icons() {
    defaults write com.apple.finder CreateDesktop -bool false
    killall Finder >/dev/null 2>&1
}

apply_state() {
    current_hour=$(date +"%H")
    raw_state=$(defaults read com.apple.finder CreateDesktop 2>/dev/null || echo "1")

    # Normalize: macOS may return 1/0 or true/false depending on who last wrote the value
    case "$raw_state" in
        1|true)  current_state="1" ;;
        0|false) current_state="0" ;;
        *)       current_state="1" ;;  # Unknown value: assume visible (safe default)
    esac

    if [ "$current_hour" -ge 22 ] || [ "$current_hour" -lt 8 ]; then
        if [ "$current_state" != "0" ]; then
            hide_icons
        fi
    else
        if [ "$current_state" != "1" ]; then
            show_icons
        fi
    fi
}

create_plist() {
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${SCRIPT_PATH}</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>300</integer>
</dict>
</plist>
EOF
}

start_service() {
    # Ensure the script is executable (LaunchAgent runs it via /bin/bash, but good hygiene)
    chmod +x "$SCRIPT_PATH" 2>/dev/null
    create_plist
    launchctl bootout "$GUI_TARGET" "$PLIST" >/dev/null 2>&1
    if launchctl bootstrap "$GUI_TARGET" "$PLIST"; then
        apply_state
        echo "Desktop icon automation started."
    else
        echo "Failed to start desktop icon automation."
        exit 1
    fi
}

stop_service() {
    launchctl bootout "$GUI_TARGET" "$PLIST" >/dev/null 2>&1
    rm -f "$PLIST"
    show_icons
    echo "Desktop icon automation stopped. Icons are visible and the LaunchAgent was removed."
}

status_service() {
    if launchctl print "$GUI_TARGET/$LABEL" >/dev/null 2>&1; then
        echo "Running - icons will hide 10 PM to 8 AM."
    else
        echo "Stopped - no scheduled icon changes active."
    fi
}

case "$1" in
    start)   start_service ;;
    stop)    stop_service ;;
    status)  status_service ;;
    run)     apply_state ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo ""
        echo "Notes:"
        echo "  - Run 'start' from the script's permanent location (e.g. ~/.scripts/)."
        echo "    Moving the script after 'start' breaks the LaunchAgent. Run 'stop' first if you need to move it."
        echo "  - State changes (8 AM / 10 PM) will briefly restart Finder and close open windows."
        echo "  - Save this file as plain UTF-8 text to avoid invisible character errors."
        ;;
esac
