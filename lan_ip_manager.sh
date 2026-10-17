#!/bin/bash
# LAN IP Manager - Linux (bash + yad + NetworkManager)
# Pokretanje: sudo lan-ip

DEFAULT_IP="192.168.1.10/24"   # /24 = maska 255.255.255.0
DEFAULT_GATEWAY=""             # prazno - bez gateway-a
DEFAULT_DNS=""                 # prazno - bez DNS servera

command -v yad &> /dev/null || { echo "Yad nije instaliran: sudo apt install yad"; exit 1; }

if [ "$(id -u)" -ne 0 ]; then
    yad --error --text="Pokrenite kao root: sudo lan-ip" --width=300
    exit 1
fi

# Aktivna žična konekcija (ako je nema, bilo koja postojeća)
CONN_NAME=$(nmcli -t -f NAME,TYPE connection show --active | grep "802-3-ethernet" | head -n1 | cut -d: -f1)
[ -z "$CONN_NAME" ] && CONN_NAME=$(nmcli -t -f NAME,TYPE connection show | grep "802-3-ethernet" | head -n1 | cut -d: -f1)
if [ -z "$CONN_NAME" ]; then
    yad --error --text="Nije pronađena nijedna LAN (Ethernet) konekcija!" --width=300
    exit 1
fi

# Mrežni uređaj (interfejs) te konekcije
DEVICE=$(nmcli -t -f GENERAL.DEVICES connection show "$CONN_NAME" | cut -d: -f2)
[ -z "$DEVICE" ] && DEVICE=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="ethernet" {print $1; exit}')

# Stvarna trenutna IP i gateway sa uređaja
read_actual() {
    ACT_IP=$(nmcli -g IP4.ADDRESS device show "$DEVICE" 2>/dev/null | head -n1)
    ACT_GW=$(nmcli -g IP4.GATEWAY device show "$DEVICE" 2>/dev/null | head -n1)
}

# Čeka (do 15 s) da port dobije signal posle restarta
wait_for_carrier() {
    for _ in $(seq 1 15); do
        [ "$(cat "/sys/class/net/$DEVICE/carrier" 2>/dev/null)" = "1" ] && return 0
        sleep 1
    done
    return 1
}

# Čeka (do 10 s) da uređaj dobije IP; ako je zadat $1, čeka baš tu adresu
wait_for_ip() {
    for _ in $(seq 1 10); do
        read_actual
        if [ -n "$ACT_IP" ] && { [ -z "$1" ] || [ "${ACT_IP%%/*}" = "$1" ]; }; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Restart porta i aktivacija konekcije; u ERR ostaje poruka ako ne uspe
apply_connection() {
    nmcli connection down "$CONN_NAME" &> /dev/null
    sleep 1
    ip link set "$DEVICE" down
    sleep 1
    ip link set "$DEVICE" up
    if ! wait_for_carrier; then
        ERR="Port $DEVICE nema signal. Proverite mrežni kabl.\nPodešavanja su sačuvana i primeniće se čim se pojavi signal."
        nmcli device set "$DEVICE" autoconnect yes &> /dev/null
        return 1
    fi
    ERR=$(nmcli connection up "$CONN_NAME" ifname "$DEVICE" 2>&1)
}

while true; do
    read_actual

    # Trenutni režim; padajući meni se otvara na SUPROTNOM režimu (onom na koji se najčešće prelazi)
    METHOD=$(nmcli -g ipv4.method connection show "$CONN_NAME" 2>/dev/null)
    if [ "$METHOD" = "auto" ]; then
        MODE_LABEL="DHCP (automatski)"
        MODE_OPTIONS="Fiksna IP!Automatski (DHCP)"
    else
        MODE_LABEL="Fiksna IP"
        MODE_OPTIONS="Automatski (DHCP)!Fiksna IP"
    fi

    # Dugmad: 2 = Osveži, 1 = Cancel, 0 = OK
    FORM_DATA=$(yad --form --title="Upravljanje LAN IP adresom" \
        --window-icon="network-wired" \
        --width=460 \
        --text="LAN konekcija: <b>$CONN_NAME</b>  (<i>$DEVICE</i>)\nTrenutni režim: <b>$MODE_LABEL</b>\nIzaberite željeni režim rada:" \
        --field="Režim rada:CB" "$MODE_OPTIONS" \
        --field="IP adresa i prefiks (npr. 192.168.1.50/24):" "$DEFAULT_IP" \
        --field="Gateway (Podrazumevani prolaz):" "$DEFAULT_GATEWAY" \
        --field="DNS serveri (odvojeni zarezom):" "$DEFAULT_DNS" \
        --field="  :LBL" "" \
        --field="<span size='large'>🔌  <b>Trenutna IP:</b>  <span foreground='#2e86de'><b>${ACT_IP:-nepoznato}</b></span></span>:LBL" "" \
        --field="<span size='large'>🌐  <b>Gateway:</b>  <span foreground='#2e86de'><b>${ACT_GW:-nepoznato}</b></span></span>:LBL" "" \
        --button="🔄 Osveži IP:2" \
        --button="gtk-cancel:1" \
        --button="gtk-ok:0")
    RET=$?

    case "$RET" in
        2) continue ;;        # samo osveži prikaz
        0) ;;                 # primeni
        *) break ;;           # Cancel / zatvoren prozor
    esac

    MODE=$(echo "$FORM_DATA" | awk -F'|' '{print $1}')
    IP_ADDR=$(echo "$FORM_DATA" | awk -F'|' '{print $2}')
    GATEWAY=$(echo "$FORM_DATA" | awk -F'|' '{print $3}')
    DNS=$(echo "$FORM_DATA" | awk -F'|' '{print $4}')

    if [ "$MODE" = "Automatski (DHCP)" ]; then
        # --- DHCP ---
        nmcli connection modify "$CONN_NAME" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns "" 2> /dev/null
        if ! apply_connection; then
            yad --error --no-markup --text="Greška:\n$ERR" --width=380
        elif wait_for_ip ""; then
            yad --info --text="Prebačeno na DHCP.\nDobijena IP: <b>$ACT_IP</b>" --width=300
        else
            yad --error --text="IP adresa nije dodeljena u roku od 10 s.\nProverite kabl i DHCP server." --width=340
        fi
    else
        # --- Fiksna IP ---
        [ -z "$IP_ADDR" ] && IP_ADDR="$DEFAULT_IP"
        [[ "$IP_ADDR" == */* ]] || IP_ADDR="$IP_ADDR/24"

        if ! ERR=$(nmcli connection modify "$CONN_NAME" ipv4.method manual ipv4.addresses "$IP_ADDR" \
                   ipv4.gateway "$GATEWAY" ipv4.dns "$DNS" 2>&1); then
            yad --error --no-markup --text="Greška:\n$ERR" --width=380
        elif ! apply_connection; then
            yad --error --no-markup --text="Greška:\n$ERR" --width=380
        elif wait_for_ip "${IP_ADDR%%/*}"; then
            yad --info --text="Fiksna IP primenjena:\n<b>$ACT_IP</b>" --width=300
        else
            yad --error --text="IP adresa nije postavljena.\nStvarna IP na uređaju: ${ACT_IP:-nema}" --width=340
        fi
    fi
done
