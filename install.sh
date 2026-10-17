#!/bin/bash
# Instalacija LAN IP Manager-a (Linux): skripta, pokretač, ikonica i stavka u meniju aplikacija.
# Pokretanje kao običan korisnik (NE sa sudo):  ./install.sh
# Skripta sama traži sudo samo za upis u /usr/local/bin.

set -e
cd "$(dirname "$0")"

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
ICON_DIR="$HOME/.local/share/icons"
APP_DIR="$HOME/.local/share/applications"

if [ "$(id -u)" -eq 0 ]; then
    echo "Ne pokrećite install.sh sa sudo - pokrenite ga kao običan korisnik (./install.sh)."
    exit 1
fi

[ -f lan_ip_manager.sh ] || { echo "Nedostaje lan_ip_manager.sh u ovom folderu."; exit 1; }

# Zavisnosti
for cmd in nmcli pkexec; do
    command -v "$cmd" > /dev/null || { echo "Nedostaje '$cmd' (NetworkManager / polkit)."; exit 1; }
done
if ! command -v yad > /dev/null; then
    echo "Nedostaje 'yad'."
    if command -v apt > /dev/null; then
        read -rp "Instalirati ga sada (sudo apt install yad)? [d/N] " ans
        if [[ "$ans" =~ ^[dDyY]$ ]]; then
            sudo apt install -y yad
        else
            exit 1
        fi
    else
        echo "Instalirajte 'yad' preko menadžera paketa vaše distribucije pa pokrenite ponovo."
        exit 1
    fi
fi

# Za upis u BIN_DIR koristi sudo samo ako je potrebno
SUDO=""
[ -w "$BIN_DIR" ] || SUDO="sudo"

echo "Instaliram skriptu u $BIN_DIR ..."
$SUDO mkdir -p "$BIN_DIR"
$SUDO install -m 755 lan_ip_manager.sh "$BIN_DIR/lan-ip"

# Pokretač: pkexec uz prosleđen grafički ekran, da se prozor otvori i bez terminala
LAUNCHER_TMP=$(mktemp)
cat > "$LAUNCHER_TMP" << LAUNCHER_EOF
#!/bin/bash
pkexec env \\
  DISPLAY="\$DISPLAY" \\
  XAUTHORITY="\${XAUTHORITY:-\$HOME/.Xauthority}" \\
  WAYLAND_DISPLAY="\$WAYLAND_DISPLAY" \\
  XDG_RUNTIME_DIR="\$XDG_RUNTIME_DIR" \\
  $BIN_DIR/lan-ip
LAUNCHER_EOF
$SUDO install -m 755 "$LAUNCHER_TMP" "$BIN_DIR/lan-ip-launcher"
rm -f "$LAUNCHER_TMP"

# Ikonica (iz repozitorijuma; ako je nema, koristi se sistemska ikonica mrežnog porta)
mkdir -p "$ICON_DIR" "$APP_DIR"
if [ -f icon/lan-ip.png ]; then
    cp icon/lan-ip.png "$ICON_DIR/lan-ip.png"
    ICON="$ICON_DIR/lan-ip.png"
else
    ICON="network-wired"
fi

# Stavka u meniju aplikacija (Settings / Postavke)
cat > "$APP_DIR/lan-ip.desktop" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IP Changer
Comment=Prebacivanje LAN konekcije između DHCP-a i fiksne IP adrese
Exec=$BIN_DIR/lan-ip-launcher
Icon=$ICON
Terminal=false
Categories=Settings;HardwareSettings;
DESKTOP_EOF
chmod 644 "$APP_DIR/lan-ip.desktop"

update-desktop-database "$APP_DIR" 2> /dev/null || true

echo
echo "Gotovo. Potražite \"IP Changer\" u meniju aplikacija (Settings / Preferences)."
echo "Ako se ne pojavi odmah, odjavite se i prijavite."
