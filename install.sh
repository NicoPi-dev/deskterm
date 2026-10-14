#!/usr/bin/env bash
# DeskTerm — a real Konsole melted into your wallpaper (KDE Plasma 6)
# Borderless, always below, pinned position/size, autostart, Meta+Enter to focus.
# https://github.com/NicoPi-dev/deskterm
set -euo pipefail

# ── Settings (edit, then re-run the script) ─────────────────
W=540;  H=760              # window size (logical pixels)
X=40;   Y=56               # top-left corner position
FONT="Monospace,13"
BG="0,0,0"                 # terminal background (match your wallpaper)
OPACITY=1                  # 1 = solid background, 0 = fully transparent (any wallpaper)
FG="178,234,205"           # text and prompt color (pastel mint)
SHORTCUT="Meta+Return"     # shortcut to jump into the terminal
# ────────────────────────────────────────────────────────────

for cmd in konsole kwriteconfig6 kreadconfig6 dbus-send; do
  command -v "$cmd" >/dev/null || { echo "Missing: $cmd (KDE Plasma 6 + Konsole required)"; exit 1; }
done

KDIR="$HOME/.local/share/konsole"
mkdir -p "$KDIR" "$HOME/.config/autostart" "$HOME/.bashrc.d" "$HOME/.local/bin"

# 1) Color scheme
cat > "$KDIR/DeskTerm.colorscheme" <<EOF
[General]
Description=DeskTerm
Opacity=$OPACITY
Blur=false

[Background]
Color=$BG

[Foreground]
Color=$FG
EOF

# 2) Konsole profile: fixed title (used by the KWin rule), blinking cursor,
#    no scrollbar, no "scrolled lines" highlight bar, DESKTERM=1 marker
cat > "$KDIR/DeskTerm.profile" <<EOF
[General]
Name=DeskTerm
Parent=FALLBACK/
TabTitleFormat=DeskTerm
RemoteTabTitleFormat=DeskTerm
TerminalMargin=14
Environment=TERM=xterm-256color,COLORTERM=truecolor,DESKTERM=1

[Appearance]
ColorScheme=DeskTerm
Font=$FONT

[Terminal Features]
BlinkingCursorEnabled=true

[Scrolling]
ScrollBarPosition=2
HighlightScrolledLines=false
EOF

# 3) Prompt in the same color, only inside DeskTerm (bash)
IFS=, read -r R G B <<< "$FG"
cat > "$HOME/.bashrc.d/deskterm.sh" <<EOF
# DeskTerm prompt color
if [ -n "\$DESKTERM" ]; then
  PS1='\[\e[38;2;${R};${G};${B}m\]\u@\h:\w\\\$ \[\e[0m\]'
fi
EOF
grep -q 'bashrc.d' "$HOME/.bashrc" 2>/dev/null || \
  echo '[ -f ~/.bashrc.d/deskterm.sh ] && . ~/.bashrc.d/deskterm.sh' >> "$HOME/.bashrc"

# 4) KWin rule: keep below, no border, skip taskbar/pager/switcher,
#    forced position and size, focus shortcut
F=kwinrulesrc; RULE=deskterm
w() { kwriteconfig6 --file "$F" --group "$RULE" --key "$1" "$2"; }
w Description "DeskTerm"
w title "DeskTerm";        w titlematch 2
w wmclass "konsole";       w wmclassmatch 2
w below true;              w belowrule 2
w noborder true;           w noborderrule 2
w skiptaskbar true;        w skiptaskbarrule 2
w skippager true;          w skippagerrule 2
w skipswitcher true;       w skipswitcherrule 2
w position "$X,$Y";        w positionrule 2
w size "$W,$H";            w sizerule 2
w shortcut "$SHORTCUT";    w shortcutrule 2

CUR=$(kreadconfig6 --file "$F" --group General --key rules)
if [[ ",$CUR," != *",$RULE,"* ]]; then
  kwriteconfig6 --file "$F" --group General --key rules "${CUR:+$CUR,}$RULE"
  N=$(kreadconfig6 --file "$F" --group General --key count --default 0)
  kwriteconfig6 --file "$F" --group General --key count "$((N+1))"
fi
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure

# 5) Launcher command + autostart at login
cat > "$HOME/.local/bin/deskterm" <<'EOF'
#!/usr/bin/env bash
# (Re)launch DeskTerm
exec konsole --separate --profile DeskTerm --hide-menubar --hide-tabbar >/dev/null 2>&1
EOF
chmod +x "$HOME/.local/bin/deskterm"

cat > "$HOME/.config/autostart/deskterm.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DeskTerm
Exec=$HOME/.local/bin/deskterm
X-KDE-autostart-phase=2
EOF

# 6) Launch now
nohup "$HOME/.local/bin/deskterm" >/dev/null 2>&1 &
echo "DeskTerm launched. Shortcut: $SHORTCUT — relaunch anytime with: deskterm"
echo "If a toolbar shows up: right-click it and uncheck the toolbars."
