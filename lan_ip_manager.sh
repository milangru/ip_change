#!/bin/bash

# Provera da li je yad instaliran
if ! command -v yad &> /dev/null; then
    zenity --error --text="Yad nije instaliran! Instalirajte ga sa: sudo apt install yad" 2>/dev/null || echo "Yad nije instaliran."
    exit 1
fi

# Pronalazi aktivnu LAN/wired konekciju (filtrira po tipu 802-3-ethernet)
CONN_NAME=$(nmcli -t -f NAME,TYPE connection show --active | grep "802-3-ethernet" | head -n 1 | cut -d: -f1)

# Ako nema aktivne LAN konekcije, uzmi bilo koju žičnu konekciju koja postoji
if [ -z "$CONN_NAME" ]; then
    CONN_NAME=$(nmcli -t -f NAME,TYPE connection show | grep "802-3-ethernet" | head -n 1 | cut -d: -f1)
fi

if [ -z "$CONN_NAME" ]; then
    yad --error --text="Nije pronađena nijedna LAN (Ethernet) konekcija!\nProverite da li je kabl priključen." --width=300
    exit 1
fi

# Ime mrežnog uređaja (interfejsa) vezanog za ovu konekciju - potrebno za restart porta
DEVICE=$(nmcli -t -f GENERAL.DEVICES connection show "$CONN_NAME" | cut -d: -f2)

# Fiksne (nepromenljive) podrazumevane vrednosti za režim "Fiksna IP" - polja formulara UVEK
# kreću od ovih vrednosti kad je izabrana fiksna IP, bez obzira šta je uređaj prethodno imao preko DHCP-a
DEFAULT_IP="192.168.100.101/24"
DEFAULT_GATEWAY="192.168.100.100"
DEFAULT_DNS="8.8.8.8, 1.1.1.1"

# Funkcija koja čita STVARNU trenutnu IP/gateway/DNS sa uređaja - za prikaz na dnu forme
# (informativno), nikad da popuni polja za unos fiksne IP
read_actual_settings() {
    ACT_IP=$(nmcli -g IP4.ADDRESS device show "$DEVICE" 2>/dev/null | head -n1)
    ACT_GW=$(nmcli -g IP4.GATEWAY device show "$DEVICE" 2>/dev/null | head -n1)
    ACT_DNS=$(nmcli -g IP4.DNS device show "$DEVICE" 2>/dev/null | paste -sd, -)
}

# Funkcija za potpuni restart LAN porta (fizički down/up interfejsa, ne samo connection up)
restart_lan_port() {
    if [ -n "$DEVICE" ]; then
        nmcli device disconnect "$DEVICE" &> /dev/null
        sleep 1
        ip link set "$DEVICE" down &> /dev/null
        sleep 1
        ip link set "$DEVICE" up &> /dev/null
        sleep 1
        nmcli device connect "$DEVICE" &> /dev/null
    fi
}

# Pri pokretanju skripte - očitaj stvarni trenutni režim (auto/manual) sa konekcije, samo da
# combo box otvori na ispravnoj trenutnoj opciji
INIT_METHOD=$(nmcli -g ipv4.method connection show "$CONN_NAME" 2>/dev/null)
if [ "$INIT_METHOD" = "auto" ]; then
    CUR_MODE="Automatski (DHCP)"
else
    CUR_MODE="Fiksna IP"
fi

# Glavna petlja - forma se ponovo otvara posle svake primene, dok korisnik ne klikne Cancel/zatvori prozor
while true; do

    # Pre svakog prikaza forme, pročitaj stvarno trenutno stanje uređaja
    read_actual_settings

    # Redosled opcija u CB polju - trenutno izabrani režim ide prvi, da ostane selektovan
    if [ "$CUR_MODE" = "Fiksna IP" ]; then
        MODE_OPTIONS="Fiksna IP!Automatski (DHCP)"
    else
        MODE_OPTIONS="Automatski (DHCP)!Fiksna IP"
    fi

    # Polja za IP/gateway/DNS UVEK prikazuju default vrednosti (za unos fiksne IP).
    # Stvarno trenutno stanje uređaja prikazano je kao dva istaknuta reda na samom dnu forme.
    # Custom dugmad: "Osveži IP" (kod 2) samo ponovo učitava stvarno stanje, bez primene izmena.
    FORM_DATA=$(yad --form --title="Upravljanje LAN IP adresom" \
        --window-icon="network-wired" \
        --width=440 \
        --text="LAN konekcija: <b>$CONN_NAME</b>  (<i>$DEVICE</i>)\nIzaberite željeni režim rada:" \
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

    # "Osveži IP" - samo ponovo pokreni petlju (na vrhu će se ponovo pozvati read_actual_settings),
    # bez primene ikakvih izmena na mrežnoj konekciji
    if [ "$RET" -eq 2 ]; then
        continue
    fi

    # Bilo šta osim "Primeni" (0) i "Osveži IP" (2) - Cancel ili zatvoren prozor - izlazimo iz petlje
    if [ "$RET" -ne 0 ]; then
        break
    fi

    # Ekstrakcija podataka iz forme (prva 4 polja su bitna, ostalo su samo labele bez vrednosti)
    MODE=$(echo "$FORM_DATA" | awk -F'|' '{print $1}')
    IP_ADDR=$(echo "$FORM_DATA" | awk -F'|' '{print $2}')
    GATEWAY=$(echo "$FORM_DATA" | awk -F'|' '{print $3}')
    DNS=$(echo "$FORM_DATA" | awk -F'|' '{print $4}')

    CUR_MODE="$MODE"

    # Primena postavki preko NetworkManagera
    if [ "$MODE" = "Automatski (DHCP)" ]; then
        nmcli connection modify "$CONN_NAME" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""

        restart_lan_port

        if nmcli connection up "$CONN_NAME"; then
            # Sačekaj da DHCP server stigne da dodeli adresu, pa pročitaj STVARNU IP - za prikaz u poruci
            sleep 3
            read_actual_settings
            yad --info --text="LAN uspešno prebačen na automatsku (DHCP) IP adresu!\nDobijena IP: <b>${ACT_IP:-nepoznato}</b>\nPort je restartovan." --width=300
        else
            yad --error --text="Greška prilikom primene DHCP postavki na LAN!" --width=300
        fi

    else
        # Ako korisnik nije ručno popunio (ostavio prazno) - koristi default vrednosti automatski
        [ -z "$IP_ADDR" ] && IP_ADDR="$DEFAULT_IP"
        [ -z "$GATEWAY" ] && GATEWAY="$DEFAULT_GATEWAY"
        [ -z "$DNS" ] && DNS="$DEFAULT_DNS"

        nmcli connection modify "$CONN_NAME" ipv4.method manual ipv4.addresses "$IP_ADDR"
        nmcli connection modify "$CONN_NAME" ipv4.gateway "$GATEWAY"
        nmcli connection modify "$CONN_NAME" ipv4.dns "$DNS"

        restart_lan_port

        if nmcli connection up "$CONN_NAME"; then
            yad --info --text="LAN uspešno podešen na fiksnu IP:\n<b>$IP_ADDR</b>\nPort je restartovan." --width=300
        else
            yad --error --text="Greška! Proverite da li je IP adresa ispravnog formata (npr. sa /24)." --width=300
        fi
    fi

done
