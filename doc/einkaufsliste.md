# Einkaufsliste Quadrocopter TC399 — global

Vollständige Teileliste über alle Bezugsquellen. Master-Dokument; ersetzt
`einkaufsliste_reichelt.md`. Für den Reichelt-CSV-Import siehe `reichelt_warenkorb.csv`.

**Status:** ✅ bestellt · 🛒 morgen (Reichelt) · ⏳ später (Aktorik/Leistung) · 🧰 vorhanden
**Preise:** ✅ = auf Produktseite gesehen · ~ = Schätzung/Erfahrungswert · — = offen.

> **Beschaffungsregel:** vor jeder Auswahl Verfügbarkeit prüfen; bei gleichwertigen Optionen
> die sofort lieferbare wählen. Vorab per Websuche (Näherung), verbindlich ist die Lieferzeit
> im Warenkorb nach Import.

---

## Kostenüberblick

| Block | Bezugsquelle | Summe ca. | Status |
|---|---|---|---|
| Sensorik (4 Stück) | Digikey | ~130 € (~140 $) | ✅ bestellt |
| Kleinteile / Beschaltung | Reichelt | ~40–60 € | 🛒 morgen |
| Antrieb (Motoren/ESC/Props) | Modellbau (funduino/Lindinger) | ~140 € | ⏳ später |
| Energie (LiPo/Lader) | Lindinger | ~145 € | ⏳ später |
| Leistungspfad / Kfz-Teile | Kfz / Modellbau | ~25 € | ⏳ später |
| Litzen-Sets | Amazon/eBay | ~15–30 € | ⏳ später |
| Werkzeug / Verbrauch | gemischt | ~50–70 € | nach Bedarf |

Handoff-Referenzwert Aktorik + Beschaltung ≈ 415 € (ohne Sensorik, ohne Vorhandenes).

---

## 1. Sensorik — Digikey ✅ bestellt

| Bauteil | Funktion | Schnittstelle | Digikey-Nr. | Preis |
|---|---|---|---|---|
| TDK **EV_ICM-42688-P** | IMU (6-Achsen), INT1 = Data-Ready | SPI (QSPI0) | EV-ICM-42688-P / 18634550 | 32,45 $ ✅ |
| SparkFun **NEO-M9N** (Chip-Antenne) | GNSS | I²C | 15733 / 11481329 | 76,50 $ ✅ |
| **BMP581**-Board (Adafruit 6407 o. SparkFun 20170) | Barometer (Höhe) | I²C | 6407 / 26562856 | ~10 $ ✅ |
| MEMSIC **MMC5983MA-B** | Magnetometer | I²C | MMC5983MA-B / 10452798 | 20,95 $ ✅ |

I²C-Adressen (kollisionsfrei): BMP581 0x46/0x47 · MMC5983 0x30 · NEO-M9N 0x42.
IMU-Versorgung: JP1/JP2 Pin 2 = 3,3 V, Jumper offen (EV-Board-LDOs bleiben aus).

---

## 2. Kleinteile / Beschaltung — Reichelt 🛒 morgen

### 2.1 Im CSV enthalten (`reichelt_warenkorb.csv`, import-fertig)

| Bauteil | Spezifikation | Zweck | Reichelt-Artikelnr. | Menge |
|---|---|---|---|---|
| Widerstand 1,0 kΩ | Metallschicht 0207, 1 % | SPI-Teiler oben | `METALL 1,00K` | 10 |
| Widerstand 1,5 kΩ | Metallschicht 0207, 1 % | DShot-Pullup | `METALL 1,50K` | 10 |
| Widerstand 2,0 kΩ | Metallschicht 0207, 1 % (**echte 2 k, nicht 2,2 k**) | SPI-Teiler unten | `METALL 2,00K` | 10 |
| Widerstand 4,7 kΩ | Metallschicht 0207, 1 % | I²C-Pullup (Reserve) | `METALL 4,70K` | 10 |
| Widerstand 10 kΩ | Metallschicht 0207, 1 % | Pulldown IMU-INT1 | `METALL 10,0K` | 10 |
| Keramik-C 100 nF | **X7R**, RM 2,5 | Entkopplung | `X7R-2,5 100N` | 20 |
| Keramik-C 10 µF | **X7R**, 25 V, 1206 SMD | Stütz-C | `X7R-G1206 10 - 25` | 5 |
| Elko 470 µF/25 V | radial, **Low-ESR** (Panasonic FR) | ESC- + Board-Puffer | `RAD FR 470 - 25` | 2 |
| TVS-Diode | P6KE27A, DO-15 **axial** | Überspannungsschutz Board | `P6KE 27A` | 2 |
| Klappferrit | Würth 74271132, Ø ~8,5 mm | EMV Board-Zuleitung | `WUE 74271132` | 1 |
| Glassicherung 5×20 | träge, 2 A | Board-Zweig | `SICHERUNG 2,0AT` | 3 |
| Buchsenleiste 1×20 | gerade, RM 2,54 | Sensor-Sockel (steckbar) | `BL 1X20G8 2,54` | 4 |
| Stiftleiste 1×40 | gerade, RM 2,54 | Verdrahtung | `SL 1X40G 2,54` | 3 |

> `X7R-2,5 100N` und `SICHERUNG 2,0AT` sind plausibel abgeleitet — beim Import Produktnamen
> kurz gegenprüfen.

### 2.2 Noch manuell dazu (kein sauberer CSV-Code / Produkt-ID zum Direktaufruf)

| Bauteil | Spezifikation | Zweck | Reichelt-ID / Suche | Menge |
|---|---|---|---|---|
| Lochrasterplatine | FR4 **durchkontaktiert**, RM 2,54, ~100×80 mm | Trägerplatine | ID 105493 „Laborkarte FR4 durchk." | 2 |
| Inline-Sicherungshalter | 5×20, mit Kabelenden | Board-Zweig | ID 14678 (Print/Panel) o. Kfz | 1 |
| Distanzbolzen | Nylon M3, 10 mm + Schrauben | Montage | Suche „Distanzbolzen Polyamid M3x10" | 1 Set |
| Schrumpfschlauch | Sortiment 2:1 (inkl. 10 mm) | Isolation | ID 280190 | 1 |
| Schutzbrille | — | ab Motorbetrieb | Suche „Schutzbrille" | 1 |
| *(Fallback)* SN74LVC1T45 | Pegelwandler SOT | nur falls Open-Drain-Bench-Test scheitert | Suche „SN74LVC1T45" | 4 |

---

## 3. Antrieb — Modellbau (funduinoshop / Lindinger) ⏳ später

| Bauteil | Spezifikation | Menge | Preis | Hinweis |
|---|---|---|---|---|
| Motor **EMAX XA2212 980 KV** | BLDC, 5-mm-Welle | 4 | 18,43 €/Stk = 73,72 € ✅ | 820/980 KV unter einer Nr. — **980 wählen** |
| 4-in-1-ESC **Flywoo GOKU G45M** | AM32, 45 A/Kanal, bidir. DShot300, Stromsensor | 1 | 40,30 € ✅ | — |
| Propeller **9450** CW/CCW-Satz | Aufnahme-Ø zur 5-mm-Welle prüfen | 2–4 Sätze | ~5–8 €/Satz ~ | AliExpress ok (Verschleiß) |
| Prop-Muttern / Adapter | Links- + Rechtsgewinde prüfen | n. Bedarf | ~5 € ~ | — |

Motoren 4× identisch, Drehrichtung in AM32 gesetzt. Bei AliExpress: Fälschungsrisiko +
fehlende Schubtabelle (fürs Simulink-Motormodell gebraucht).

> ⚠ Motor-KV / Propellergröße hängen an der finalen Rahmenwahl. Aktueller Stand: F450 + 9450
> (980 KV). Vor Bestellung fixieren.

---

## 4. Energie — Lindinger ⏳ später

| Bauteil | Spezifikation | Menge | Preis |
|---|---|---|---|
| LiPo 4S 4000 mAh 25/50C | XT60 (Wellpower Ultima) | 2 | 42,99 €/Stk = 85,98 € ✅ |
| Ladegerät mit Balancer | ≥ 4S | 1 | 40–60 € ~ |
| LiPo-Safe-Beutel | — | 1 | ~10 € ~ |

---

## 5. Leistungspfad Akku → Verteiler ⏳ später (Kfz / Modellbau / Amazon)

| Bauteil | Spezifikation | Menge | Bezug |
|---|---|---|---|
| Silikonlitze 12 AWG (4,0 mm²) | rot + schwarz, je 0,5 m | 1 | Amazon-Set / Modellbau |
| XT90-S Anti-Spark | Paar (Trennstelle/Kill) | 1 | Modellbau |
| Flachsicherung 80 A (MAXIVAL) | Kfz-Format | 2 | Kfz-Zubehör |
| Halter MAXIVAL *oder* 2× Ringkabelschuh M5 | — | 1 | Kfz |
| XT60-Buchse | — | 1 | (in Reichelt §2.2 / Modellbau) |
| XT60 Y-Parallelkabel | **mind. 12 AWG prüfen** | 1 | Modellbau |

ESC-XT30-Kabel wird **nicht** verwendet — 12 AWG + XT60 direkt an die ESC-Pads.

---

## 6. Litzen — Amazon/eBay ⏳ später

| Bauteil | Spezifikation | Menge | Preis |
|---|---|---|---|
| Signallitze-Set | 26 AWG Silikon, mehrfarbig (6–10 Farben à 5–10 m) | 1 | ~10–15 € ~ |
| Silikonlitze 20 AWG | rot + schwarz (Board-Zuleitung) | je 1 m | (im Set) |

Reichelt verkauft nur 25/50-m-Rollen → Set günstiger. Alternativ Cat-5/Servokabel schlachten (0 €).

---

## 7. Werkzeug / Verbrauch (nach Bedarf)

| Teil | Preis | Bemerkung |
|---|---|---|
| Digitalwaage 0,1 g | ~15 € | Schubmessung (Küchenwaagen-Methode) + Auswiegen |
| Smoke Stopper | ~10 € | Erst-Einschaltschutz (FPV-Shop) |
| Crimpzange Rohrkabelschuhe | ~25 € | nur falls nicht vorhanden |
| Eimer Sand / Metallbehälter | — | LiPo-Brandschutz (Baumarkt/vorhanden) |

*(Schrumpfschlauch-Sortiment + Schutzbrille laufen über Reichelt §2.2.)*

---

## 8. Bereits vorhanden 🧰 (nicht kaufen)

- Hohlstecker 5,5/2,5 mm Schraubklemme (Board-Versorgung)
- JST-SH-Pigtail (liegt dem ESC bei)
- TriBoard TC3X9 (TC399), miniWiggler/DAP, Ethernet-Setup

## 9. Bewusst NICHT gekauft

Step-down-Wandler (Board nimmt 12 V direkt) · Pegelwandler-IC als Standard (Teiler/Open-Drain
statt IC) · separates Powermodul (ESC misst Strom) · Sender/Empfänger (XCP über Ethernet) ·
PDB (4-in-1 verteilt selbst) · Propellerwuchter.

---

## 10. Kritische Bauteil-Hinweise

- **Kondensatoren:** X7R/X5R **zwingend**, nie Y5V/Z5U (bis 80 % Kapazitätsverlust unter DC-Bias).
- **Widerstand 2 kΩ:** echte 2,0 kΩ, **nicht** 2,2 kΩ — sonst stimmt der SPI-Teiler (1 k/2 k → 3,3 V) nicht.
- **Elko:** **Low-ESR**-Typ (Panasonic FR), sonst taugt er nicht als ESC-Stütz-C.
- **TVS P6KE27A:** DO-15 **axial**, nicht die SMD-Variante (SMBJ26A).
- **VAREF = 5 V** am Board: ESC-Stromsense 0–3,3 V nutzt nur ⅔ des ADC-Bereichs → in Skalierung einrechnen.
- **Leitungslängen:** SPI ≤ 10 cm @10 MHz · I²C-Bus ≤ 30 cm · DShot ≤ 15 cm (Signal + Masse verdrillt).
- **Sicherheit (80 A/LiPo):** Gefahr = Kurzschluss/Verbrennung/Brand (nicht Stromschlag). Smoke Stopper
  beim Erst-Einschalten, Akku zuletzt an / zuerst ab, Sand/Metallbehälter bereit, Schmuck ab.
