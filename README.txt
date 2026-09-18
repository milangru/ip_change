LAN IP MANAGER
==============

Graficka alatka (bash + yad) za brzo prebacivanje Ethernet (LAN) konekcije
na Linux sistemima izmedju automatske DHCP adrese i fiksne IP adrese, bez
otvaranja terminala ili mreznih podesavanja.


ZASTO OVA ALATKA
-----------------
Kada cesto menjate mrezu (npr. povremeno pristupate uredjaju na fiksnoj
lokalnoj IP adresi, a inace koristite DHCP), rucno kucanje nmcli komandi
je sporo i podlozno greskama. Ova skripta otvara jednostavan graficki
prozor, primenjuje podesavanja preko NetworkManager-a i fizicki
restartuje mrezni port da bi se izmene odmah primenile.


FUNKCIONALNOSTI
----------------
- Graficki interfejs (YAD forma) - bez terminala i kucanja komandi
- Prebacivanje izmedju DHCP i fiksne IP jednim klikom
- Podrazumevane (default) vrednosti unapred popunjene u poljima za
  fiksnu IP
- Prikaz stvarne trenutne IP adrese i gateway-a uredjaja, uzivo ocitano
  sa mreznog interfejsa
- Potpuni restart LAN porta posle svake izmene (ip link down/up +
  nmcli device connect), ne samo connection up
- Prozor ostaje otvoren posle primene izmena - mozete odmah nastaviti
  sa daljim podesavanjem, dok ne kliknete Cancel ili zatvorite prozor
- Automatsko prepoznavanje aktivne Ethernet konekcije preko nmcli


ZAHTEVI
-------
- Linux distribucija sa NetworkManager-om (nmcli)
- Instaliran yad:
    sudo apt install yad
- Root/sudo privilegije za izmenu mreznih podesavanja i restart
  interfejsa


INSTALACIJA
-----------
    git clone https://github.com/<vas-username>/<naziv-repozitorijuma>.git
    cd <naziv-repozitorijuma>
    sudo cp lan_ip_manager.sh /usr/local/bin/lan-ip
    sudo chmod +x /usr/local/bin/lan-ip


UPOTREBA
--------
Pokrenite iz terminala:

    sudo lan-ip

Ili napravite .desktop precicu za pokretanje jednim klikom sa Desktop-a
ili iz menija aplikacija.

Otvara se forma sa:
    - izborom rezima rada (Fiksna IP / Automatski DHCP)
    - poljima za unos IP adrese, gateway-a i DNS servera (samo za
      fiksni rezim)
    - prikazom stvarne trenutne IP adrese i gateway-a uredjaja


PODESAVANJE PODRAZUMEVANIH VREDNOSTI
-------------------------------------
Podrazumevana fiksna IP adresa, gateway i DNS serveri se menjaju na
vrhu skripte:

    DEFAULT_IP="192.168.100.101/24"
    DEFAULT_GATEWAY="192.168.100.100"
    DEFAULT_DNS="8.8.8.8, 1.1.1.1"


NAPOMENA
--------
Skripta menja aktivnu NetworkManager konekciju tipa 802-3-ethernet
(zicnu/Ethernet). Wi-Fi konekcije nisu podrzane.


LICENCA
-------
Slobodno za koriscenje i izmenu. Dodajte licencu po zelji (npr. MIT)
ako planirate javno deljenje repozitorijuma.
