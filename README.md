# LAN IP Manager

Grafička alatka (bash + [yad](https://github.com/v1cont/yad)) za brzo prebacivanje Ethernet (LAN) konekcije na Linux sistemima između **automatske DHCP** adrese i **fiksne IP** adrese, bez otvaranja terminala ili mrežnih podešavanja.

![Screenshot](screenshot.png)

## Zašto ova alatka

Kada često menjate mrežu (npr. povremeno pristupate uređaju na fiksnoj lokalnoj IP adresi, a inače koristite DHCP), ručno kucanje `nmcli` komandi je sporo i podložno greškama. Ova skripta otvara jednostavan grafički prozor, primenjuje podešavanja preko `NetworkManager`-a i **fizički restartuje mrežni port** da bi se izmene odmah primenile.

## Funkcionalnosti

- Grafički interfejs (YAD forma) — bez terminala i kucanja komandi
- Prebacivanje između **DHCP** i **fiksne IP** jednim klikom
- Podrazumevane (default) vrednosti unapred popunjene u poljima za fiksnu IP
- Prikaz **stvarne trenutne IP adrese i gateway-a** uređaja, uživo očitano sa mrežnog interfejsa
- Potpuni restart LAN porta posle svake izmene (`ip link down/up` + `nmcli device connect`), ne samo `connection up`
- Prozor ostaje otvoren posle primene izmena — možete odmah nastaviti sa daljim podešavanjem, dok ne kliknete Cancel ili zatvorite prozor
- Automatsko prepoznavanje aktivne Ethernet konekcije preko `nmcli`

## Zahtevi

- Linux distribucija sa `NetworkManager`-om (`nmcli`)
- Instaliran `yad`:
  ```bash
  sudo apt install yad
  ```
- Root/sudo privilegije za izmenu mrežnih podešavanja i restart interfejsa

## Instalacija

```bash
git clone https://github.com/<vas-username>/<naziv-repozitorijuma>.git
cd <naziv-repozitorijuma>
sudo cp lan_ip_manager.sh /usr/local/bin/lan-ip
sudo chmod +x /usr/local/bin/lan-ip
```

## Upotreba

Pokrenite iz terminala:

```bash
sudo lan-ip
```

Ili napravite `.desktop` prečicu za pokretanje jednim klikom sa Desktop-a ili iz menija aplikacija.

Otvara se forma sa:
- izborom režima rada (Fiksna IP / Automatski DHCP)
- poljima za unos IP adrese, gateway-a i DNS servera (samo za fiksni režim)
- prikazom stvarne trenutne IP adrese i gateway-a uređaja

## Podešavanje podrazumevanih vrednosti

Podrazumevana fiksna IP adresa, gateway i DNS serveri se menjaju na vrhu skripte:

```bash
DEFAULT_IP="192.168.100.101/24"
DEFAULT_GATEWAY="192.168.100.100"
DEFAULT_DNS="8.8.8.8, 1.1.1.1"
```

## Napomena

Skripta menja aktivnu NetworkManager konekciju tipa `802-3-ethernet` (žičnu/Ethernet). Wi-Fi konekcije nisu podržane.

## Licenca

Slobodno za korišćenje i izmenu. Dodajte licencu po želji (npr. MIT) ako planirate javno deljenje repozitorijuma.
