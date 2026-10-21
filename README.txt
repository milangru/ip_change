LAN IP MANAGER (LINUX, BASH + YAD)
===================================

Graficka alatka za Linux koja prebacuje zicnu (Ethernet) konekciju
izmedju automatske DHCP adrese i fiksne IP adrese. Napisana je u
bash-u, koristi yad za prozor i NetworkManager (nmcli) za primenu
podesavanja.

Ovo je verzija samo za Linux. Za Windows, macOS i Linux u jednom fajlu
pogledajte Python verziju:
https://github.com/milangru/Menjanj-ip-allOS


FUNKCIONALNOSTI
---------------
- Prebacivanje izmedju DHCP i fiksne IP adrese preko padajuceg menija
- Padajuci meni se otvara na rezimu suprotnom od trenutnog, a trenutni
  rezim pise iznad njega
- Prikaz stvarne trenutne IP adrese i gateway-a uredjaja na dnu forme
- Dugme "Osvezi IP" koje ponovo ocitava stvarno stanje, bez primene
  izmena
- Restart LAN porta posle svake izmene, uz cekanje da port dobije
  signal
- Provera da li je adresa stvarno primenjena i poruka o gresci ako nije
- Prozor ostaje otvoren posle primene, pa mozete odmah praviti nove
  izmene
- Instalacija za sve korisnicke naloge na racunaru: stavka u meniju
  aplikacija i precica na radnoj povrsini
- Pokretanje bez lozinke za clanove grupe netdev; ostali korisnici
  unose lozinku


ZAHTEVI
-------
- Linux sa NetworkManager-om (nmcli) i polkit-om (pkexec), polkit
  0.106 ili noviji (npr. Linux Mint 22, Ubuntu 24.04)
- yad (instalacija nudi da ga instalira preko apt, ili rucno:
  sudo apt install yad)


INSTALACIJA
-----------
    git clone https://github.com/milangru/ip_change.git
    cd ip_change
    bash install.sh

Pokrenite ga kao obican korisnik (bez sudo); sudo lozinku trazi sam,
gde je potrebno. Instalacija:

- kopira skriptu kao lan-ip i pravi pokretac lan-ip-launcher u
  /usr/local/bin
- kopira ikonicu iz foldera icon/ u /usr/local/share/icons (ako je
  nema, koristi sistemsku ikonicu mreznog porta)
- dodaje stavku "IP Changer" u /usr/share/applications, pa je vide
  svi nalozi (kategorije System, Settings, Utility)
- pravi precicu "IP Changer" na radnoj povrsini svih postojecih
  naloga (UID 1000 i vise), uz postovanje lokalizovanog imena
  foldera (npr. "Radna povrsina"), i u /etc/skel/Desktop, pa je
  dobijaju i nalozi napravljeni kasnije
- podesava polkit akciju i pravilo za pokretanje bez lozinke za
  grupu netdev
- pravi grupu netdev (ako je nema) i dodaje u nju korisnika koji je
  pokrenuo instalaciju

Posle prve instalacije se jednom odjavite i prijavite, da clanstvo u
grupi netdev stupi na snagu. Ako se stavka ne pojavi u meniju odmah,
odjavite se i prijavite i na ostalim nalozima. Na Linux Mint-u se
nalazi u grupi Administration (kategorija System).


UPOTREBA
--------
Pokrenite "IP Changer" iz menija aplikacija ili sa precice na radnoj
povrsini, ili iz terminala:

    sudo lan-ip

Na nekim okruzenjima (npr. GNOME) je pri prvom pokretanju precice
potrebno desnim tasterom izabrati "Allow Launching".


POKRETANJE BEZ LOZINKE (NETDEV)
-------------------------------
Aplikacija menja mrezu kao root, pa je zasticena polkit-om. Clanovi
grupe netdev je pokrecu bez lozinke, i to vazi samo za ovu aplikaciju
(svi ostali programi i dalje traze lozinku). Korisnici koji nisu u
grupi unose lozinku.

Druge korisnike dodajete u grupu preko "Users and Groups" (grupa
netdev, pa cekirate korisnike) ili komandom:

    sudo usermod -aG netdev ime_korisnika

Svaki dodati korisnik mora da se odjavi i prijavi.

Imajte na umu da svaki program koji radi pod nalogom clana grupe tada
moze da menja mrezna podesavanja bez lozinke, pa koristite ovo samo na
racunaru kojem verujete.


UKLANJANJE
----------
    bash uninstall.sh

Uklanja skriptu, pokretac, ikonicu, stavku u meniju, polkit pravila i
precice sa radne povrsine svih naloga. Grupa netdev i clanstva ostaju
kakva jesu.


STRUKTURA REPOZITORIJUMA
------------------------
    ip_change/
      lan_ip_manager.sh   glavna skripta
      install.sh          instalacija (skripta, pokretac, ikonica,
                          meni, precice, polkit)
      uninstall.sh        uklanjanje
      icon/lan-ip.png     ikonica za meni


PODESAVANJE PODRAZUMEVANIH VREDNOSTI
------------------------------------
Na vrhu lan_ip_manager.sh:

    DEFAULT_IP="192.168.1.10/24"   # /24 = maska 255.255.255.0
    DEFAULT_GATEWAY=""             # prazno - bez gateway-a
    DEFAULT_DNS=""                 # prazno - bez DNS servera

Posle izmene ponovo pokrenite: bash install.sh


RESAVANJE PROBLEMA
------------------
- Pita za lozinku, ali se prozor ne otvori: root proces nema pristup
  ekranu. Jednom pokrenite "xhost +SI:localuser:root" i probajte
  ponovo.
- Poruka da port nema signal: proverite mrezni kabl i uredjaj s druge
  strane. Podesavanja su vec sacuvana i primenice se cim se pojavi
  signal.
- Stavka se ne vidi u meniju drugog naloga: proverite da postoji
  /usr/share/applications/lan-ip.desktop, pa se odjavite i prijavite
  na tom nalogu. Na XFCE-u pomaze i "xfce4-panel -r". Pogledajte i da
  li stari fajl ~/.local/share/applications/lan-ip.desktop na tom
  nalogu sakriva sistemsku stavku; ako postoji, obrisite ga. Precica
  na radnoj povrsini radi i bez menija.
- Trazi lozinku iako ste u grupi netdev: odjavite se i prijavite, pa
  proverite komandom "id" da je netdev na spisku grupa.


NAPOMENA
--------
Skripta menja aktivnu NetworkManager konekciju tipa 802-3-ethernet.
Wi-Fi nije podrzan.


IKONICA
-------
Ethernet icons created by Those Icons - Flaticon
https://www.flaticon.com/free-icons/ethernet


LICENCA
-------
Slobodno za koriscenje i izmenu. Dodajte licencu po zelji (npr. MIT).
