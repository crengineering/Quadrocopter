# Propeller choice → firmware sample rate

**ASPICE:** SYS.3 supporting analysis — propeller → sample-rate path · realizes SYS2-MEC-002, SYS2-MEC-004, SYS2-MEC-006, SYS2-TIM-001 · process: QuadSE/requirements/README.md

**Decided, 2026-08-30 (SYS1-012 gate 1).** The propeller ambiguity this note
used to carry is resolved: **F450**, `l` = 225 mm; **SunnySky X2216-III V3,
KV880**, 4S; **HQProp 10×4,5″ (Ø 254 mm), 2 blades**. §2 below re-derives the
sample-rate arithmetic for this one airframe. `kT`/`kQ`/`tau`/`w_max` are
**not yet measured** — SYS2-MEC-004's bench sweep is blocked on the actuation
path (SYS2-ACT-001) — so `quad_params.m`'s numeric fields are unchanged
(still the small-prop placeholder example); this section states the
*expected* range, sourced to the motor's one rpm-carrying datasheet row, and
flags it as such throughout.

Written 2026-08-27, from the measured firmware side in
`crengineering/AurixTricore` (branch `feature/refactoring`). Re-derived
2026-08-30 (flight-control, SYS1-012 gate 2) against the decided drive and the
corrected SYS2-MEC-006.

---

## 1. Why the propeller sets a firmware constant

The propeller fixes the thrust coefficient `kT`, which fixes the hover rotor
speed through the trim condition `4·kT·ω² = m·g`. Rotor speed times blade count
is the **blade-pass frequency** — the dominant vibration the IMU sees. The
estimator's sample rate must put Nyquist **above** that band, or blade-pass
folds down into the control bandwidth as an alias the filters cannot remove.

```
propeller  ->  kT  ->  w_hover = sqrt(m*g/(4*kT))  ->  blade-pass = n_blades * w_hover
                                                    ->  required sample rate > 2 * blade-pass
```

Nothing else in the firmware depends on the propeller. The control gains are
continuous-time (`quad_params.m:26-28`) and rate-independent; `Ts` enters the
control law in exactly one line (`flight_ctrl.c:114`, backward-Euler integrator)
and is fed the *measured* tick, not a constant.

---

## 2. The ambiguity is resolved — one airframe, expected numbers pending measurement

`quad_params.m` (small, fast prop) and `doc/projektplan.md` (large, slow
prop) used to describe two live candidates. SYS1-012 gate 1 (2026-08-30) fixed
the drive, and it collapses onto the **`projektplan.md` figures** — the
large-prop candidate — not the `quad_params.m` placeholder:

| | decided drive |
|---|---|
| Frame | F450, `l` = 225 mm |
| Motor | SunnySky X2216-III V3, KV880, 67,5 g, 7 pole pairs (12N14P) |
| Propeller | HQProp 10×4,5″ (Ø 254 mm), 2 blades |
| Pack | 4S (Wellpower Ultima 4000 mAh) |
| AUM (incl. 10 m airborne tether) | **1,77–1,82 kg** (T/W 2,20–2,26) — dispatch/SYS1-012.md §4 |

**`kT` has no measurement yet** for this exact pair — SYS2-MEC-004's bench
sweep needs the actuation path (SYS2-ACT-001), which doesn't exist. The only
sourced number is one manufacturer datapoint that *carries rpm* (the rest of
the vendor table is thrust-vs-current only, from which `kT` cannot be
derived): APC 11×4.7 @ 11,1 V, 1000 gf at 6193 rpm ⇒ ω = 648,5 rad/s ⇒
`kT ≈ 2,33e-5` for an **11″** blade. Scaled to the 10″ HQProp actually flown,
the motor datasheet note (`procurement/datasheets/motor-sunnysky-x2216-iii-v3-880kv.md`)
puts this **near 1,4–1,6e-5** — corroboration, explicitly not a substitute
for the bench measurement.

Using that expectation range against the measured AUM band:

```
T_hover/motor = AUM·g/4                    = 4,34–4,46 N   (442–455 gf)
w_hover       = sqrt(T_hover / kT)         ≈ 521–565 rad/s
f_rotor       = w_hover / (2π)             ≈ 83–90 Hz
f_blade       = 2 · f_rotor (2 blades)     ≈ 166–180 Hz
```

This lands in the same band `projektplan.md:135` already named ("~83 Hz
Hover-Grundton") — expected, since a Ø 254 mm prop is what that document was
written against — and matches the ~18 A / 267 W hover current the vendor
thrust table predicts (dispatch/SYS1-012.md §4a, §6).

`quad_params.m:2,8,9,10,11` (`m`, `kT`, `kQ`, `tau`, `w_max`) are **not
touched by this pass** — no measurement exists, and the gate-2 instruction
is explicit: no invented numbers go into that file. §4 below states what
does update them, and how. `quad_params.m:1`'s *"Beispiel: 450er-Klasse"*
label is now literally true (the decided frame is an F450) but the file's
numeric example (small fast prop) is still the placeholder; do not read the
label as confirmation of the numbers.

`quad_params.m:57`'s inline comment said `-> 990.5 rad/s`, which requires
`kT = 3.0e-6`; the file has carried `kT = 5.0e-6` (⇒ 767.2 rad/s) since
before this pass. **Fixed in this pass** (comment only, no value changed):
see the file.

---

## 3. What the firmware does today

Measured on hardware, not estimated
(`AurixTricore/docs/IMU_INTERRUPT.md` §5.6):

| | |
|---|---|
| IMU data-ready | **1014.2 Hz** (985.04 µs mean, 1.78 µs stddev) |
| Nyquist | **507 Hz** |
| Estimator (`NavTask_step`, CPU1) | 50 Hz today; moves to DRDY-clocked 1014.2 Hz in T15 |
| Worst-case dispatch | **170 µs** measured, against a 300 µs budget |
| Headroom at 1014 Hz | CPU1 ~17-22 % |

The ICM-42688-P is band-limited for a 1 kHz output rate, so consuming every
edge is correct and consuming every *second* edge would be decimation without a
decimation filter.

**At 1014 Hz, Nyquist 507 Hz clears the decided drive with margin.** §2's
hover-point estimate (166–180 Hz blade-pass) sits well under it; §3a below
works the full-throttle case, which is the one that can actually bite.

---

## 3a. SYS2-MEC-006 — adjudicated for this drive, 2026-08-30

SYS2-MEC-006 was corrected the same day: the sufficient no-aliasing case
stays `f_blade < 507 Hz` (design target), but exceeding it is only a defect
if the alias actually lands in the control band — `min_k |f_blade − k·fs|`
must stay ≥ 20× the attitude crossover (~1,91 Hz ⇒ ≥ 40 Hz), evaluated at
the **measured** `w_max`, not a no-load bound. **Adjudication belongs to
flight-control** (SYS2-MEC-006's own wording); here it is, against the
decided drive:

- **No-load bound** (worst case, never reached under load): KV880 at a
  fully-charged 4S pack (16,8 V) ⇒ 14 784 rpm ⇒ 246 Hz rotor ⇒ **493 Hz
  blade-pass** (dispatch/SYS1-012.md §2). This clears the raw `< 507 Hz` target
  with **14 Hz** of margin, and even if it didn't, its alias distance
  `min(493, |493−1014,2|) = 493 Hz` is ~250× the 40 Hz threshold — harmless
  either way.
- **Realistic loaded full-throttle** is well below the no-load bound — a
  loaded Ø 254 mm prop cannot reach no-load rpm. No measurement exists yet
  (SYS2-MEC-004), but by the same physics cited in the SYS2-MEC-006 change log
  for this motor class, expect roughly 8000–9000 rpm loaded ⇒ 133–150 Hz
  rotor ⇒ **~267–300 Hz blade-pass** — comfortably under 507 Hz on the raw
  target, and its alias distance (`min(300, 1014,2−300) = 300 Hz`) is again
  far above the 40 Hz threshold.

**Judgement: SYS2-MEC-006 is satisfied by design for this drive under both
forms of the criterion**, using either the conservative unloaded bound or
the expected loaded full-throttle figure. No IMU ODR change, no
`INT_CONFIG1` edit, no `NavTask_step` re-cost is anticipated. This does not
set `verified` — that needs the measured `w_max` from SYS2-MEC-004, which is
blocked on SYS2-ACT-001 — but nothing here argues for holding the firmware
sample rate hostage to that measurement landing a particular way.

---

## 4. When the bench sweep lands — the procedure

The propeller/motor pair is now decided (§2); what is still open is the
**measurement**, blocked on SYS2-ACT-001. When the sweep exists (see
SWE1-MDL-003, dispatch/SYS1-012.md §6 for the rig and fit method):

1. **Fit `kT`, `kQ`, `tau`, `w_max`** from the bench sweep with the
   coefficient-fit script (SWE1-MDL-003) and put them in `quad_params.m:8-11`.
   Set the real `m` at `:2` from the SYS2-MEC-003 weigh-in once the frame and
   breakout PCB are no longer estimates. See §5 (quad_params.m update path)
   for exactly how, with what provenance.
2. **Re-run the arithmetic:**
   ```
   w_hover    = sqrt(m*g/(4*kT))          [rad/s]
   f_rotor    = w_hover / (2*pi)          [Hz]
   f_blade    = n_blades * f_rotor        [Hz]   (n_blades = 2, decided)
   f_blade_max= n_blades * w_max/(2*pi)   [Hz]   full-throttle, measured
   ```
3. **Check `f_blade_max` by the SYS2-MEC-006 criterion (§3a), not the raw
   Nyquist bound alone:**
   - `f_blade_max < 507 Hz` → nothing changes; §3a's expectation is that
     this holds with room to spare.
   - `f_blade_max ≥ 507 Hz` → before touching firmware, check the alias
     distance `min_k |f_blade_max − k·fs|` against the 40 Hz threshold
     (§3a). Only a genuine sub-40 Hz alias justifies the firmware change
     below — a bare Nyquist miss with a large alias distance does not.
   - **Firmware change, if actually triggered:** `INT_CONFIG1` must become
     `0x60` (8 µs pulse, de-assert disabled — required at ODR ≥ 4 kHz, see
     `AurixTricore/docs/ICM42688P.md` §8.2), and `NavTask_step`'s 300 µs
     budget must be re-costed against the shorter period.
4. **Nothing else in the firmware moves.** No gain retuning: the gains are
   continuous-time and `Ts` tracks the measured tick.

## 5. `quad_params.m` update path

| line | field | source once measured | how it stays traceable |
|---|---|---|---|
| `:2` | `m` | SYS2-MEC-003 weigh-in table (dispatch/SYS1-012.md §4), once the frame (400 g estimate) and breakout PCB (100–150 g estimate) are weighed, not planning values | evidence/INDEX.md row + dated comment citing it |
| `:8` | `kT` | SWE1-MDL-003 fit script output on the bench sweep | evidence/INDEX.md row (MF4 of the sweep) + fit script's reported R²/residual in the comment |
| `:9` | `kQ` | same sweep, current/torque channel, same fit run | same evidence row |
| `:10` | `tau` | same sweep, throttle-step response | same evidence row |
| `:11` | `w_max` | top of the same sweep (measured, not KV × V_max) | same evidence row |
| `:57` | hover comment | recomputed from the new `m`, `kT` at the same time | falls out of the arithmetic in §4 step 2 |

Every one of `:2,8,9,10,11` is a **proposal, not a direct edit** — per
CLAUDE.md's control-law/parameter rule, changes to `quad_params.m` go to the
user as a diff with rationale and expected closed-loop effect before being
applied, even though the source becomes a measurement rather than a guess.
No line changes without a row in `QuadSE/evidence/INDEX.md` (flight-control
cannot add that row — report it, the system architect enters it).

**The parameter set exists three times with no SSoT (PLAN-000/T-000.4):**
`quad_params.m` (here), `sil/flight_ctrl_lct.c:18-51`, and
`AurixTricore/src/asw/CtrlReplay.c:80-113` — checked at this writing:

- **`m` and `w_max` are literal duplicated fields** in both C structs
  (`1.20f` and `1200.0f`, identical in both files today). Either line
  changing means both C sites change too.
- **`kT` and `kQ` are not literal fields** in the C struct — they are
  **baked into the 4×4 Mixer-Inverse constant block** in both C files
  (`MIX_inv = inv(MIX)` from `quad_params.m:17-22`, hand-copied as 16
  floating literals). A `kT`/`kQ` change means **regenerating that matrix
  and updating both C files with it** — easier to miss than a named field,
  because nothing in the C source says "this came from kT".
- **`tau` is not in the C controller struct at all** — it is a plant/ESC-lag
  parameter consumed by the Simulink actuator model, not by
  `flight_ctrl.c`'s control law, so a `tau` update only touches
  `quad_params.m` (and, once it exists, wherever the estimator plant model
  or a firmware ESC-response identification needs it — not the case today).

Name whichever of these a `kT`/`kQ`/`w_max`/`m` proposal actually touches;
`tau` alone does not currently reach the C side.

---

## 6. The frame resonance is the other half

`projektplan.md:135` also notes the frame's own resonance must not sit on the
hover fundamental. That is a mechanical constraint, not a sampling one, and it
is **not** covered by the rate argument above — a structural mode at the blade
frequency is excited regardless of how fast the IMU is read. The planned RPM
notch filter from the DShot speed feedback (`README.md`, *Actuation*) is the
mitigation; it needs the real prop and the real frame before it can be tuned.

---

## 7. What is still unmeasured

- **No phase margin exists anywhere in this repo.** `linearize/linearize_hover.m:13-16`
  runs `linmod` and prints eigenvalues only — no `margin()`, no saved state-space.
  The crossover figures used on the firmware side (yaw ω_c = Kp/I = 12 rad/s
  = 1.91 Hz) are re-derived from the gains and inertias, i.e. design intent, not
  a measured loop.
- **Blade count is decided (2, HQProp 10×4,5″)**, no longer an assumption —
  but still not what `quad_params.m` encodes anywhere as a named field; §2's
  arithmetic above hard-codes it.
- **No file records why `Ts = 0.001` was chosen.** It is asserted at
  `quad_params.m:50` and repeated in `sil/`, `pil/`, `README.md` and
  `projektplan.md` — it is the sensor's rate, adopted, not a derived requirement.
  The control law itself needs only ~38 Hz (10-20x the 1.91 Hz crossover); the
  fastest pole in the modelled aircraft is the motor+ESC lag at **3.18 Hz**
  (`quad_params.m:10`, `tau = 0.05`).
