LAN IP MANAGER (LINUX, BASH + YAD)
===================================

Graficka alatka za Linux koja jednim klikom prebacuje zicnu (Ethernet)
konekciju izmedju automatske DHCP adrese i fiksne IP adrese. Napisana
je u bash-u, koristi yad za prozor i NetworkManager (nmcli) za primenu
podesavanja.

Ovo je verzija samo za Linux. Za Windows, macOS i Linux u jednom fajlu
pogledajte Python verziju:
https://github.com/milangru/Menjanj-ip-allOS


FUNKCIONALNOSTI
---------------
- Prebacivanje izmedju DHCP i fiksne IP adrese
- Polja za fiksnu IP uvek krecu od podrazumevanih vrednosti; ako polje
  ostane prazno, koristi se default
- Prikaz stvarne trenutne IP adrese i gateway-a uredjaja na dnu forme
- Dugme "Osvezi IP" koje ponovo ocitava stvarno stanje, bez primene
  izmena
- Potpuni restart LAN porta posle svake izmene (nmcli device
  disconnect, ip link down/up, nmcli device connect)
- Prozor ostaje otvoren posle primene, pa mozete odmah praviti nove
  izmene
- Automatski pronalazi aktivnu Ethernet konekciju


ZAHTEVI
-------
- Linux sa NetworkManager-om (nmcli)
- yad: sudo apt install yad
- Root privilegije (sudo ili pkexec)


INSTALACIJA
-----------
    git clone https://github.com/milangru/ip_change.git
    cd ip_change
    sudo cp lan_ip_manager.sh /usr/local/bin/lan-ip
    sudo chmod +x /usr/local/bin/lan-ip


UPOTREBA
--------
    sudo lan-ip


POKRETANJE DUPLIM KLIKOM (PRECICA)
----------------------------------
pkexec sam po sebi ne prosledjuje graficki ekran root procesu, pa
prozor moze da se ne otvori. Zato napravite pomocnu skriptu:

    sudo tee /usr/local/bin/lan-ip-launcher > /dev/null << 'EOT'
    #!/bin/bash
    pkexec env \
      DISPLAY="$DISPLAY" \
      XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" \
      WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
      /usr/local/bin/lan-ip
    EOT
    sudo chmod +x /usr/local/bin/lan-ip-launcher

Zatim napravite ~/.local/share/applications/lan-ip.desktop:

    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=Ip Changer
    Exec=/usr/local/bin/lan-ip-launcher
    Icon=network-workgroup
    Terminal=false

Ako se prozor i dalje ne pojavi, jednom pokrenite:
    xhost +SI:localuser:root


PODESAVANJE PODRAZUMEVANIH VREDNOSTI
------------------------------------
Na vrhu skripte:

    DEFAULT_IP="192.168.1.10/24"   # /24 = maska 255.255.255.0
    DEFAULT_GATEWAY=""             # prazno - bez gateway-a
    DEFAULT_DNS=""                 # prazno - bez DNS servera


NAPOMENA
--------
Skripta menja aktivnu NetworkManager konekciju tipa 802-3-ethernet.
Wi-Fi nije podrzan.


LICENCA
-------
Slobodno za koriscenje i izmenu. Dodajte licencu po zelji (npr. MIT).
