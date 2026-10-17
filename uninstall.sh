#!/bin/bash
# Uklanja LAN IP Manager (skriptu, pokretač, ikonicu i stavku u meniju).
# Pokretanje kao običan korisnik:  ./uninstall.sh

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
SUDO=""
[ -w "$BIN_DIR" ] || SUDO="sudo"

$SUDO rm -f "$BIN_DIR/lan-ip" "$BIN_DIR/lan-ip-launcher"
# polkit pravilo (ako je instalirano sa --no-password); grupa netdev i članstva ostaju netaknuti
POLKIT_ACTIONS_DIR="${POLKIT_ACTIONS_DIR:-/usr/share/polkit-1/actions}"
POLKIT_RULES_DIR="${POLKIT_RULES_DIR:-/etc/polkit-1/rules.d}"
if [ -e "$POLKIT_ACTIONS_DIR/com.milangru.lan-ip.policy" ] || [ -e "$POLKIT_RULES_DIR/49-lan-ip.rules" ]; then
    SUDO_P=""
    { [ -w "$POLKIT_ACTIONS_DIR" ] && [ -w "$POLKIT_RULES_DIR" ]; } || SUDO_P="sudo"
    $SUDO_P rm -f "$POLKIT_ACTIONS_DIR/com.milangru.lan-ip.policy" "$POLKIT_RULES_DIR/49-lan-ip.rules"
fi
rm -f "$HOME/.local/share/applications/lan-ip.desktop" "$HOME/.local/share/icons/lan-ip.png"
update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true

echo "LAN IP Manager je uklonjen."
