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
- Stavka "IP Changer" u meniju aplikacija (System / Administration), sa
  ikonicom


ZAHTEVI
-------
- Linux sa NetworkManager-om (nmcli) i polkit-om (pkexec)
- yad (instalacija nudi da ga instalira preko apt, ili rucno:
  sudo apt install yad)


INSTALACIJA
-----------
    git clone https://github.com/milangru/ip_change.git
    cd ip_change
    bash install.sh

Pokrenite ga kao obican korisnik (bez sudo); sudo lozinku trazi sam,
samo za upis u /usr/local/bin. Instalacija:

- kopira skriptu kao lan-ip i pravi pokretac lan-ip-launcher u
  /usr/local/bin
- kopira ikonicu iz foldera icon/ (ako je nema, koristi sistemsku
  ikonicu mreznog porta)
- dodaje stavku "IP Changer" u meni aplikacija

Ako se stavka ne pojavi odmah, odjavite se i prijavite. Na Linux
Mint-u se nalazi u grupi Administration (kategorija System).


UPOTREBA
--------
Pokrenite "IP Changer" iz menija aplikacija (trazi lozinku), ili iz
terminala:

    sudo lan-ip


POKRETANJE BEZ LOZINKE (OPCIONO)
--------------------------------
Podrazumevano aplikacija trazi lozinku, jer menja mrezu kao root. Ako
to ne zelite:

    bash install.sh --no-password

Aplikacija se tada pokrece bez lozinke za clanove grupe netdev, i samo
ova aplikacija (svi ostali programi i dalje traze lozinku).
Instalacija pravi grupu netdev ako je nema i dodaje vas u nju, pa se
posle instalacije jednom odjavite i prijavite.

Druge korisnike dodajete u grupu kasnije, npr. preko "Users and
Groups" (grupa netdev, pa cekirate korisnike) ili komandom
"sudo usermod -aG netdev ime_korisnika". Svaki dodati korisnik mora da
se odjavi i prijavi. Korisnici koji nisu u grupi i dalje unose lozinku.

Zahteva polkit 0.106 ili noviji (npr. Linux Mint 22, Ubuntu 24.04).
Imajte na umu da svaki program koji radi pod nalogom clana grupe tada
moze da menja mrezna podesavanja bez lozinke, pa koristite ovu opciju
samo na racunaru kojem verujete.

Za povratak na unos lozinke pokrenite "bash uninstall.sh", pa ponovo
"bash install.sh". Grupa netdev i clanstva ostaju kakva jesu.


UKLANJANJE
----------
    bash uninstall.sh


STRUKTURA REPOZITORIJUMA
------------------------
    ip_change/
      lan_ip_manager.sh   glavna skripta
      install.sh          instalacija (skripta, pokretac, ikonica, meni)
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
