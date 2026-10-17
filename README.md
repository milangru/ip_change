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
- Stavka **IP Changer** u meniju aplikacija (Settings / Preferences), sa ikonicom

## Zahtevi

- Linux sa `NetworkManager`-om (`nmcli`) i `polkit`-om (`pkexec`)
- `yad` (instalacija ga nudi da instalira preko `apt`, ili ručno: `sudo apt install yad`)

## Instalacija

```bash
git clone https://github.com/milangru/ip_change.git
cd ip_change
bash install.sh
```

Pokrenite ga kao običan korisnik (bez `sudo`); sudo lozinku traži sam, samo za upis u `/usr/local/bin`. Instalacija:

- kopira skriptu kao `lan-ip` i pravi pokretač `lan-ip-launcher` u `/usr/local/bin`
- kopira ikonicu iz foldera `icon/` (ako je nema, koristi sistemsku ikonicu mrežnog porta)
- dodaje stavku **IP Changer** u meni aplikacija

Ako se stavka ne pojavi odmah, odjavite se i prijavite. Na Linux Mint-u se nalazi u grupi **Preferences**.

## Upotreba

Pokrenite **IP Changer** iz menija aplikacija (traži lozinku), ili iz terminala:

```bash
sudo lan-ip
```

## Uklanjanje

```bash
bash uninstall.sh
```

## Struktura repozitorijuma

```
ip_change/
├── lan_ip_manager.sh   # glavna skripta
├── install.sh          # instalacija (skripta, pokretač, ikonica, meni)
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

## Napomena

Skripta menja aktivnu NetworkManager konekciju tipa `802-3-ethernet`. Wi-Fi nije podržan.

## Ikonica

<a href="https://www.flaticon.com/free-icons/ethernet" title="ethernet icons">Ethernet icons created by Those Icons - Flaticon</a>

## Licenca

Slobodno za korišćenje i izmenu. Dodajte licencu po želji (npr. MIT).
