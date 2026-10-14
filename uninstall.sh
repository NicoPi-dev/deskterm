#!/usr/bin/env bash
# DeskTerm — uninstall: removes the profile, color scheme, prompt, KWin rule,
# launcher and autostart entry. Your other Konsole profiles are not touched.
set -euo pipefail

pkill -f "konsole --separate --profile DeskTerm" 2>/dev/null || true

rm -f "$HOME/.local/share/konsole/DeskTerm.profile" \
      "$HOME/.local/share/konsole/DeskTerm.colorscheme" \
      "$HOME/.bashrc.d/deskterm.sh" \
      "$HOME/.local/bin/deskterm" \
      "$HOME/.config/autostart/deskterm.desktop"

# Remove the line the installer may have added to ~/.bashrc
[ -f "$HOME/.bashrc" ] && sed -i '\|~/.bashrc.d/deskterm.sh|d' "$HOME/.bashrc"

# Remove the KWin rule
F=kwinrulesrc; RULE=deskterm
CUR=$(kreadconfig6 --file "$F" --group General --key rules)
if [[ ",$CUR," == *",$RULE,"* ]]; then
  NEW=$(echo "$CUR" | tr ',' '\n' | grep -vx "$RULE" | paste -sd, -)
  kwriteconfig6 --file "$F" --group General --key rules "$NEW"
  N=$(kreadconfig6 --file "$F" --group General --key count --default 1)
  kwriteconfig6 --file "$F" --group General --key count "$(( N > 0 ? N-1 : 0 ))"
fi
sed -i "/^\[$RULE\]$/,/^\[/{/^\[$RULE\]$/d;/^\[/!d}" "$HOME/.config/$F"
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure

echo "DeskTerm removed."
