# Frame concept r02 — basebody, arms, mounts, legs, housing

**draft — gate 2 open.** Chain: SYS1-011 (frame) / SYS1-013 (legs) / SYS1-014
(housing) / SYS1-012 (mounts) → SYS2-MEC-008…013 → this note →
`dispatch/SYS1-011 — Dispatch.md`. Written 2026-09-03, `flight-mech`.
**Nothing built into `frame_r01`; nothing changed in `DrohneP1`** — both
opened read-only over the Fusion MCP, for reference only.

**Chris decides at gate 2:** the six recommendations below, the basebody
solid-vs-ribbed call, leg attachment/material, drop-height and
pocket-depth values, and whether the resulting mass (§9) and T/W margin
are acceptable or send the concept back.

**Design intent baseline** (Chris, 2026-09-03, superseding a plate-and-
bracket first draft): a solid printed PETG **basebody**, not a thin plate,
with pockets the 10×10 CFK tube arms slide into and are screwed in place;
TriBoard stack on top; battery + ESC hanging below in a separate tray;
arm-tip motor mounts are clamp blocks (reference: a Tarot-style carbon
quad frame photo Chris shared — sandwich tube-clamp centre, described,
not reproduced, vendor image); legs hang from those same tip blocks.
`DrohneP1` (Fusion, read 2026-09-03) is Chris's own earlier basebody
sketch, cited for footprint/thickness/pocket-depth only — its `EMAX_980KV`
motor and `Rotor_150mm` (Ø150 mm) prop placeholders predate the current
X2216/Ø254 mm decisions and are **not** sources here.

## 1. Layout

Bottom→top: foot → leg (CFK tube) → arm-tip clamp block (motor+prop) ↔ arm
(10×10 CFK tube) ↔ basebody pocket → basebody → standoff → breakout PCB →
Samtec → TriBoard (connectors underside) → sensors (open, top). Battery+ESC
hang from the basebody underside, inside the leg envelope.

```
TOP (basebody 242×162 mm, arms on the diagonals)

  (leg)\ [MOTOR]==254disc==\      /==254disc==[MOTOR] /(leg)
         \                  \    /                  /
          [==== BASEBODY, pockets at 45°, sensors open on top ====]
         /                  /    \                  \
  (leg)/ [MOTOR]==254disc==/      \==254disc==[MOTOR] \(leg)

  battery+ESC tray hangs BELOW basebody, centred (hidden here)

SIDE (one arm pair, height up)

  sensors (open) ┐
  TriBoard ───── ┤ board stack, ~40 mm assumed
  breakout/standoff ┘  (basebody top → TriBoard underside)
  ══ BASEBODY 35 mm ══   ← arm axis ≈ basebody mid-height
  battery+ESC tray, ~38 mm below basebody, housing skirt wraps it
  ── ground ── (~15 mm clearance under tray)
   |leg ~70 mm, same at every corner|
```

**CG (qualitative — real number needs the post-gate-2 Fusion mass read):**
battery (397 g, heaviest item) sits ~35–40 mm *below* the rotor plane, board
stack ~100–140 mm *above* it — battery mass dominates, so overall CG should
sit near/below the rotor plane. Tray recommended **centred** on the
basebody XY centroid (`DrohneP1`'s own off-centre placement is a sketch
artefact, not carried forward). **XT90-S** on the tray's power lead,
housing underside, reachable without opening anything (SYS1-005). Cable
exits: 4× motor leads at the arm pockets, tether on one side, XT-60 near
XT90-S.

## 2. MEC-008 — Motor mount (arm tip)

**Recommendation:** two-piece printed PETG **clamp block** around the
10×10 tube tip (split along the tube axis, 2–4 M3 clamp screws) + a flat
top plate carrying the motor bolt pattern: one axis fixed at **19 mm**
(assumed shared by both candidate 2216 patterns), the other a **16–19 mm
slot** (absorbs the pattern uncertainty — same semi-kinematic idea as the
TriBoard mount, `board_mount` in `params_r01.json`). Shaft clearance: a
**Ø5 mm through-hole**, not a blind pocket (protrusion below the motor
base is unpublished — a through-hole tolerates whatever is found on
arrival). ⚠ **Confirm the shared-19 mm axis when the real pattern is
measured**; if it differs on both axes, both need slots — a revision, not
a redesign. Clamp preload only resists axial slip — the square tube
already prevents rotation geometrically (unlike the round tube in the
reference photo, which needs clamp friction for both) — so preload stays
low, avoiding the 0.75 mm wall-crush risk commit `1cb5c6f` flagged.

**Alternatives:** bonded sleeve bracket (pre-photo first draft) — not
replaceable, dropped. Direct-mount plug in a wider tube — reopens tube
procurement and resonance for no gain, rejected.

**Mass** (volume × 1.25 g/cm³ PETG, estimate): clamp halves ~7.5 cm³ +
top plate ~3.6 cm³ + screws/inserts ⇒ **~18 g/mount, 72 g for four**.

**Resonance re-run** — `f₁ = (1/2π)·√(3EI/(L³·(M_tip+0.2357·m_arm)))`,
back-derived from the published 46 Hz/84.1 g result (10×10×0.75 mm tube):
`EI = 27.4 N·m² ⇒ E ≈ 68.9 GPa` (cross-checked against the same table's
round 12/10→53 Hz and 16/14→84 Hz rows, <1% error). `k = 3EI/L³ = 7224 N/m`,
`L = 225 mm` fixed.

| tip mass | M_tip | f₁ |
|---|---|---|
| motor+prop only | 79.1 g | 46.1 Hz |
| + mount (18 g) | 97.1 g | 42.9 Hz |
| **+ leg at tip (3.1 g) — this concept** | **~103 g** | **41.7 Hz** |

Comfortably below the 86 Hz 1P band; since the design sits *below* the band
("stiffer is worse," `1cb5c6f`), added tip mass moves the mode *further*
away — favourable, not a risk.

**Printability:** clamp halves + plate print flat, no supports, trivial
bed footprint.

## 3. MEC-009 — Arm-to-basebody joint

**Recommendation:** a **pocket in the basebody**, not a plate boss. Tube
slides into a **10.2×10.2 mm pocket, 30 mm deep** (mid-range of Chris's
20–40 mm; matches `DrohneP1`'s own cut depths, several exactly 20/30/35/40
mm), bored on the 45° diagonal. Retained by **2× M3 screws, transverse to
the tube axis**, through the basebody wall into a hole through the tube,
threaded into basebody heat-set inserts (not the tube wall) — a deliberate
in-plane load direction (see printability).

**Loads** (design load: single-motor max thrust 1000 gf = 9.81 N ×
L = 225 mm ⇒ **M = 2.21 N·m root moment**, matching Chris's own "2.2 Nm"
figure). Modelled as a reaction couple `P = M/L_pocket` bearing on the
pocket top/bottom walls (5 mm local contact × 10 mm tube face):

| pocket depth | P | bearing pressure |
|---|---|---|
| 20 mm | 110.4 N | 2.21 MPa |
| **30 mm (recommended)** | **73.6 N** | **1.47 MPa** |
| 40 mm | 55.2 N | 1.10 MPa |

All well under PETG X-Y reference strength (51 MPa tensile, 75 MPa
bending, used as a conservative proxy — no compressive figure published):
**bearing is not limiting at any depth in range**; depth is a mass call,
not a strength one, per Chris's instruction not to fight it.

**Screw pull-out:** generic M3 brass heat-set insert (~300 N at ~5 mm
engagement in PETG — **estimate, not project-sourced, confirm with the
chosen insert**) vs. a bounding 9.81 N axial load ⇒ >30× margin, not
limiting.

**Load direction / printability:** basebody prints **flat** (§8) —
vertical bearing reaction loads the pocket walls in **interlaminar
compression** (FDM's tolerant mode), and the transverse screws pull
in-plane (51 MPa), not through the weak Z axis (35 MPa) — both chosen
deliberately to avoid the datasheet's weak direction.

**Replacement:** unbolt the 2 screws, withdraw the tube — no basebody
damage, "crash consumable" per `einkaufsliste.md` §6a.

**Procurement:** `arm_length_l = 225 mm` (centre-to-motor,
frozen) is unchanged, but the physical tube segment must now be
**225 + 30 = 255 mm** to keep the same exposed length. A 1 m tube then
yields only **3** arms (765 mm), not 4 — **a second tube is needed
regardless of the leg-material choice** (§5); recommend 2× Lindinger tube
(`P: 9810632`, ~31 € total) — covers 4×255 mm arms + 4×70 mm legs + spare.

**Alternatives:** bonded pocket, no screws — not replaceable, rejected.
Root clamp collar like the tip — redundant with pocket bearing, rejected.

No resonance re-run needed — root-end mass sits near-zero modal
displacement in a cantilever mode, negligible effect on `f₁`.

## 4. MEC-010 — Battery bay (+ ESC)

**Recommendation:** printed PETG **tray/cage** bolted to the basebody
underside on 4 standoffs, cradling the 140×44×31 mm pack (centred on the
basebody centroid, unlike `DrohneP1`'s off-centre sketch) with the ESC
beside it — matches `DrohneP1`'s own under-plate pack+ESC placement.
Retention: 2× hook-and-loop straps through tray slots — fast swap, no
printed clamp stress.

**Alternatives:** battery on top — rejected, raises CG, blocks sensor
access. Split fore/aft — rejected, no benefit for one pack.

**Mass** (shell: perimeter × height × 2 mm wall, 1.25 g/cm³): pack+ESC
envelope ~170×44×31 mm ⇒ shell ~33 g + 4 standoffs ~8 g + straps ~5 g ⇒
**~45 g estimate**.

**Printability:** single part, trivial bed fit, prints upright open-top,
no supports.

## 5. MEC-012 — Legs

**Recommendation:** legs attach at the **arm-tip clamp block**, per
Chris's reference photo (max ground clearance for the hanging pack; leg
loads stay out of the basebody). **Trade-off:** crash load goes into the
motor mount/arm tip instead of the more robust basebody — accepted for
clearance and part-count; revisit if drop testing overstresses the block.

**Material: CFK tube (same 10×10 stock as the arms) — recommended**, not
printed, because §3 already forces a second tube purchase; that tube
covers 4×70 mm legs (12.4 g total, at the arm's 10.0 g/225 mm linear
rate) with material to spare, no extra procurement line. Alternative:
printed PETG tapered post (~20 g for four) — no CFK dependency but heavier
and mismatches the tube-is-the-consumable logic of §6a; fallback only.

**Leg length — 70 mm (estimate, Chris confirms):** `≥ basebody_thickness/2
(17.5) + battery_bay_depth (~38) + ground_margin (10) ≈ 65.5 mm` ⇒ 70 mm,
leaving ~15 mm clearance under the tray.

**Drop height — 0.5 m onto a hard floor (flight-mech proposal, Chris
confirms/changes).** SYS1-014 already owns the crash/tip-over-from-tether-
height case for electronics; SYS1-013's own acceptance reads as the more
frequent "dropped it carrying it" case — 0.5 m is a common hobby-airframe
benchmark for that.

**Crash consumable:** yes, bolted/pinned to the clamp block, swapped like
arms. **Mass:** 12.4 g (CFK, recommended) or ~20 g (printed, alternative).
**Printability (printed alt only):** lying down, same reasoning as the
arms (projektplan §7) — bends sideways on impact, so the load runs in the
strong X-Y plane, not the weak Z layer boundary.

## 6. MEC-011 — Board stack

Unchanged in principle, now anchored to the basebody top instead of a thin
plate: **basebody top → standoff (10 mm nylon M3, `einkaufsliste.md`
§2.2) → breakout PCB → Samtec → TriBoard (connectors underside) → sensors
(open, top)**, **40 mm total, estimate, Chris 2026-09-03**.

**What Chris measures to replace the 40 mm estimate:** (1) standoff
installed height, basebody top → breakout PCB underside; (2) breakout PCB
thickness (typically 1.6 mm, unconfirmed, not built); (3) Samtec connector
pair mated stack height (connector not yet chosen — breakout-PCB-owner
dependency, not owned here); (4) TriBoard thickness + underside connector
protrusion (so the breakout doesn't bottom out and Samtec fully mates);
(5) clearance above TriBoard for sensor boards + harness, so the
housing's open top is tall enough. No separate mass line beyond standoffs
(~4 g, folded into "joint hardware," §9) — breakout PCB/TriBoard masses
are already in the AUM table (§9).

## 7. MEC-013 — Housing

**Recommendation:** two-piece PETG shell — a lower **skirt** wrapping the
battery/ESC tray + basebody underside, an upper **collar** wrapping the
board-stack sides up to just below the sensors, open-topped. Encloses
battery, TriBoard, breakout PCB; sensors stay open. Cut-outs: XT90-S
(reachable, SYS1-005), 4× motor leads at the arm exits, Ethernet tether
gland, XT-60 charge lead. Passive vent slots over the ESC/battery zone —
no sealed pocket there, given the PETG 68–69 °C HDT/Tg limit; watch ESC
skin temperature on the first powered bench test before trusting it.

**Alternatives:** fully sealed enclosure — traps ESC heat, no
weatherization need; rejected. Corner posts + top shelf only — fails the
tip-over contact-damage acceptance; rejected.

**Mass** (shell: perimeter × height × 2 mm wall, 1.25 g/cm³): skirt
(242+162 mm perimeter × ~48 mm) ≈ 97 g; collar (~130×190 mm perimeter ×
~45 mm) ≈ 72 g ⇒ **~170 g estimate**.

**Printability:** both parts fit the bed individually, well under
256×256 mm; print standing on the largest open face, no supports for
vertical walls; vent bridges stay under the ~30 mm max bridge span.

## 8. Basebody — solid vs shelled/ribbed

**Recommendation: shelled/ribbed, not solid.** Footprint/thickness from
`DrohneP1` (Fusion, read 2026-09-03): **242×162×35 mm**, pocket depth
**30 mm** (§3) — a concept-stage volume estimate, no lightening pattern
or boss removal applied yet.

| variant | method | mass |
|---|---|---|
| solid | 242×162×35 mm × 1.25 g/cm³ | **1714 g** |
| **shelled/ribbed (recommended)** | 3 mm shell (surface × wall) + 15% gyroid interior, minus 4 pocket cavities | **~580 g** |

Even lightened, this is heavy vs. the old 400 g planning value — **reported
as the honest consequence, not fought down**, per Chris's instruction; §9
carries it into the AUM/T-W check.

**Print orientation — flat, pocket axis horizontal (recommended):**
footprint on the bed, 35 mm print height. Each 10 mm-square pocket bridges
~10 mm per layer, well under the ~30 mm max bridge, so **no supports** —
and this is what puts the §3 bearing/screw loads in their favourable
directions. Standing the basebody on edge to shorten the print was not
pursued — it flips those loads onto the weak Z-tensile/impact direction
for no real benefit. Single part, fits 256×256×260 mm with large margin
(SYS2-MEC-007 satisfied trivially).

## 9. Mass roll-up

| component | mass | method / status |
|---|---|---|
| Basebody (shelled/ribbed) | 580 g | volume × density, estimate (§8) |
| Arms, 4× CFK tube (255 mm cut) | 40 g | catalogue rate, decided |
| Motor mounts, 4× clamp+plate+hw | 72 g | volume × density, estimate (§2) |
| Arm-joint hardware, 4× (2 screws+2 inserts) | 10 g | estimate (§3) |
| Legs, 4× CFK tube, 70 mm | 12 g | catalogue rate, estimate (§5) |
| Battery + ESC tray | 45 g | shell volume × density, estimate (§4) |
| Housing (skirt + collar) | 170 g | shell volume × density, estimate (§7) |
| **Frame-side total (vs 400 g planning value: +530 g, 2.3×)** | **~930 g** | reported, not resolved here |

**AUM roll-up** (`params_r01.json` mass table; frame-side total above
replaces the old `frame_mass_planning_value` + `arm_mass_4x` placeholders):

| item | mass | source |
|---|---|---|
| TriBoard | 121 g | weighed 2026-08-29 |
| GNSS+IMU+Mag+Baro breakouts | 21 g | weighed 2026-08-29 |
| AURIX breakout PCB | 100–150 g | Chris's estimate, not built |
| Battery | 397 g | datasheet |
| Motors 4× | 270 g | datasheet |
| Propellers 4× | 46.4 g | datasheet |
| ESC | 15 g | datasheet |
| **Frame-side total (this concept)** | **930 g** | this document |
| **AUM excluding tether** | **≈ 1900–1950 g** | roll-up |

**T/W** (4×1000 gf = 4.0 kgf, SYS2-MEC-002): **1.90 kg → 2.10**, **1.93 kg
(mid) → 2.07**, **1.95 kg → 2.05**.

**Still ≥ 2.0, but the margin has collapsed** vs. the pre-basebody concept
(2.47–2.54 at 0 m tether, `dispatch/SYS1-012` §4). Airborne tether budget
before T/W = 2.0: `(2.0 − 1.93)/0.0215 ≈ 3.3 m` — down from ~17.6 m.
**Gate-2 flag, not a silent pass**: options are accept the reduced tether
margin, ask for a lighter basebody, or revisit thrust/prop sizing.

## 10. What Chris measures / decides at gate 2

1. Approve or redirect each of the 6 recommendations (§2–§7); basebody
   solid vs ribbed (§8, recommended: ribbed) or lighter still, if the
   930 g / 3.3 m tether margin (§9) isn't acceptable.
2. Pocket depth: confirm 30 mm or pick elsewhere in 20–40 mm — moves
   basebody mass and the tube-length/2nd-tube consequence (§3).
3. Leg attachment (tip clamp block, recommended, vs. basebody-mounted
   fallback) and leg material (CFK, recommended, vs. printed fallback).
4. Drop height: confirm 0.5 m or name another value.
5. Board-stack measurements (§6, 5 items) once hardware exists; motor bolt
   pattern + shaft protrusion on arrival (§2) — confirms or breaks the
   shared-19 mm-axis assumption.
6. Procurement (recommend only): 2nd Lindinger CFK tube (`P: 9810632`,
   ~15.49 €) — covers arms + legs + spare from 2 tubes.

## 11. Sources

- `dispatch/SYS1-011 — Dispatch.md` (gate 1 approved 2026-09-03)
- `requirements/SYS2/SYS2-MEC-008…013`, `-001`, `-003`, `-007`;
  `requirements/SYS1/SYS1-011`, `-013`, `-014`, `-005`
- `Quadrocopter/mech/params_r01.json` (gate 2, 2026-09-03), `mech/README.md`
- `procurement/datasheets/*.md`: motor-sunnysky-x2216-iii-v3-880kv,
  battery-wellpower-ultima-4s-4000, board-triboard-tc3x9-mechanical,
  esc-flywoo-goku-g55m, material-bambu-petg-basic
- `procurement/einkaufsliste.md` §2.2, §5, §6a
- Commit `1cb5c6f` (Euler-Bernoulli modal analysis, tube/section table)
- Fusion MCP, read-only, 2026-09-03: `frame_r01` (screenshot, confirms the
  dispatch's no-mount/no-leg/no-housing findings) and `DrohneP1` →
  `Aurix_Baseplate` (bounding box 242.46×162.46×35.02 mm; extrude-cut
  depths 20/20/40/40/35/35/30/30 mm; battery/ESC under the plate; 9 thread
  features), read via script, closed without saving. Its `EMAX_980KV` /
  `Rotor_150mm` placeholders predate the current motor/prop decisions and
  are **not** sources.
- Reference photo, Chris 2026-09-03 (Tarot-style carbon 4-arm frame,
  vendor photo, not reproduced): sandwich tube-clamp centre, tower on top,
  battery below, tip clamp-block motor mounts, legs from the tip blocks.
