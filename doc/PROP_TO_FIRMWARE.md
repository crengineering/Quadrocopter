# Propeller choice → firmware sample rate

**Open item.** The propeller is not yet fixed (`README.md`, *Mechanics*). This
note records the one place that choice reaches into the flight firmware, so the
path is already clear when the decision is made.

Written 2026-08-27, from the measured firmware side in
`crengineering/AurixTricore` (branch `feature/refactoring`).

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

## 2. The two figures in this repo describe two different aircraft

This is the thing to know before deciding. `quad_params.m` and
`doc/projektplan.md` do not disagree by accident — they are consistent with
**different builds**:

| Source | m [kg] | kT [N/(rad/s)²] | ω_hover | rotor | blade-pass (2 blades) | implies |
|---|---|---|---|---|---|---|
| `quad_params.m:2,8` | 1.20 | 5.0e-6 | 767.2 rad/s | **122.1 Hz** (7326 rpm) | 244 Hz | a small, fast prop (~5-6") |
| `projektplan.md:135` ("~83 Hz Hover-Grundton") + `:134` (~1.5 kg) | 1.50 | ~1.35e-5 | 522 rad/s | **83.1 Hz** (4985 rpm) | 166 Hz | a large, slow prop (~10") |

Both are internally consistent, and **both are live candidates** — two different
models and frames are still under discussion, with different take-off weights,
and nothing is fixed. `quad_params.m:1` labels its set *"Beispiel:
450er-Klasse"* — an example, not a decision. Neither figure is "the stale one";
they belong to different aircraft, and the frame/motor/propeller decision is
what collapses them into one.

⚠️ Separately stale and worth correcting whenever that file is next touched:
`quad_params.m:57`'s inline comment says `-> 990.5 rad/s`, which requires
`kT = 3.0e-6`. The file now has `5.0e-6`, so the correct value is **767.2**.
The `fprintf` on the next line prints the real number; only the comment lies.

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

**At 1014 Hz, Nyquist 507 Hz clears both candidate builds** — 244 Hz for the
small prop, 166 Hz for the large one, and 382 Hz even at full throttle
(`w_max = 1200 rad/s`, `quad_params.m:11`). That is why the firmware took the
sensor's full rate: it is the choice that survives being wrong about the
airframe.

---

## 4. When the propeller is chosen — the procedure

1. **Measure or look up `kT`** for the chosen prop/motor pair and put it in
   `quad_params.m:8`. Set the real `m` at `:2`. Fix the `:57` comment.
2. **Re-run the arithmetic:**
   ```
   w_hover    = sqrt(m*g/(4*kT))          [rad/s]
   f_rotor    = w_hover / (2*pi)          [Hz]
   f_blade    = n_blades * f_rotor        [Hz]   (n_blades = 2 or 3)
   f_blade_max= n_blades * w_max/(2*pi)   [Hz]   full-throttle worst case
   ```
3. **Check `f_blade_max` against Nyquist = 507 Hz.**
   - `f_blade_max < 507 Hz` → **nothing changes.** The firmware already
     samples fast enough. This is the expected outcome for any sane prop on
     this airframe; a 3-blade prop at `w_max` reaches 573 Hz, which is the
     first case that does not clear.
   - `f_blade_max ≥ 507 Hz` → the IMU ODR would have to rise above 1 kHz.
     That is a real firmware change: `INT_CONFIG1` must become `0x60` (8 µs
     pulse, de-assert disabled — required at ODR ≥ 4 kHz, see
     `AurixTricore/docs/ICM42688P.md` §8.2), and `NavTask_step`'s 300 µs
     budget must be re-costed against the shorter period.
4. **Nothing else in the firmware moves.** No gain retuning: the gains are
   continuous-time and `Ts` tracks the measured tick.

---

## 5. The frame resonance is the other half

`projektplan.md:135` also notes the frame's own resonance must not sit on the
hover fundamental. That is a mechanical constraint, not a sampling one, and it
is **not** covered by the rate argument above — a structural mode at the blade
frequency is excited regardless of how fast the IMU is read. The planned RPM
notch filter from the DShot speed feedback (`README.md`, *Actuation*) is the
mitigation; it needs the real prop and the real frame before it can be tuned.

---

## 6. What is still unmeasured

- **No phase margin exists anywhere in this repo.** `linearize/linearize_hover.m:13-16`
  runs `linmod` and prints eigenvalues only — no `margin()`, no saved state-space.
  The crossover figures used on the firmware side (yaw ω_c = Kp/I = 12 rad/s
  = 1.91 Hz) are re-derived from the gains and inertias, i.e. design intent, not
  a measured loop.
- **Blade count is assumed 2** throughout. Three blades raise every blade-pass
  figure by 50 %.
- **No file records why `Ts = 0.001` was chosen.** It is asserted at
  `quad_params.m:50` and repeated in `sil/`, `pil/`, `README.md` and
  `projektplan.md` — it is the sensor's rate, adopted, not a derived requirement.
  The control law itself needs only ~38 Hz (10-20x the 1.91 Hz crossover); the
  fastest pole in the modelled aircraft is the motor+ESC lag at **3.18 Hz**
  (`quad_params.m:10`, `tau = 0.05`).
