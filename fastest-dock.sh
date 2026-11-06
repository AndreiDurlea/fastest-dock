#!/bin/sh
set -eu

DOMAIN=com.apple.dock
KEYS="autohide-delay autohide-time-modifier"
DEFAULT_DELAY=0
BACKUP_DIR="$HOME/Library/Application Support/fastest-dock"

usage() {
	cat <<EOF
Usage: fastest-dock.sh [apply [delay] [speed] | restore]

  apply [delay] [speed]  Wait delay seconds before the Dock slides in (default $DEFAULT_DELAY).
                         speed multiplies the slide animation, 1 is the macOS default.
                         Without speed, the animation stays as it was before the first apply.
  restore                Bring back the values saved by the first apply.
EOF
}

fail() {
	printf 'fastest-dock: %s\n' "$1" >&2
	exit 1
}

require_macos() {
	[ "$(uname -s)" = Darwin ] || fail "requires macOS"
}

require_number() {
	case $2 in
	'' | . | *[!0-9.]* | *.*.*) fail "$1 must be a non-negative number, got '$2'" ;;
	esac
}

read_key() {
	defaults read "$DOMAIN" "$1" 2>/dev/null
}

# Only the first apply saves, so applying twice cannot overwrite the user's values with ours.
save_current_values() {
	[ -d "$BACKUP_DIR" ] && return
	mkdir -p "$BACKUP_DIR"
	for key in $KEYS; do
		if value=$(read_key "$key"); then
			printf '%s\n' "$value" >"$BACKUP_DIR/$key"
		fi
		printf 'saved %s = %s\n' "$key" "${value:-unset}"
	done
}

restore_key() {
	defaults delete "$DOMAIN" "$1" 2>/dev/null || true
	if [ -f "$BACKUP_DIR/$1" ]; then
		defaults write "$DOMAIN" "$1" -float "$(cat "$BACKUP_DIR/$1")"
	fi
}

restore_saved_values() {
	for key in $KEYS; do
		restore_key "$key"
		printf 'restored %s = %s\n' "$key" "$(read_key "$key" || echo unset)"
	done
	rm -rf "$BACKUP_DIR"
}

# Without a speed the saved animation comes back, so dropping the argument undoes an earlier speed.
set_animation() {
	if [ -n "$1" ]; then
		defaults write "$DOMAIN" autohide-time-modifier -float "$1"
	else
		restore_key autohide-time-modifier
	fi
}

# No Dock process means launchd is already relaunching it, and the new Dock reads the new values.
restart_dock() {
	killall Dock 2>/dev/null || true
}

warn_if_autohide_off() {
	[ "$(read_key autohide)" = 1 ] ||
		printf 'note: turn on "Automatically hide and show the Dock" in System Settings > Desktop & Dock to see the change\n'
}

apply() {
	delay=${1:-$DEFAULT_DELAY}
	speed=${2:-}
	require_number delay "$delay"
	[ -z "$speed" ] || require_number speed "$speed"
	save_current_values
	defaults write "$DOMAIN" autohide-delay -float "$delay"
	set_animation "$speed"
	restart_dock
	printf 'applied autohide-delay = %s, autohide-time-modifier = %s\n' "$delay" "$(read_key autohide-time-modifier || echo unset)"
	warn_if_autohide_off
}

restore() {
	restore_saved_values
	restart_dock
}

main() {
	require_macos
	mode=${1:-apply}
	if [ $# -gt 0 ]; then shift; fi
	case $mode in
	apply) apply "$@" ;;
	restore) restore ;;
	-h | --help | help) usage ;;
	*) usage >&2 && exit 2 ;;
	esac
}

main "$@"
