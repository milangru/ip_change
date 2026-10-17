#!/bin/bash
# Uklanja LAN IP Manager (skriptu, pokretač, ikonicu i stavku u meniju).
# Pokretanje kao običan korisnik:  ./uninstall.sh

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
SUDO=""
[ -w "$BIN_DIR" ] || SUDO="sudo"

$SUDO rm -f "$BIN_DIR/lan-ip" "$BIN_DIR/lan-ip-launcher"
rm -f "$HOME/.local/share/applications/lan-ip.desktop" "$HOME/.local/share/icons/lan-ip.png"
update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true

echo "LAN IP Manager je uklonjen."
