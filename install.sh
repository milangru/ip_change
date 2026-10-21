#!/bin/bash
# Instalacija LAN IP Manager-a (Linux), sistemski za sve korisnike:
#  - skripta i pokretač u /usr/local/bin
#  - stavka u meniju aplikacija (svi nalozi)
#  - prečica na radnoj površini (svi postojeći nalozi + novi preko /etc/skel)
#  - pokretanje BEZ lozinke za članove grupe "netdev" (ostali unose lozinku)
#
# Pokretanje kao običan korisnik (NE sa sudo):  ./install.sh
# Skripta sama traži sudo gde je potrebno.
# Potreban polkit >= 0.106 (npr. Linux Mint 22 / Ubuntu 24.04).

set -e
cd "$(dirname "$0")"

BIN_DIR="${BIN_DIR:-/usr/local/bin}"
POLKIT_ACTIONS_DIR="${POLKIT_ACTIONS_DIR:-/usr/share/polkit-1/actions}"
POLKIT_RULES_DIR="${POLKIT_RULES_DIR:-/etc/polkit-1/rules.d}"
ICON_DIR="${ICON_DIR:-/usr/local/share/icons}"
APP_DIR="${APP_DIR:-/usr/share/applications}"
SHORTCUT_NAME="IP Changer.desktop"
GROUP_ADDED=0

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

# Sudo samo ako je potrebno
SUDO=""
[ -w "$BIN_DIR" ] || SUDO="sudo"

echo "Instaliram skriptu u $BIN_DIR ..."
$SUDO mkdir -p "$BIN_DIR"
$SUDO install -m 755 lan_ip_manager.sh "$BIN_DIR/lan-ip"

# Pokretač (polkit akcija ispod sama prosleđuje DISPLAY/XAUTHORITY)
LAUNCHER_TMP=$(mktemp)
printf '#!/bin/bash\nexec pkexec %s/lan-ip\n' "$BIN_DIR" > "$LAUNCHER_TMP"
$SUDO install -m 755 "$LAUNCHER_TMP" "$BIN_DIR/lan-ip-launcher"
rm -f "$LAUNCHER_TMP"

# Polkit akcija + pravilo: bez lozinke za grupu netdev, ostali uz lozinku
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

# Sistemska ikonica i stavka menija
SUDO_APP=""
{ [ -w "$APP_DIR" ] && [ -w "$ICON_DIR" ]; } || SUDO_APP="sudo"
$SUDO_APP mkdir -p "$ICON_DIR" "$APP_DIR"

if [ -f icon/lan-ip.png ]; then
    $SUDO_APP install -m 644 icon/lan-ip.png "$ICON_DIR/lan-ip.png"
    ICON="$ICON_DIR/lan-ip.png"
else
    ICON="network-wired"
fi

DESKTOP_TMP=$(mktemp)
cat > "$DESKTOP_TMP" << DESKTOP_EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IP Changer
Comment=Prebacivanje LAN konekcije između DHCP-a i fiksne IP adrese
Exec=$BIN_DIR/lan-ip-launcher
Icon=$ICON
Terminal=false
Categories=System;Settings;Utility;
DESKTOP_EOF
$SUDO_APP install -m 644 "$DESKTOP_TMP" "$APP_DIR/lan-ip.desktop"
rm -f "$DESKTOP_TMP"
$SUDO_APP update-desktop-database "$APP_DIR" 2> /dev/null || true

# Prečice na radnoj površini: svi postojeći nalozi (UID 1000-59999) + /etc/skel za nove
desktop_dir_for() {   # $1 = home folder
    local home="$1" d=""
    d=$(sudo cat "$home/.config/user-dirs.dirs" 2> /dev/null \
        | sed -n 's/^XDG_DESKTOP_DIR=//p' | tr -d '"' | head -n1)
    d="${d//\$HOME/$home}"
    [ -z "$d" ] && d="$home/Desktop"
    echo "$d"
}

echo "Pravim prečice na radnoj površini ..."
while IFS=: read -r user home; do
    [ -d "$home" ] || continue
    ddir=$(desktop_dir_for "$home")
    sudo test -d "$ddir" || continue
    sudo install -m 755 -o "$user" -g "$(id -gn "$user")" \
        "$APP_DIR/lan-ip.desktop" "$ddir/$SHORTCUT_NAME"
    echo "  - $user: $ddir/$SHORTCUT_NAME"
done < <(getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1":"$6}')

# Za nove naloge
sudo mkdir -p /etc/skel/Desktop
sudo install -m 755 "$APP_DIR/lan-ip.desktop" "/etc/skel/Desktop/$SHORTCUT_NAME"

# Označi prečicu kao pouzdanu za trenutnog korisnika (Nemo/Nautilus)
MY_DESKTOP=$(desktop_dir_for "$HOME")
if [ -f "$MY_DESKTOP/$SHORTCUT_NAME" ]; then
    gio set "$MY_DESKTOP/$SHORTCUT_NAME" metadata::trusted true 2> /dev/null || true
fi

echo
echo "Gotovo. Potražite \"IP Changer\" u meniju aplikacija i na radnoj površini."
echo "Instalirano je sistemski i dostupno svim korisnicima."
echo "Bez lozinke rade samo članovi grupe netdev; ostale dodajte u nju (npr. preko \"Users and Groups\")."
echo "Ako se ikonica ne pojavi odmah, odjavite se i prijavite."
if [ "$GROUP_ADDED" -eq 1 ]; then
    echo
    echo "VAŽNO: dodati ste u grupu netdev. Odjavite se i ponovo prijavite da bi to stupilo na snagu."
fi
