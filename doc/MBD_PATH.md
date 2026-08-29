# MBD Path — Sensor Models & State Estimator (Simulink)

**ASPICE:** SWE.2 — software architecture, MDL domain (Simulink estimator/sensor path); §3 is the SYS-IF-001 contract · realizes SYS-VER-001, SYS-IF-001/002 · process: QuadSE/requirements/README.md

> **Standalone work package.** This document is self-contained so it can be
> executed independently (e.g. in a parallel Claude Chat session) while the
> firmware strand proceeds on the AURIX TC399. It describes the **Simulink side**:
> adding realistic sensor models and a state estimator, closing the loop, and
> verifying against the existing SIL/PIL harness.
>
> The companion firmware plan (TC399 BSW drivers + estimator in C) lives in
> `AurixTricore/`. **Both strands implement the same estimator algorithm and must
> use identical conventions** (§7) so the Simulink model and the target C code can
> be compared bit-for-bit with the existing replay harness.

---

## 1. Context — what this project is

A 450-class quadcopter flight controller, built Model-Based-Design:

- **Plant** (Simulink, `models/`): `dynamik_6DoF.slx`, `kinematik.slx`,
  `kraefte_momente.slx`, `actuators.slx` — full 6-DoF rigid-body simulation.
- **Controller** (`quad_model_control.slx`): a 4-stage cascade —
  position (NED) → attitude → body-rate → mixer — running at **Ts = 1 ms (1 kHz)**.
  Also code-generated to C and verified on the TC399 (`sil/`, `pil/`).
- **Parameters**: `quad_params.m` (mass 1.20 kg, arm 0.225 m, X-config, etc.).

**Conventions (must match everywhere):**
- **NED** frame: z points *down*, altitude = −z.
- Attitude `phi = [roll, pitch, yaw] = [φ, θ, ψ]` in **rad**.
- Body rates `om = [p, q, r]` in **rad/s**.
- Body velocity `v_b = [u, v, w]` in **m/s** (used as a damping term; for small
  angles and ψ≈0 it approximates NED velocity — see `sil/flight_ctrl.h`).

## 2. The problem this work package solves

Today the controller is fed the **true plant states directly** — position,
velocity, attitude and rates come straight out of the 6-DoF model with no sensor
imperfection and no estimation. That is unrealistic: on real hardware the
controller only ever sees **noisy, biased, rate-limited sensor data**, fused by a
**state estimator**.

This package inserts that missing reality:

```
        ┌─────────┐   true states   ┌──────────────┐  measurements  ┌───────────────┐  x̂  ┌────────────┐
  ─────▶│  PLANT   │───────────────▶│ SENSOR MODELS │──────────────▶│ STATE ESTIMATOR│────▶│ CONTROLLER │──┐
        │ (6-DoF)  │                 │ (this package)│               │ (this package) │      │ (existing) │  │
        └─────────┘                 └──────────────┘               └───────────────┘      └────────────┘  │
             ▲                                                                                              │
             └──────────────────────────── motor commands w_cmd ───────────────────────────────────────────┘
```

Deliverables: (A) sensor models, (B) a complementary-filter estimator, (C) the
closed loop, (D) verification. Success = the loop stays stable with realistic
sensors, and the estimator matches the target C implementation under replay.

## 3. The estimator output contract (fixed — do not change)

The controller consumes a **16-element input vector** (`u`). Column order is
defined by `pil/replay_export.m` and consumed by `sil/CtrlReplay.c`:

| Cols | Field | Unit | Produced by |
|---|---|---|---|
| 1:3 | `p_ned_soll` | m | **guidance / setpoint** (not estimated) |
| 4:6 | `p_ned_ist` | m | **estimator** — GNSS position + baro altitude |
| 7:9 | `v_b_ist` | m/s | **estimator** — GNSS velocity (+ IMU) |
| 10 | `psi_soll` | rad | **guidance / setpoint** (not estimated) |
| 11:13 | `phi_ist` | rad | **estimator** — complementary filter |
| 14:16 | `om_ist` | rad/s | **estimator** — calibrated gyro (direct) |

The estimator fills cols **4:6, 7:9, 11:13, 14:16**. Setpoints (1:3, 10) stay as
today. The controller block and its C code are **frozen** — this package only
changes what feeds its inputs.

---

## 4. Part A — Sensor models

Add a `sensors` subsystem (suggest new `models/sensors.slx`, referenced from
`quad_model_control.slx`) that takes true plant states and outputs raw sensor
signals. Each sensor = **rotate/convert → scale/misalign → bias → noise →
quantize → rate-limit (ZOH at sensor ODR) → latency**. Model each at its own rate
using rate-transition blocks; the estimator resamples.

Parameters below are grounded in the datasheets in `doc/` (breakout guides) and
typical component values — put them in a new `sensor_params.m` and **flag any value
marked “≈” for confirmation against the manufacturer component datasheet**.

### 4.1 IMU — ICM-42688-P (gyro + accel), 1 kHz
Derive from plant body rates `om` and body specific force `a_b = R·(v̇_ned − g)`.
| Effect | Gyro | Accel |
|---|---|---|
| Full scale | ±2000 dps (±34.9 rad/s) | ±8 g |
| Noise density ≈ | 2.8 mdps/√Hz → σ≈0.0016 rad/s @1kHz | 70 µg/√Hz → σ≈0.022 m/s² @1kHz |
| Bias (turn-on) ≈ | ±0.5 … 1 °/s, slow random walk | ±20 … 40 mg |
| Scale/misalign ≈ | ±1 %, ±0.5° axis cross-coupling | ±1 %, ±0.5° |
| Quantization | 16-bit over full scale | 16-bit over full scale |
Model gyro bias as a slow random walk (drives the estimator’s bias-correction term).

### 4.2 Barometer — BMP581, 50 Hz
Derive pressure from true altitude (−z) via the barometric formula about a
sea-level reference `p0`.
- Relative accuracy **±0.4 Pa ≈ ±3.3 cm**; low-altitude noise ≈ **1 cm (0.08 Pa)**.
- Absolute accuracy **±30 Pa ≈ ±2.5 m** (slow bias — do **not** trust for absolute
  height; use for short-term vertical rate/relative altitude).
- Temperature ±0.5 °C (only if you model temp compensation).
- Add ZOH at 50 Hz + one-sample latency.

### 4.3 Magnetometer — MMC5983MA, 100 Hz
Derive from Earth field rotated into body frame `m_b = R·m_ned` (use a local
reference field: magnitude ≈ 48 µT, inclination/declination for your site).
- Resolution 0.4 mG, RMS noise ≈ **0.4 mG (0.063 µT)**, FSR ±8 G, 18-bit.
- **Hard-iron** offset (constant vector) + **soft-iron** (3×3) — the interesting
  part; model them so the estimator’s calibration is exercised.
- Heading accuracy ≈ 0.5°. ZOH at 100 Hz.

### 4.4 GNSS — u-blox NEO-M9N, 10 Hz (up to 25 Hz)
Derive from true NED position/velocity; convert position to lat/lon/height about a
captured origin (tangent plane), then add error and convert back in the estimator.
- Horizontal accuracy ≈ **1.5 m** (correlated, slowly varying — model as
  1st-order Gauss-Markov, not white).
- Velocity accuracy ≈ **0.05 m/s**; heading ≈ 0.3°.
- Update **10 Hz** default; **latency ≈ 100–200 ms** (important — model it).
- Provide a `fix_valid` flag; include a short **dropout** scenario to test coasting.

## 5. Part B — Complementary-filter estimator

New `StateEstimator` subsystem (MATLAB Function block or Simulink primitives — keep
it codegen-friendly and **structurally identical to the planned C `StateEstimator.c`**).

### 5.1 Attitude — Mahony complementary filter (gyro + accel + mag)
Runs at 1 kHz. Quaternion state `q` (or DCM), plus gyro-bias estimate `b`.
1. Predict: integrate `q` with bias-corrected gyro `ω − b`.
2. Accel correction: error `e_a = â_body × ĝ_body` (measured gravity dir × estimated).
3. Mag correction: tilt-compensate mag, compare heading to estimate → `e_m` about z.
4. Feedback: `ω_corr = ω − b + Kp·(e_a+e_m)`, `ḃ = −Ki·(e_a+e_m)`.
5. Output Euler `phi_ist` (cols 11:13). Pass calibrated gyro through as `om_ist`
   (cols 14:16). Start `Kp≈1.0, Ki≈0.05`; tune for settling vs. noise.
Reject accel correction when `|a| ≠ g` (high-acceleration gate).

### 5.2 Vertical — baro + GNSS + accel
Complementary/lead-lag fusion: baro (fast, relative) + GNSS height (slow, absolute)
+ integrated accel-z (very fast vertical rate). Output `p_ned_ist(z)` and vertical
velocity. Estimate baro bias slowly from GNSS height.

### 5.3 Horizontal — GNSS + IMU
- GNSS lat/lon → local NED about a captured origin → `p_ned_ist(x,y)` (cols 4:6).
- GNSS NED velocity, de-latated, rotated into body via `R(phi)` → `v_b_ist`
  (cols 7:9), matching the controller’s body-velocity damping convention.
- Between GNSS updates, propagate with accel (dead reckoning); correct on each fix.
- Coast on `fix_valid == 0`.

## 6. Part C — Closing the loop

1. Wire `plant → sensors → StateEstimator → controller` in a copy of
   `quad_model_control.slx` (e.g. `quad_model_control_hil.slx`) to preserve the
   existing open-loop verification model.
2. Feed setpoints (`p_ned_soll`, `psi_soll`) as before.
3. Confirm hover + step responses remain stable with sensors in the loop; expect
   slightly degraded performance vs. the ideal-state baseline — quantify it.
4. Reuse `quad_run.m` / `quad_params.m`; add `sensor_params.m`.

## 7. Part D — Verification (reuse the existing harness)

The controller is already verified by replaying Simulink input vectors to the
TC399 and comparing (`pil/run_pil.m`, `pil/replay_export.m`, `pil/replay_compare.m`,
`sil/`). Extend the **same pattern** to the estimator:

1. **SIL first**: build the estimator as an S-function / generated C (as done for
   the controller in `sil/`), run it in-model, confirm it matches the Simulink
   estimator.
2. **Extend the replay vector**: today `replay_export.m` exports the 16 controller
   inputs. Add a parallel export of the **raw sensor signals** (gyro/accel/mag/baro/
   GNSS) plus the Simulink estimator output as reference. Replay the raw sensors to
   the target estimator and compare its `x̂` to the Simulink reference — exactly the
   `replay_udp.m` round-trip used for the controller.
3. **Regression**: the existing controller replay (`run_pil()`) must still pass —
   the frozen controller path is unchanged.

**Convergence rule:** the C `StateEstimator.c` (firmware strand) and this Simulink
estimator are the *same filter*. Keep gains, state layout, update order, and the
NED/rad conventions of §1 identical, so the replay comparison is meaningful. When
the firmware team finalizes gains, mirror them here (and vice-versa) via a shared
constants list — ideally the same `sensor_params.m` values baked into both.

## 8. Suggested file layout (new)

```
Quadrocopter/
  models/sensors.slx              (A) sensor models subsystem
  models/StateEstimator.slx       (B) complementary filter (or MATLAB Function)
  quad_model_control_hil.slx      (C) closed loop with sensors + estimator
  sensor_params.m                 all sensor + estimator constants (shared w/ C)
  pil/replay_export_sensors.m     (D) export raw sensor vectors for estimator replay
```

## 9. Definition of done

- [ ] Sensor models produce datasheet-plausible signals at correct rates.
- [ ] Complementary filter recovers attitude/heading; vertical & horizontal fusion sane.
- [ ] Closed-loop sim (plant→sensors→estimator→controller) stable at hover + steps.
- [ ] Estimator SIL matches Simulink; PIL replay matches within tolerance.
- [ ] Existing controller PIL regression still green.
- [ ] `sensor_params.m` constants agreed with the firmware strand.
