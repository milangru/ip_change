# LAN IP Manager (Linux, bash + yad)

Grafička alatka za **Linux** koja jednim klikom prebacuje žičnu (Ethernet) konekciju između **automatske DHCP** adrese i **fiksne IP** adrese. Napisana je u bash-u, koristi `yad` za prozor i `NetworkManager` (`nmcli`) za primenu podešavanja.

> Ovo je verzija samo za Linux. Za Windows, macOS i Linux u jednom fajlu pogledajte Python verziju: [Menjanj-ip-allOS](https://github.com/milangru/Menjanj-ip-allOS).

## Funkcionalnosti

- Prebacivanje između **DHCP** i **fiksne IP** adrese
- Polja za fiksnu IP uvek kreću od podrazumevanih vrednosti; ako polje ostane prazno, koristi se default
- Prikaz **stvarne trenutne IP adrese i gateway-a** uređaja na dnu forme
- Dugme **"🔄 Osveži IP"** koje ponovo očitava stvarno stanje, bez primene izmena
- Potpuni restart LAN porta posle svake izmene (`nmcli device disconnect`, `ip link down/up`, `nmcli device connect`)
- Prozor ostaje otvoren posle primene, pa možete odmah praviti nove izmene
- Automatski pronalazi aktivnu Ethernet konekciju

## Zahtevi

- Linux sa `NetworkManager`-om (`nmcli`)
- `yad`: `sudo apt install yad`
- Root privilegije (sudo ili pkexec)

## Instalacija

```bash
git clone https://github.com/milangru/ip_change.git
cd ip_change
sudo cp lan_ip_manager.sh /usr/local/bin/lan-ip
sudo chmod +x /usr/local/bin/lan-ip
```

## Upotreba

```bash
sudo lan-ip
```

## Pokretanje duplim klikom (prečica)

`pkexec` sam po sebi ne prosleđuje grafički ekran root procesu, pa prozor može da se ne otvori. Zato napravite pomoćnu skriptu:

```bash
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
```

Zatim napravite `~/.local/share/applications/lan-ip.desktop`:

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Ip Changer
Exec=/usr/local/bin/lan-ip-launcher
Icon=network-workgroup
Terminal=false
```

Ako se prozor i dalje ne pojavi, jednom pokrenite `xhost +SI:localuser:root`.

## Podešavanje podrazumevanih vrednosti

Na vrhu skripte:

```bash
DEFAULT_IP="192.168.1.10/24"   # /24 = maska 255.255.255.0
DEFAULT_GATEWAY=""             # prazno - bez gateway-a
DEFAULT_DNS=""                 # prazno - bez DNS servera
```

## Napomena

Skripta menja aktivnu NetworkManager konekciju tipa `802-3-ethernet`. Wi-Fi nije podržan.

## Licenca

Slobodno za korišćenje i izmenu. Dodajte licencu po želji (npr. MIT).
