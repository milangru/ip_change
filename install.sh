#!/bin/bash
# Instalacija LAN IP Manager-a (Linux): skripta, pokretač, ikonica i stavka u meniju aplikacija.
# Pokretanje kao običan korisnik (NE sa sudo):  ./install.sh
# Skripta sama traži sudo samo za upis u /usr/local/bin.
#
# Opcija:  ./install.sh --no-password
#   Aplikacija se pokreće BEZ unosa lozinke, ali samo za članove grupe "netdev".
#   Instalacija pravi tu grupu (ako je nema) i dodaje vas u nju; ostale korisnike
#   kasnije dodajete u grupu (npr. preko "Users and Groups").
#   Potreban polkit >= 0.106 (npr. Linux Mint 22 / Ubuntu 24.04).

set -e
cd "$(dirname "$0")"

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
POLKIT_ACTIONS_DIR="${POLKIT_ACTIONS_DIR:-/usr/share/polkit-1/actions}"
POLKIT_RULES_DIR="${POLKIT_RULES_DIR:-/etc/polkit-1/rules.d}"
NO_PASSWORD=0
GROUP_ADDED=0
[ "$1" = "--no-password" ] && NO_PASSWORD=1
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
if [ "$NO_PASSWORD" -eq 1 ]; then
    # polkit akcija (ispod) sama prosleđuje DISPLAY/XAUTHORITY
    printf '#!/bin/bash\nexec pkexec %s/lan-ip\n' "$BIN_DIR" > "$LAUNCHER_TMP"
else
cat > "$LAUNCHER_TMP" << LAUNCHER_EOF
#!/bin/bash
pkexec env \\
  DISPLAY="\$DISPLAY" \\
  XAUTHORITY="\${XAUTHORITY:-\$HOME/.Xauthority}" \\
  WAYLAND_DISPLAY="\$WAYLAND_DISPLAY" \\
  XDG_RUNTIME_DIR="\$XDG_RUNTIME_DIR" \\
  $BIN_DIR/lan-ip
LAUNCHER_EOF
fi
$SUDO install -m 755 "$LAUNCHER_TMP" "$BIN_DIR/lan-ip-launcher"
rm -f "$LAUNCHER_TMP"

# Opciono: pokretanje bez lozinke samo za ovog korisnika (polkit akcija + pravilo)
if [ "$NO_PASSWORD" -eq 1 ]; then
    SUDO_P=""
    { [ -w "$POLKIT_ACTIONS_DIR" ] && [ -w "$POLKIT_RULES_DIR" ]; } || SUDO_P="sudo"
    POLICY_TMP=$(mktemp)
    RULE_TMP=$(mktemp)
    cat > "$POLICY_TMP" << POLICY_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <action id="com.milangru.lan-ip.run">
    <description>Promena LAN IP adrese</description>
    <message>Potrebna je autentifikacija za promenu LAN IP adrese</message>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">$BIN_DIR/lan-ip</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
  </action>
</policyconfig>
POLICY_EOF
    cat > "$RULE_TMP" << RULE_EOF
polkit.addRule(function(action, subject) {
    if (action.id == "com.milangru.lan-ip.run" &&
        subject.isInGroup("netdev") && subject.local && subject.active) {
        return polkit.Result.YES;
    }
});
RULE_EOF
    echo "Podešavam pokretanje bez lozinke za članove grupe netdev ..."
    getent group netdev > /dev/null || sudo groupadd netdev
    if ! id -nG "$(id -un)" | tr ' ' '\n' | grep -qx netdev; then
        sudo usermod -aG netdev "$(id -un)"
        GROUP_ADDED=1
    fi
    $SUDO_P install -m 644 "$POLICY_TMP" "$POLKIT_ACTIONS_DIR/com.milangru.lan-ip.policy"
    $SUDO_P install -m 644 "$RULE_TMP" "$POLKIT_RULES_DIR/49-lan-ip.rules"
    rm -f "$POLICY_TMP" "$RULE_TMP"
fi

# Ikonica (iz repozitorijuma; ako je nema, koristi se sistemska ikonica mrežnog porta)
mkdir -p "$ICON_DIR" "$APP_DIR"
if [ -f icon/lan-ip.png ]; then
    cp icon/lan-ip.png "$ICON_DIR/lan-ip.png"
    ICON="$ICON_DIR/lan-ip.png"
else
    ICON="network-wired"
fi

# Stavka u meniju aplikacija (grupa System; na Linux Mint-u se zove Administration)
cat > "$APP_DIR/lan-ip.desktop" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IP Changer
Comment=Prebacivanje LAN konekcije između DHCP-a i fiksne IP adrese
Exec=$BIN_DIR/lan-ip-launcher
Icon=$ICON
Terminal=false
Categories=System;
DESKTOP_EOF
chmod 644 "$APP_DIR/lan-ip.desktop"

update-desktop-database "$APP_DIR" 2> /dev/null || true

echo
echo "Gotovo. Potražite \"IP Changer\" u meniju aplikacija (System / Administration)."
echo "Ako se ne pojavi odmah, odjavite se i prijavite."
if [ "$GROUP_ADDED" -eq 1 ]; then
    echo
    echo "VAŽNO: dodati ste u grupu netdev. Odjavite se i ponovo prijavite da bi to stupilo na snagu."
fi
