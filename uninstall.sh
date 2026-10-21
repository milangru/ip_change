#!/bin/bash
# Uklanja LAN IP Manager (skriptu, pokretač, ikonicu, stavku u meniju,
# polkit pravilo i prečice sa radne površine svih korisnika).
# Pokretanje kao običan korisnik:  ./uninstall.sh

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
POLKIT_ACTIONS_DIR="${POLKIT_ACTIONS_DIR:-/usr/share/polkit-1/actions}"
POLKIT_RULES_DIR="${POLKIT_RULES_DIR:-/etc/polkit-1/rules.d}"
APP_DIR="${APP_DIR:-/usr/share/applications}"
ICON_DIR="${ICON_DIR:-/usr/local/share/icons}"
SHORTCUT_NAME="IP Changer.desktop"

SUDO=""
[ -w "$BIN_DIR" ] || SUDO="sudo"
$SUDO rm -f "$BIN_DIR/lan-ip" "$BIN_DIR/lan-ip-launcher"

# Polkit akcija i pravilo (grupa netdev i članstva ostaju netaknuti)
if [ -e "$POLKIT_ACTIONS_DIR/com.milangru.lan-ip.policy" ] || [ -e "$POLKIT_RULES_DIR/49-lan-ip.rules" ]; then
    SUDO_P=""
    { [ -w "$POLKIT_ACTIONS_DIR" ] && [ -w "$POLKIT_RULES_DIR" ]; } || SUDO_P="sudo"
    $SUDO_P rm -f "$POLKIT_ACTIONS_DIR/com.milangru.lan-ip.policy" "$POLKIT_RULES_DIR/49-lan-ip.rules"
fi

# Meni i ikonica
SUDO_APP=""
{ [ -w "$APP_DIR" ] && [ -w "$ICON_DIR" ]; } || SUDO_APP="sudo"
$SUDO_APP rm -f "$APP_DIR/lan-ip.desktop" "$ICON_DIR/lan-ip.png"
$SUDO_APP update-desktop-database "$APP_DIR" 2> /dev/null || true

# Prečice na radnoj površini svih korisnika + /etc/skel
desktop_dir_for() {
    local home="$1" d=""
    d=$(sudo cat "$home/.config/user-dirs.dirs" 2> /dev/null \
        | sed -n 's/^XDG_DESKTOP_DIR=//p' | tr -d '"' | head -n1)
    d="${d//\$HOME/$home}"
    [ -z "$d" ] && d="$home/Desktop"
    echo "$d"
}
while IFS=: read -r user home; do
    [ -d "$home" ] || continue
    sudo rm -f "$(desktop_dir_for "$home")/$SHORTCUT_NAME"
done < <(getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1":"$6}')
sudo rm -f "/etc/skel/Desktop/$SHORTCUT_NAME"

# Stari korisnički fajlovi iz ranijih verzija
rm -f "$HOME/.local/share/applications/lan-ip.desktop" "$HOME/.local/share/icons/lan-ip.png"
update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true

echo "LAN IP Manager je uklonjen."
