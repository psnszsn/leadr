#!/usr/bin/env bash
# Run after `nix develop -c zig build`, inside xvfb-run and dbus-run-session.
# Needs xdotool, xclip; VALGRIND=1 additionally runs the GUI under Valgrind.
set -euo pipefail
app=$(realpath "${1:-zig-out/bin/leadrgtk}")
export LEADR_TEST_DIR
LEADR_TEST_DIR=$(mktemp -d /tmp/leadr-fuzzy-test.XXXXXX)
trap 'echo "FAIL at line $LINENO; logs: $LEADR_TEST_DIR" >&2' ERR
export XDG_DATA_HOME="$LEADR_TEST_DIR/data" XDG_DATA_DIRS="$LEADR_TEST_DIR/system"
export XDG_CACHE_HOME="$LEADR_TEST_DIR/cache" XDG_CONFIG_HOME="$LEADR_TEST_DIR/config"
export XDG_CURRENT_DESKTOP=LeadrTest GDK_BACKEND=x11 GTK_A11Y=none GSK_RENDERER=cairo
export XDG_RUNTIME_DIR="$LEADR_TEST_DIR/runtime" GIO_USE_VFS=local
mkdir -m 700 "$XDG_RUNTIME_DIR"
unset WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE SWAYSOCK
mkdir -p "$XDG_DATA_HOME/applications" "$XDG_DATA_DIRS/applications" "$LEADR_TEST_DIR/bin" "$LEADR_TEST_DIR/work dir"
export PATH="$LEADR_TEST_DIR/bin:$PATH"
cat > "$LEADR_TEST_DIR/bin/record" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$LEADR_TEST_DIR/launched"
printf '%s\n' "$PWD" > "$LEADR_TEST_DIR/cwd"
SH
chmod +x "$LEADR_TEST_DIR/bin/record"
cat > "$LEADR_TEST_DIR/bin/xdg-terminal-exec" <<'SH'
#!/bin/sh
touch "$LEADR_TEST_DIR/terminal-used"
exec "$@"
SH
chmod +x "$LEADR_TEST_DIR/bin/xdg-terminal-exec"
cat > "$XDG_DATA_HOME/applications/browser.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Safari Test
GenericName=Web Browser
Exec=$LEADR_TEST_DIR/bin/record %c %k %f %u %% "two words"
Path=$LEADR_TEST_DIR/work dir
Actions=private;
[Desktop Action private]
Name=Private Window
Exec=$LEADR_TEST_DIR/bin/record private-window
EOF
fixture() {
  local id=$1 name=$2 extra=${3:-}
  cat > "$XDG_DATA_HOME/applications/$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=$LEADR_TEST_DIR/bin/record %c
$extra
EOF
}
fixture hidden HiddenFixture 'Hidden=true'
fixture nodisplay NoDisplayFixture 'NoDisplay=true'
fixture missing MissingFixture 'TryExec=leadr-no-such-executable'
fixture only OnlyFixture 'OnlyShowIn=AnotherDesktop;'
fixture not NotFixture 'NotShowIn=LeadrTest;'
fixture visible VisibleFixture 'OnlyShowIn=LeadrTest;'
fixture twin-one 'Twin One'
fixture twin-two 'Twin Two'
fixture unicode 'Éditeur 日本語'
fixture terminal TerminalFixture 'Terminal=true'
fixture override ShadowFixture 'Hidden=true'
cat > "$XDG_DATA_DIRS/applications/override.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ShadowFixture
Exec=$LEADR_TEST_DIR/bin/record wrong-override
EOF
printf '#!/bin/sh\nexit 0\n' > "$LEADR_TEST_DIR/bin/PathOnlyFixture"
chmod +x "$LEADR_TEST_DIR/bin/PathOnlyFixture"
cp "$LEADR_TEST_DIR/bin/record" "$LEADR_TEST_DIR/bin/vanishing"
cat > "$XDG_DATA_HOME/applications/failure.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=FailureFixture
Exec=$LEADR_TEST_DIR/bin/vanishing retry-ok
EOF

cleanup() { kill "${app_pid:-}" 2>/dev/null || true; }
trap cleanup EXIT
start() {
  if test "${VALGRIND:-0}" = 1; then
    valgrind --leak-check=full --show-leak-kinds=definite --errors-for-leak-kinds=none --error-exitcode=99 --log-file="$LEADR_TEST_DIR/valgrind.log" "$app" > "$LEADR_TEST_DIR/app.log" 2>&1 &
  else
    "$app" > "$LEADR_TEST_DIR/app.log" 2>&1 &
  fi
  app_pid=$!
  for i in $(seq 1 600); do
    overlay=$(xdotool search --onlyvisible --pid "$app_pid" 2>/dev/null | head -1 || true)
    test -n "$overlay" && break
    sleep 0.1
  done
  test -n "$overlay"
  xdotool windowfocus --sync "$overlay"
}
leader() { "$app"; sleep 0.3; xdotool windowfocus --sync "$overlay"; }
search() {
  xdotool key BackSpace
  launcher=''
  for i in $(seq 1 300); do
    launcher=$(xdotool search --onlyvisible --name '^Fuzzy Mode$' 2>/dev/null | head -1 || true)
    test -n "$launcher" && break
    sleep 0.1
  done
  test -n "$launcher"
  xdotool windowfocus --sync "$launcher"
}
query() { xdotool key ctrl+a; xdotool type --clearmodifiers --delay 2 "$1"; sleep 0.2; }
expect_launch() {
  for i in $(seq 1 50); do test -e "$LEADR_TEST_DIR/launched" && break; sleep 0.1; done
  test "$(head -1 "$LEADR_TEST_DIR/launched")" = "$1"
  rm "$LEADR_TEST_DIR/launched"
}
close_search() { xdotool key Escape; sleep 0.2; }
focus_title() {
  local window=''
  for i in $(seq 1 300); do
    window=$(xdotool search --all --onlyvisible --pid "$app_pid" --name "^$1$" 2>/dev/null | head -1 || true)
    test -n "$window" && break
    sleep 0.1
  done
  test -n "$window"
  xdotool windowfocus --sync "$window"
}
focus_overlay() {
  for i in $(seq 1 300); do
    if xdotool search --onlyvisible --pid "$app_pid" | rg -q "^$overlay$"; then
      xdotool windowfocus --sync "$overlay"
      return
    fi
    sleep 0.1
  done
  return 1
}
start
for group in o w; do
  xdotool key "$group" BackSpace
  if xdotool search --onlyvisible --name '^Fuzzy Mode$'; then exit 1; fi
done
search
query sfi
if test -n "${SCREENSHOT_PATH:-}"; then
  sleep 1
  magick import -window "$launcher" "$SCREENSHOT_PATH"
fi
xdotool key Return
expect_launch 'Safari Test'
test "$(cat "$LEADR_TEST_DIR/cwd")" = "$LEADR_TEST_DIR/work dir"
echo 'PASS: only root Backspace opens Fuzzy Mode; noncontiguous search launches desktop entry with Path'

leader; search
query safariX
xdotool key BackSpace Return
for i in $(seq 1 50); do test -e "$LEADR_TEST_DIR/launched" && break; sleep 0.1; done
printf 'Safari Test\n%s\n%%\ntwo words\n' "$XDG_DATA_HOME/applications/browser.desktop" > "$LEADR_TEST_DIR/expected"
cmp "$LEADR_TEST_DIR/expected" "$LEADR_TEST_DIR/launched"
rm "$LEADR_TEST_DIR/launched"
echo 'PASS: Backspace edits query; Exec field codes and quoted arguments are handled by GIO'

leader; search
for hidden in HiddenFixture NoDisplayFixture MissingFixture OnlyFixture NotFixture ShadowFixture PathOnlyFixture DoesNotExist; do
  query "$hidden"
  xdotool key Return
  sleep 0.2
  test ! -e "$LEADR_TEST_DIR/launched"
  xdotool search --onlyvisible --name '^Fuzzy Mode$' >/dev/null
done
query VisibleFixture
xdotool key Return
expect_launch VisibleFixture
echo 'PASS: desktop visibility, TryExec, user masking of system entries, and no PATH-only commands'

leader; search
query wbbr
xdotool key Tab
query private
xdotool key Return
expect_launch private-window
echo 'PASS: GenericName search and desktop action execution'

leader; search
query browser.desktop
xdotool key Tab Escape Return
expect_launch 'Safari Test'
echo 'PASS: desktop ID search; leaving actions restores app query and selection'

leader; search
query sfi
xdotool mousemove --window "$launcher" 100 130 click 1
query browser.desktop
xdotool key Return
expect_launch 'Safari Test'
echo 'PASS: typing after mouse selection returns to the search field'

leader; search
printf 'ÉDITEUR' | xclip -selection clipboard
xdotool key ctrl+v
sleep 0.2
xdotool key Return
expect_launch 'Éditeur 日本語'
echo 'PASS: Unicode case folding and pasted queries'

leader; search
query TerminalFixture
xdotool key Return
expect_launch TerminalFixture
test -e "$LEADR_TEST_DIR/terminal-used"
echo 'PASS: Terminal=true uses the desktop terminal launcher'

leader; search
query twin
xdotool key Down Return
expect_launch 'Twin Two'
leader; search
query twin
xdotool key Return
expect_launch 'Twin Two'
echo 'PASS: arrow selection and learned query preference'

leader; search
query FailureFixture
rm "$LEADR_TEST_DIR/bin/vanishing"
xdotool key Return
sleep 0.4
xdotool search --onlyvisible --name '^Fuzzy Mode$' >/dev/null
test ! -e "$LEADR_TEST_DIR/launched"
cp "$LEADR_TEST_DIR/bin/record" "$LEADR_TEST_DIR/bin/vanishing"
xdotool key Return
expect_launch retry-ok
echo 'PASS: failed launch keeps query and allows retry'

leader; search
query 'Fuzzy Mode'
xdotool key Tab
query switch
xdotool key Return
# Allow the same window to unmap, rebuild its catalog, and map again.
sleep 1
focus_title 'Fuzzy Mode'
# Reopening itself rebuilds the catalog and resets the action/query state.
query 'Leader Mode'
xdotool key Return
focus_overlay
if xdotool search --onlyvisible --name '^Fuzzy Mode$'; then exit 1; fi
search
query combo
xdotool key Tab Escape Return
focus_overlay
search
query 'Emoji Mode'
xdotool key Return
focus_title Emoji
if xdotool search --onlyvisible --name '^Fuzzy Mode$'; then exit 1; fi
xdotool key Escape
leader; search
query voice
xdotool key Tab
query switch
xdotool key Return
focus_title Dictation
if xdotool search --onlyvisible --name '^Fuzzy Mode$'; then exit 1; fi
xdotool key Escape
echo 'PASS: all modes are searchable; aliases, mode actions, self-switch and root leader navigation work'

leader; search
close_search
leader
xdotool key q
wait "$app_pid"
echo "PASS: Escape closes; clean shutdown. Logs: $LEADR_TEST_DIR"
# A fresh process must retain the learned choice.
if test "${VALGRIND:-0}" != 1; then
  mv "$XDG_CACHE_HOME/leadr/catalog.ini" "$XDG_CACHE_HOME/leadr/applications.ini"
  start; search; query twin
  xdotool key Return
  expect_launch 'Twin Two'
  leader; xdotool key q; wait "$app_pid"
  echo 'PASS: learning persists across process restarts and migrates the desktop-only cache'
  mkdir -p "$LEADR_TEST_DIR/empty"
  export XDG_DATA_HOME="$LEADR_TEST_DIR/empty" XDG_DATA_DIRS="$LEADR_TEST_DIR/empty"
  start; search; query nothing
  xdotool key Return
  test ! -e "$LEADR_TEST_DIR/launched"
  query 'Leader Mode'
  xdotool key Return
  focus_overlay
  xdotool key q; wait "$app_pid"
  echo 'PASS: modes remain available without any desktop applications'
fi
trap - EXIT
