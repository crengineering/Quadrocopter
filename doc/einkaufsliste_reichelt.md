# Einkaufsliste Reichelt — Elektronik-Bauteile (Quadrocopter TC399)

Zusammengefasst aus dem Projekt-Übergabestand (`quadrocopter_tc399_uebergabe.md` §5) und
dem aktuellen Pegel-Konzept aus `PINNING.md` §2.5/§2.6.
Fokus: **diskrete/passive Elektronik + Platinenaufbau** — das, was Reichelt führt.
Antrieb, Energie und Sensor-Breakouts stehen unten nur als Verweis (andere Quellen).

> **Preise/Artikelnummern:** bewusst offen gelassen — Reichelt-Artikelnummern und
> Tagespreise sind hier nicht verifiziert. Die Spalte *Reichelt-Suchbegriff* ist zum
> direkten Finden gedacht. Auf Wunsch löse ich die exakten Artikelnummern + Preise nach.

---

## Beschaffungsregel: Verfügbarkeit vor Auswahl

**Vor jeder Bauteilauswahl die Reichelt-Verfügbarkeit prüfen.** Bei mehreren gleichwertigen
Optionen die **sofort lieferbare** wählen; nicht-sofort-lieferbare Teile mit Lieferzeit
markieren und, wenn sinnvoll, eine lagernde Alternative vorschlagen.

- **Vorab-Check (Näherung):** per Websuche beim Aussuchen — erkennt grobe „nicht lieferbar /
  lange Lieferzeit"-Fälle, ist aber nicht tagesaktuell garantiert (reichelt.de ist von hier
  aus nicht live auslesbar).
- **Verbindlicher Check:** die Lieferzeit-Anzeige **im Warenkorb nach dem CSV-Import**
  (live aus deinem Konto) — dort je Position „sofort ab Lager" vs. „x Tage" prüfen, bevor du
  bestellst.

---

## 0. CSV-Import in den Reichelt-Warenkorb

Reichelt akzeptiert einen CSV-Upload (myReichelt → Warenkorb → Artikel-Import):
- **Format:** genau zwei Spalten `Artikelnummer;Menge`, **Semikolon** als Trenner.
- **Ganze Mengen** (keine Teilmengen), sonst bricht der Import ab.
- Upload → „Übertragen"; fehlerhafte/geänderte Artikelnummern werden **pro Zeile markiert**,
  die korrigierst du dann manuell. Preise erscheinen erst nach „Artikel hinzufügen".

### 0.1 Fertige CSV (Datei `reichelt_warenkorb.csv`)

Alle Positionen mit gesichertem Reichelt-Bestellcode liegen jetzt in der
import-fertigen CSV `reichelt_warenkorb.csv` (`Artikelnummer;Menge`). Beim Import zeigt
Reichelt je Zeile den Produktnamen — falls eine Nummer nicht passt, wird sie markiert.

> **Hinweis:** die ersten 9 Zeilen hast du bereits importiert. Um Dopplung zu vermeiden,
> importiere entweder nur die **4 neuen** Zeilen (unten mit ➕ markiert) oder leere den
> Warenkorb und lade die komplette Datei neu.

| Position | Reichelt-Artikelnr. | Menge |  |
|---|---|---|---|
| Widerstand 1,0 kΩ Metallschicht 0207 1% | `METALL 1,00K` | 10 | |
| Widerstand 1,5 kΩ (DShot-Pullup) | `METALL 1,50K` | 10 | |
| Widerstand 2,0 kΩ (SPI-Teiler unten) | `METALL 2,00K` | 10 | |
| Widerstand 4,7 kΩ (I²C-Pullup) | `METALL 4,70K` | 10 | |
| Widerstand 10 kΩ (INT-Pulldown) | `METALL 10,0K` | 10 | |
| TVS-Diode P6KE27A | `P6KE 27A` | 2 | |
| Klappferrit Würth 74271132 | `WUE 74271132` | 1 | |
| Buchsenleiste 1×20 gerade RM2,54 | `BL 1X20G8 2,54` | 4 | |
| Stiftleiste 1×40 gerade RM2,54 | `SL 1X40G 2,54` | 3 | |
| Elko 470 µF/25 V radial Low-ESR (Panasonic FR) | `RAD FR 470 - 25` | 2 | ➕ |
| Keramik-C 100 nF X7R RM2,5 | `X7R-2,5 100N` | 20 | ➕ Code prüfen |
| Keramik-C 10 µF 25 V X7R 1206 SMD | `X7R-G1206 10 - 25` | 5 | ➕ |
| Glassicherung 5×20 träge 2 A | `SICHERUNG 2,0AT` | 3 | ➕ Code prüfen |

### 0.2 Noch zu ergänzen (Produkt-ID direkt bei reichelt.de aufrufbar)

Diese habe ich nur teilweise/als Produkt-ID belegt — kurz auf der Seite prüfen und
in die CSV/den Warenkorb aufnehmen (Produkt-ID lässt sich direkt in die Reichelt-Suche
eingeben):

Für diese Positionen gibt es keinen sauberen Reichelt-Bestellcode (oder es sind
Kfz-/Modellbau-Teile) — deshalb **nicht** in der CSV. Produkt-ID lässt sich direkt in
die Reichelt-Suche eingeben:

| Position | Menge | Reichelt-Produkt-ID / Suchbegriff | Status |
|---|---|---|---|
| Lochrasterplatine durchkontaktiert ~100×80 | 2 | „Laborkarte FR4 durchkontaktiert" ID **105493** (oder RADEMACHER 160×100 ID 23950) | Größe wählen |
| Inline-Sicherungshalter 5×20 (Kabel) | 1 | Reichelt v.a. Print/Panel (FREI ID **14678**); echtes Inline eher Kfz-Shop | prüfen |
| XT60 Buchse | 1 | ID **207648** (XT-60 Stecker/Buchse) | Code prüfen |
| Abstandsbolzen Nylon M3 10 mm + Schrauben | 1 Set | Suche „Distanzbolzen Polyamid M3x10 Gewinde" | offen |
| Schrumpfschlauch-Sortiment 2:1 | 1 | „Akku-Schrumpfschlauch-Sortiment 2:1" ID **280190** | offen |
| Schutzbrille | 1 | Suche „Schutzbrille" | offen |
| *(Fallback)* SN74LVC1T45 | 4 | Suche „SN74LVC1T45" | evtl. nicht bei Reichelt gelistet |
| *(Grenzfall)* XT90-S Anti-Spark | 1 | Suche „XT90 Anti Spark" | evtl. Modellbau |
| *(Grenzfall)* Flachsicherung 80 A + Halter | 2 | — | Kfz-Shop |

**Litzen** (12/20/26 AWG) bewusst nicht enthalten — kaufst du als Set bei Amazon.

> Warum nicht alles automatisch: reichelt.de ist von hier aus weder per Browser-Automatik
> noch per Server-Abruf lesbar; die Codes stammen aus der Websuche. Die 0.1-Liste ist
> verlässlich (Muster `METALL x,xxK`, `RAD FR 470 - 25`, `X7R-G1206 10 - 25` bestätigt);
> `X7R-2,5 100N` und `SICHERUNG 2,0AT` beim Import kurz gegenprüfen.

---

## 1. Sensor-/SPI-Beschaltung (Lochraster-Board)

| Bauteil | Spezifikation | Menge | Zweck | Reichelt-Suchbegriff |
|---|---|---|---|---|
| Lochrasterplatine | FR4 durchkontaktiert, Punktraster RM 2,54, ~100×80 mm | 2 | Trägerplatine Sensorik | „Lochrasterplatine RM2,54 durchkontaktiert" |
| Widerstand **1 kΩ** | Metallschicht 0207, 1 % | 10 | SPI-Teiler oben (SCLK/MOSI/CS) | „Metallschicht 1,0k 0207" |
| Widerstand **2 kΩ** | Metallschicht 0207, 1 % — **echte 2 kΩ, nicht 2,2 k** | 10 | SPI-Teiler unten → 3,3 V | „Metallschicht 2,0k 0207" |
| Widerstand **10 kΩ** | Metallschicht 0207, 1 % | 10 | Pulldown IMU-INT1 | „Metallschicht 10k 0207" |
| Widerstand **4,7 kΩ** | Metallschicht 0207, 1 % | 10 | I²C-Pullup (nur falls Messung es verlangt) | „Metallschicht 4,7k 0207" |
| Keramik-C **100 nF** | **X7R**, SMD 0805 *oder* bedrahtet RM 2,54 | 20 | Entkopplung | „Vielschicht 100n X7R" |
| Keramik-C **10 µF** | **X5R/X7R**, 25 V, SMD 1206 | 5 | Stütz-C (quer über 2 Augen löten) | „Vielschicht 10µ 25V 1206 X7R" |
| Buchsenleiste RM 2,54 | 1×20, zum Kürzen (Sensoren steckbar) | 4 | Sensor-Sockel | „Buchsenleiste gerade 1X20 RM2,54" |
| Stiftleiste RM 2,54 | 1×40, gerade **und** gewinkelt | 3 | Verdrahtung | „Stiftleiste 1X40 RM2,54" |
| Abstandsbolzen | Nylon M3, 10 mm + Schrauben (Set) | 1 Set | Montage | „Abstandsbolzen Nylon M3 10mm" |

> ⚠ **Kondensator-Dielektrikum:** zwingend **X7R/X5R**, **nicht** Y5V/Z5U — Letztere
> verlieren unter DC-Bias bis 80 % Kapazität.
> Alternative zu Einzelwerten: Metallschicht-Sortiment E12 0207 1 % — aber **2 kΩ separat**
> kaufen (in E12 nicht enthalten).

---

## 2. DShot-Signalseite

| Bauteil | Spezifikation | Menge | Zweck | Reichelt-Suchbegriff |
|---|---|---|---|---|
| Widerstand **1,5 kΩ** | Metallschicht 0207, 1 % | 4 + Reserve | Open-Drain-Pullup nach 3,3 V, 1 pro Motor | „Metallschicht 1,5k 0207" |
| *(Fallback)* **SN74LVC1T45** | Einzelbit-Pegelwandler, dual-supply, SOT | (4) | nur falls Open-Drain-Bench-Test (PINNING §2.6) scheitert | „74LVC1T45" |
| Cat-5-Kabelrest | 4 verdrillte Paare, ~0,5 m | 1 | 4 DShot-Leitungen (Signal + Masse verdrillt) | „Patchkabel Cat5" / Reststück |

JST-SH-Pigtail liegt dem ESC bei — **nicht** kaufen.

---

## 3. ESC-Beschaltung

| Bauteil | Spezifikation | Menge | Zweck | Reichelt-Suchbegriff |
|---|---|---|---|---|
| Elko **470 µF / 25 V** Low-ESR | Panasonic **EEU-FR1E471**, radial ⌀10×12,5, RM5 | 1 | direkt auf ESC +/− Pads (liegend, fixieren) | „Panasonic FR 470µ 25V" |

---

## 4. Board-Zweig — Versorgung TC399

Reihenfolge im Zweig: Sicherung (Plus) → Ferrit (beide Adern) → TVS (parallel) → Elko (parallel) → X501.

| Bauteil | Spezifikation | Menge | Zweck | Reichelt-Suchbegriff |
|---|---|---|---|---|
| Inline-Sicherungshalter | 5×20 mm, mit Kabelenden | 1 | Absicherung Board-Zweig | „Sicherungshalter 5x20 Kabel" |
| Glassicherung 5×20 mm träge | **T2A** (T2,5A/T1,6A auch ok) | 3 | — | „Feinsicherung 5x20 träge 2A" |
| *Alternative:* Polyfuse | rückstellbar, ~1,1 A Haltestrom | (1) | statt Glassicherung | „PTC Polyfuse 1,1A" |
| Klappferrit | Ø 5–7 mm (**Würth 74271132**), beide Adern durch | 1 | EMV | „Klappferrit 74271132" |
| **TVS-Diode P6KE27A** | DO-15, **axial** — NICHT SMBJ26A/SMD | 2 | Überspannungsschutz | „P6KE27A" |
| Elko **470 µF / 25 V** Low-ESR | Panasonic FR, radial | 1 | Puffer Board-Zweig | „Panasonic FR 470µ 25V" |
| Silikonlitze **20 AWG** (0,5 mm²) | rot + schwarz, je 1 m | 1 | Board-Zuleitung | „Silikonlitze 0,5mm² rot/schwarz" |

Hohlstecker 5,5/2,5 mm Schraubklemme: **bereits vorhanden** — nicht kaufen.

---

## 5. Leistungspfad Akku → Verteiler (teils Reichelt, teils Modellbau/Kfz)

| Bauteil | Spezifikation | Menge | Bezug |
|---|---|---|---|
| Silikonlitze **12 AWG** (4,0 mm²) | rot + schwarz, je 0,5 m | 1 | Reichelt/Modellbau |
| XT90-S Anti-Spark | Paar (Trennstelle/Kill) | 1 | Modellbau (Reichelt teils) |
| Flachsicherung **80 A** (MAXIVAL) | Kfz-Format | 2 | Kfz-Zubehör |
| Sicherungshalter MAXIVAL *oder* 2× Ringkabelschuh M5 | — | 1 | Kfz / Reichelt |
| XT60-Buchse | — | 1 | Modellbau (Reichelt teils) |
| XT60 Y-Parallelkabel | **mind. 12 AWG prüfen** | 1 | Modellbau |

---

## 6. Verbrauch / Werkzeug (Reichelt-relevant)

| Bauteil | Spezifikation | Menge | Reichelt-Suchbegriff |
|---|---|---|---|
| Schrumpfschlauch-Sortiment | 2:1, inkl. 10 mm für XT60 | 1 | „Schrumpfschlauch Sortiment 2:1" |
| Signallitze-Set | 26 AWG Silikon, mehrfarbig (6–10 Farben à 5–10 m) | 1 | „Silikonlitze Set 26AWG" (sonst Amazon/eBay) |
| Schutzbrille | — | 1 | „Schutzbrille" |

> **Smoke Stopper** (Erst-Einschaltschutz, ~10 €): eher Modellbau/FPV-Shop, nicht Reichelt.

---

## 7. NICHT bei Reichelt (nur Verweis)

- **Sensoren → Digikey** (Sammelbestellung >90 $, kein Versandzuschlag):
  EV_ICM‑42688‑P (IMU, ~32 $) · SparkFun NEO‑M9N Chip-Antenne 15733 (GNSS, ~76 $) ·
  BMP581-Board (Baro) · MMC5983MA-Board (Mag, optional).
- **Antrieb → Modellbau (funduinoshop/Lindinger):**
  4× Motor EMAX XA2212 **980 KV** · Flywoo GOKU G45M 4-in-1-ESC · Propeller 9450 CW/CCW ·
  Prop-Muttern/Adapter. *(Motor-KV/Prop hängen an der finalen Rahmengröße — vor Bestellung fixieren.)*
- **Energie → Lindinger:** 2× LiPo 4S 4000 mAh 25/50C XT60 · Ladegerät ≥4S mit Balancer · LiPo-Safe-Beutel.
- **Bewusst nicht gekauft:** Step-down-Wandler (Board nimmt 12 V direkt) · Pegelwandler-IC als
  Standard (Teiler/Open-Drain statt IC) · separates Powermodul (ESC misst Strom) ·
  Sender/Empfänger (XCP über Ethernet) · PDB (4-in-1 verteilt selbst).

---

## 8. Sicherheits-/Aufbauhinweise (aus dem Übergabestand)

- **Pegel:** Ports sind 5 V (VEXT). SPI-Ausgänge über 1 kΩ/2 kΩ-Teiler auf 3,3 V (Steckbrett: 3,30 V
  gemessen); MISO/INT direkt über TTL-Pad; I²C ohne Wandler (Open-Drain + Breakout-Pullups).
- **IMU-Versorgung:** JP1/JP2 Pin 2 mit 3,3 V speisen, Jumper offen (EV-Board-LDOs bleiben aus).
- **Leitungslängen:** SPI ≤10 cm @10 MHz · I²C-Bus gesamt ≤30 cm · DShot ≤15 cm (jede Ader mit Masse verdrillt).
- **LiPo/80 A:** Gefahr ist Kurzschluss/Verbrennung/Brand, nicht Stromschlag. Smoke Stopper beim
  Erst-Einschalten, Akku zuletzt an/zuerst ab, Sand/Metallbehälter bereit.
