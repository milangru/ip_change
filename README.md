# LAN IP Manager (Linux, bash + yad)

Grafička alatka za **Linux** koja prebacuje žičnu (Ethernet) konekciju između **automatske DHCP** adrese i **fiksne IP** adrese. Napisana je u bash-u, koristi `yad` za prozor i `NetworkManager` (`nmcli`) za primenu podešavanja.

> Ovo je verzija samo za Linux. Za Windows, macOS i Linux u jednom fajlu pogledajte Python verziju: [Menjanj-ip-allOS](https://github.com/milangru/Menjanj-ip-allOS).

## Funkcionalnosti

- Prebacivanje između **DHCP** i **fiksne IP** adrese preko padajućeg menija
- Padajući meni se otvara na režimu suprotnom od trenutnog, a trenutni režim piše iznad njega
- Prikaz **stvarne trenutne IP adrese i gateway-a** uređaja na dnu forme
- Dugme **"🔄 Osveži IP"** koje ponovo očitava stvarno stanje, bez primene izmena
- Restart LAN porta posle svake izmene, uz čekanje da port dobije signal
- Provera da li je adresa stvarno primenjena i poruka o grešci ako nije
- Prozor ostaje otvoren posle primene, pa možete odmah praviti nove izmene
- **Instalacija za sve korisničke naloge** na računaru: stavka u meniju aplikacija i prečica na radnoj površini
- **Pokretanje bez lozinke za članove grupe `netdev`**; ostali korisnici unose lozinku

## Zahtevi

- Linux sa `NetworkManager`-om (`nmcli`) i `polkit`-om (`pkexec`), polkit 0.106 ili noviji (npr. Linux Mint 22, Ubuntu 24.04)
- `yad` (instalacija nudi da ga instalira preko `apt`, ili ručno: `sudo apt install yad`)

## Instalacija

```bash
git clone https://github.com/milangru/ip_change.git
cd ip_change
bash install.sh
```

Pokrenite ga kao običan korisnik (bez `sudo`); sudo lozinku traži sam, gde je potrebno. Instalacija:

- kopira skriptu kao `lan-ip` i pravi pokretač `lan-ip-launcher` u `/usr/local/bin`
- kopira ikonicu iz foldera `icon/` u `/usr/local/share/icons` (ako je nema, koristi sistemsku ikonicu mrežnog porta)
- dodaje stavku **IP Changer** u `/usr/share/applications`, pa je vide **svi nalozi** (kategorije System, Settings, Utility)
- pravi prečicu **IP Changer** na radnoj površini svih postojećih naloga (UID 1000 i više), uz poštovanje lokalizovanog imena foldera (npr. "Радна површина"), i u `/etc/skel/Desktop`, pa je dobijaju i nalozi napravljeni kasnije
- podešava polkit akciju i pravilo za pokretanje bez lozinke za grupu `netdev`
- pravi grupu `netdev` (ako je nema) i dodaje u nju korisnika koji je pokrenuo instalaciju

Posle prve instalacije se jednom odjavite i prijavite, da članstvo u grupi `netdev` stupi na snagu. Ako se stavka ne pojavi u meniju odmah, odjavite se i prijavite i na ostalim nalozima. Na Linux Mint-u se nalazi u grupi **Administration** (kategorija System).

## Upotreba

Pokrenite **IP Changer** iz menija aplikacija ili sa prečice na radnoj površini, ili iz terminala:

```bash
sudo lan-ip
```

Na nekim okruženjima (npr. GNOME) je pri prvom pokretanju prečice potrebno desnim tasterom izabrati **Allow Launching**.

## Pokretanje bez lozinke (netdev)

Aplikacija menja mrežu kao root, pa je zaštićena polkit-om. Članovi grupe **`netdev`** je pokreću **bez lozinke**, i to važi samo za ovu aplikaciju (svi ostali programi i dalje traže lozinku). Korisnici koji nisu u grupi unose lozinku.

Druge korisnike dodajete u grupu preko **Users and Groups** (grupa `netdev`, pa čekirate korisnike) ili komandom:

```bash
sudo usermod -aG netdev ime_korisnika
```

Svaki dodati korisnik mora da se odjavi i prijavi.

Imajte na umu da svaki program koji radi pod nalogom člana grupe tada može da menja mrežna podešavanja bez lozinke, pa koristite ovo samo na računaru kojem verujete.

## Uklanjanje

```bash
bash uninstall.sh
```

Uklanja skriptu, pokretač, ikonicu, stavku u meniju, polkit pravila i prečice sa radne površine svih naloga. Grupa `netdev` i članstva ostaju kakva jesu.

## Struktura repozitorijuma

```
ip_change/
├── lan_ip_manager.sh   # glavna skripta
├── install.sh          # instalacija (skripta, pokretač, ikonica, meni, prečice, polkit)
├── uninstall.sh        # uklanjanje
└── icon/lan-ip.png     # ikonica za meni
```

## Podešavanje podrazumevanih vrednosti

Na vrhu `lan_ip_manager.sh`:

```bash
DEFAULT_IP="192.168.1.10/24"   # /24 = maska 255.255.255.0
DEFAULT_GATEWAY=""             # prazno - bez gateway-a
DEFAULT_DNS=""                 # prazno - bez DNS servera
```

Posle izmene ponovo pokrenite `bash install.sh`.

## Rešavanje problema

- **Pita za lozinku, ali se prozor ne otvori:** root proces nema pristup ekranu. Jednom pokrenite `xhost +SI:localuser:root` i probajte ponovo.
- **Poruka da port nema signal:** proverite mrežni kabl i uređaj s druge strane. Podešavanja su već sačuvana i primeniće se čim se pojavi signal.
- **Stavka se ne vidi u meniju drugog naloga:** proverite da postoji `/usr/share/applications/lan-ip.desktop`, pa se odjavite i prijavite na tom nalogu. Na XFCE-u pomaže i `xfce4-panel -r`. Pogledajte i da li stari fajl `~/.local/share/applications/lan-ip.desktop` na tom nalogu sakriva sistemsku stavku; ako postoji, obrišite ga. Prečica na radnoj površini radi i bez menija.
- **Traži lozinku iako ste u grupi `netdev`:** odjavite se i prijavite, pa proverite komandom `id` da je `netdev` na spisku grupa.

## Napomena

Skripta menja aktivnu NetworkManager konekciju tipa `802-3-ethernet`. Wi-Fi nije podržan.

## Ikonica

<a href="https://www.flaticon.com/free-icons/ethernet" title="ethernet icons">Ethernet icons created by Those Icons - Flaticon</a>

## Licenca

Slobodno za korišćenje i izmenu. Dodajte licencu po želji (npr. MIT).
