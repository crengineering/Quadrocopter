# Projektplan — Quadrocopter-Flugregler auf AURIX TC399

**ASPICE:** MAN.3 — Projektplan; §3 (Architektur) abgelöst durch `QuadSE/architecture/SYS3_SYSARC.md` (SYS.3), Anforderungen jetzt in `QuadSE/requirements/` · process: QuadSE/requirements/README.md

Gesamtübersicht des Projekts: Ziel, Architektur, Teststufen, Arbeitspakete, offene Punkte.
Quellen: Übergabedokument, `PINNING.md` (Pin-SSoT), `einkaufsliste.md`, `MBD_PATH.md`.

---

## 1. Ziel & Kernidee

Eigener Quadrocopter-Flugregler über die **komplette Model-Based-Design-Kette**:
Simulink → Codegenerierung → SiL/PIL → Zielhardware auf einem **Infineon AURIX TC399**
(Automotive-Mehrkern-µC, 6× TriCore @ 300 MHz).

Portfolio-Story und technischer Anspruch:
- eigener **Kaskadenregler** auf einem Automotive-µC,
- eigener **bidirektionaler DShot-Treiber** (Drehzahlregelung pro Motor auf dem TC399),
- **Verifikation gegen die Simulation** mit echten Messschrieben (XCP-DAQ / Vektor-Replay).

Der Prüfstandsnachweis gegen die Simulation ist bewusst das Rückgrat der Story — stärker
als ein reines Flugvideo. **Der Regler ist und bleibt der TC399.**

---

## 2. Aktueller Stand (erledigt)

| Bereich | Stand |
|---|---|
| Regelungsmodell | 6-DoF-Modell + Kaskadenregler (Position PD → Attitude P → Rate PI, Ts = 1 ms) |
| Codegen & Verifikation | C99 via SiL erzeugt, per **Vektor-Replay auf dem TC399 verifiziert** (3,9 µs/Zyklus) |
| Kommunikation | Ethernet/lwIP/**XCP** läuft auf CPU0 (Mess-/Kalibrierzugriff) |
| Hardware-Planung | Sensorik & Aktorik elektrisch durchgeplant, Pegelfrage am Board **gemessen** (Ports = 5 V) |
| Pinbelegung | in **`PINNING.md`** konsolidiert (Single Source of Truth, gegen iLLD + Datenblatt + Manual geprüft) |
| Beschaffung | 4 Sensoren bei Digikey **bestellt**; Reichelt-Kleinteile als CSV vorbereitet |

Aktuelle Phase: **Übergang zur realen Hardware — Sensorik zuerst.**

---

## 3. Systemarchitektur

### 3.1 Rechenplattform
**TriBoard TC3X9**, Device **TC399 B-step, LFBGA-516**. Rollenverteilung der Kerne:
- **CPU0** — Kommunikation: Ethernet/lwIP/XCP, Messwerterfassung.
- **CPU1** — Zustandsschätzer (Komplementärfilter, Quaternion, 1 kHz) + Regler.
- übrige Kerne — Sync/Reserve.

### 3.2 Sensorik
| Rolle | Bauteil | Bus | Rate |
|---|---|---|---|
| IMU (6-Achsen) | ICM-42688-P | SPI (QSPI0), INT1 = Data-Ready | 1 kHz |
| Barometer | BMP581 | I²C0 | 50 Hz |
| Magnetometer | MMC5983MA | I²C0 (shared) | 100 Hz |
| GNSS | u-blox NEO-M9N | I²C0 (shared) | 10 Hz |

### 3.3 Aktorik
4× BLDC **EMAX XA2212 980 KV**, 4-in-1-ESC **Flywoo GOKU G45M** (AM32), Protokoll
**bidirektionales DShot300** — eine Signalleitung pro Motor, Drehzahl-Rückmeldung für den
RPM-Notchfilter. TX = GTM ATOM0, RX = GTM TIM0/TIM7, Richtungswechsel per IOCR (1 ms-Zyklus).

### 3.4 Pegel & Versorgung (Kern-Erkenntnisse)
- Board-Ports sind **5 V** (VEXT = V_UC, gemessen P00.1 = 5,0 V) → alle 3,3-V-Teile brauchen Pegelanpassung.
- **SPI-Ausgänge** (SCLK/MOSI/CS): Teiler 1 kΩ/2 kΩ → 3,3 V (Steckbrett: 3,30 V gemessen).
- **MISO/INT**: direkt, TTL-Pad-Modus (V_IH = 2,0 V). **I²C**: Open-Drain + Breakout-Pullups.
- **DShot**: Open-Drain + 1,5 kΩ-Pullup nach 3,3 V (Bench-Test §Open-Drain-ALT ausstehend).
- **Board-Versorgung**: LiPo 4S direkt an X501 (3,5–40 V zulässig), kein Step-down.
  Zweig: Sicherung → Ferrit → TVS (P6KE27A) → Elko → X501.

Details je Pin/Signal: `PINNING.md` (§2 Sensor/DShot, §2.5 Sensor-Elektrik, §2.6 DShot-Treiber).

---

## 4. Software-/Regelungsarchitektur

- **BSW/ASW-Trennung:** Base-Software besitzt die Hardware (iLLD-Wrapper, Bus-Treiber, Dienste);
  Application-Software (Regler/Schätzer) ruft nur BSW, nie iLLD direkt.
- **Regler:** Kaskade Position PD → Attitude P → Rate PI, fester 1-ms-Takt, FPU-basiert.
- **Schätzer:** Komplementärfilter (Quaternion-Update + Accel/Mag-Korrektur), Baro für Höhe.
- **DShot-Treiber:** Einzelpin-bidirektional (ATOM0 TX / TIM0·TIM7 RX), DMA-gefüttert.
- **Verifikation:** SiL → PIL → Vektor-Replay auf Ziel; XCP-DAQ liefert Messschriebe zum
  Abgleich Simulation ↔ Realität.

---

## 5. Teststufen-Roadmap

| Stufe | Aufbau | Regelungs-/HW-Ziel | Sicherheit |
|---|---|---|---|
| **0** | Motoren am Rig, **ohne Propeller** | DShot-Treiber, Arming, Kill | Kill getestet, keine Props |
| **1** | Kugelgelenk-Rig (Friktion hoch → frei) | Rate- + Attitude-Regler, 3 Achsen | Rig hält den Copter |
| **2** | Leine über Rasen, 1,5–2 m | Höhenregelung (Baro-Fusion) | Leine + weicher Untergrund |
| **3** | Freier Flug, Lage geregelt | Failsafe, später Sender/Empfänger | Failsafe-Logik aktiv |
| **4** | Positionsregelung | GNSS (Freiraum) / Optical Flow | — |

**Kill-Konzept:** (1) Software-Disarm über XCP, (2) Watchdog im TC399 bei XCP-Ausfall,
(3) physisch: XT90-S als Trennstelle, Akku in der Rig-Phase auf dem Tisch über Verlängerung.
Kein Schalter am Copter — nie in laufende Propeller greifen.

**Groundstation:** XCP über Ethernet für Rig-/Leinen-Phase; **kein** RC-Empfänger in diesen Stufen.

**Kugelgelenk-Rig:** Stativ-Kugelkopf ≥ 8–10 kg, M10-Stab, beschwerte Grundplatte;
Pendel-Störterm M ≈ m·g·d·sin(φ) ins Simulink-Modell aufgenommen.

---

## 6. Arbeitspakete & Reihenfolge

| WP | Inhalt | Voraussetzung | Status |
|---|---|---|---|
| **A — SW-Skelette** | BSW-Wrapper QSPI0 (IMU) + I²C0 (Baro/Mag/GNSS) + Registertreiber; build-clean unter TASKING/MISRA | keine (jetzt, parallel) | offen |
| **B — Sensor-Aufbau** | Lochraster + Teiler/TTL-Pads + 3V3-Tap; erster Read-out; Bench-Checks (s. §7) | Digikey + Reichelt da | offen |
| **C — Schätzer** | Komplementärfilter auf echten Sensordaten; Abgleich gegen Sim | WP-B | offen |
| **D — Aktorik** | DShot-Treiber + Open-Drain-Bench-Test (P22.0/P22.2/3); ESC am Rig (Stufe 0–1) | WP-A/B, Aktorik-Teile | später |
| **E — Leistungselektronik** | Board-Versorgungszweig, LiPo-Pfad, Sicherheit | WP-D | später |
| **F — Regelkreis** | geschlossener Regelkreis, Stufen 1–4 | WP-C/D/E | später |

**Nächster konkreter Schritt:** WP-A kann **jetzt** starten (kein Bauteil nötig), damit beim
Eintreffen der Teile Code bereitliegt. Danach WP-B (Sensor-Read-out) als erster Hardware-Schritt.
Aktorik/Leistungselektronik (WP-D/E) bewusst nach hinten.

---

## 7. Offene Punkte / Risiken

**Bench-Checks (vor Verdrahtung/Treiber):**
- Überschreibt iLLD `initModule` die TTL-Pad-Einstellung? Nach Init Register zurücklesen.
- Open-Drain im ALT-Modus (DShot) auf **P22.0 und P22.2/P22.3** (LVDS_TX/HSCT-Stub, höheres Risiko).
- Ist **P22.7** (IMU-INT) ERU-/GTM-TIM-fähig, oder nur Polling?

**Mechanik/Rahmen (offene Auslegung, kein Konflikt):**
- Rahmengröße/Motor-KV/Propeller sind gekoppelt und noch zu fixieren; Randbedingung ist der
  **Board-Footprint (100×160 mm)** — die Rahmenfläche muss ihn aufnehmen.
- Material **PETG** (nicht PLA, 60 °C Glasübergang), Arme liegend drucken (Schichtfestigkeit);
  Hybrid CFK-Rohr-Arme + gedruckte Zentralplatte spart 150–200 g und ist steifer.
- Planungswerte: Rahmen ~400 g, Abfluggewicht ~1,5 kg, Schub/Gewicht ~2,1.
- Eigenfrequenz beachten (Rahmenresonanz ≠ ~83 Hz Hover-Grundton); RPM-Notchfilter aus DShot-Drehzahl.

**Elektrisch/extern:**
- ESC-Signal-Spannungstoleranz (GOKU G45M / AM32) — externe Teilespec.
- Stromsense-Skalierung: **VAREF = 5 V**, ESC-Ausgang 0–3,3 V nutzt nur ⅔ des ADC-Bereichs.

---

## 8. Grobe Meilensteine

1. **M1 — Sensor-Read-out steht:** IMU über SPI + Baro/Mag/GNSS über I²C liefern plausible
   Rohdaten auf dem TC399 (WP-A/B).
2. **M2 — Schätzer live:** Lage-/Höhenschätzung aus echten Sensoren, deckt sich mit Sim (WP-C).
3. **M3 — Aktorik am Rig:** DShot-Treiber treibt 4 ESCs, Arming/Kill sicher, Stufe 0/1 (WP-D).
4. **M4 — Geschlossener Regelkreis:** Rate/Attitude am Kugelgelenk-Rig geregelt (Stufe 1).
5. **M5 — Freiflug:** Leine → freier Flug, Höhen-/Lageregelung (Stufe 2–3).
6. **M6 — Position:** GNSS/Optical-Flow-gestützte Positionsregelung (Stufe 4).

---

## 9. Referenzdokumente

| Thema | Datei |
|---|---|
| Pinbelegung (SSoT), Sensor-/DShot-Pins, Pegel, Treiber-Notizen | `PINNING.md` |
| Diagnose / Cal-Blöcke | `DIAGNOSTICS.md` |
| MBD-Kette (Simulink-Strang) | `MBD_PATH.md` |
| Globale Einkaufsliste | `einkaufsliste.md` (+ `reichelt_warenkorb.csv`) |
| Sensor-Datenblätter | `doc/IMU.pdf`, `Barometer.pdf`, `Magnetometer.pdf`, `GNSS.pdf` |
