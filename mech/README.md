# mech/ — mechanical design (frame, mounts)

**ASPICE:** MEE — mechanical design, quadrocopter frame · realizes SYS-MEC-001
(printability, board footprint, resonance — parent R-011) and SYS-MEC-007
(X2D build-volume fit, multi-part split, arm-printable-lying-down — parents
R-011, R-012) · process: QuadSE/requirements/README.md

SYS-MEC-002 (thrust/weight) no longer belongs here — narrowed 2026-08-30 to
the drive's own condition, owned by the R-012 dispatch. This directory feeds
it and SYS-MEC-003 a number (frame mass, from Fusion mass properties) but
realizes neither.

Owned by the `flight-mech` agent (Fusion via MCP) together with Chris, who
does the shape judgment in the Fusion GUI and owns the Bambu Lab X2D.

## The versioning rule

The **working copy lives in Autodesk Fusion's cloud** — git cannot hold it.
This directory holds the **approved snapshots**: on every gate-approved
revision, export

| File | What |
|---|---|
| `frame_rNN_<yyyymmdd>.step` | geometry of record |
| `frame_rNN_<yyyymmdd>.3mf` | print file for the X2D |
| `params_rNN.json` | every named user parameter: value, unit, **source** (datasheet / measurement / gate decision) |

`rNN` increments per approved revision; never overwrite an earlier
revision's files. The newest `params_rNN.json` is the dimensional SSoT —
a dimension that is not in it with a source does not exist.

## Standing constraints

See `QuadSE/architecture/SYS3_SYSARC.md` (E5), `QuadSE/requirements/SYS2_SYS.md`
(SYS-MEC-001/007) and `Quadrocopter/doc/projektplan.md` §7.

**Decided geometry (gate 1, R-012, approved 2026-08-30 — do not re-open here):**

- Frame class **F450**, arm length `l` = **225 mm** centre-to-motor
- Propeller **Ø 254 mm** (10×4,5″), 2 blades — HQProp MR1045
- Adjacent motor spacing `l·√2` = **318 mm** ⇒ **64 mm** prop tip gap
- Motor-to-nearest-board-corner 134,6 mm > 127 mm prop radius ⇒ disc never
  sweeps the board
- Board footprint **100×160 mm** (TriBoard TC3X9)
- Centre-plate standoff pattern: **4 mounting holes**, positions sourced
  from `AurixTricore/docs/infineon-tc3x9-usermanual-en.pdf` §7.4 "Layout
  with Dimensioning", **Figure 7-11** (PDF page index 53 — the figure is
  drawn **rotated 180°** on the page, and its dimension numbers are
  vector-outlined, not extractable text; read it, don't `pdftotext` it).
  The manual states this dimensioning **"should be used for development of
  extension boards"** and **"is valid for all TriBoards."**
  **⚠ The hole pattern is only PARTLY pinned down — do not treat it as
  fully settled.** Gate-2 final correction, 2026-08-30, after Chris
  measured the physical board (Geodreieck, ~±0,5 mm) as a third
  independent source:
  - **Length (Y) axis: CONFIRMED.** 3,581 / 129,261 / 127,167 mm along the
    160 mm length, unchanged from the previous draft. Measured lengths
    125,5 mm and 123,0 mm and a 2,5 mm far-side asymmetry all agree with
    these printed values within/near the ±0,5 mm measurement resolution —
    the drawing-derived Y positions are trustworthy.
  - **Width (X) axis: UNRESOLVED, ~84,7–85,0 mm span.** Three reading
    methods (printed dimension chain, vector-path extraction, hand
    measurement) each point at a different width, and the disagreement
    (0,84 mm on the chain reading used previously) **exceeds the ±0,5 mm
    measurement resolution** — this is a genuine unresolved disagreement,
    not measurement noise. Two candidate printed-chain readings exist
    (near-X = 7,298 mm → 85,536 mm span, vs near-X = 7,812 mm → 85,022 mm
    span, the latter matching Chris's measurement far better) and neither
    is asserted as correct. Full derivation and both candidates:
    `params_r01` draft (gate-2 report).
  - **Design response: a semi-kinematic four-point mount, not a fourth
    reading attempt.** Chris's decision — a 3D-printed plate needs
    clearance for shrinkage/warp regardless of the drawing ambiguity, so
    design around the ~0,8 mm rather than chase it: **one boss round
    Ø 3,4 mm (datum)**, **one boss slotted along the width axis** (slot
    sized to absorb ±0,5 mm), **two bosses oversized Ø 4,2–4,5 mm**. Which
    of the four hole positions plays which role is left open for the
    Fusion shape pass. **Do not "tighten" the three non-datum holes back
    to a snug round fit in a later revision** — that reintroduces the
    exact fight this scheme exists to avoid.
  - **⚠ NOT A RECTANGLE.** The near-side pair shares one Y (3,581 mm); the
    far-side pair does **not** — the drawing prints two different far-Y
    dimensions, 129,261 and 127,167 mm, a 2,094 mm difference. **Confirmed
    by Chris's hand measurement of the physical board** (2026-08-30,
    ~±0,5 mm resolution): a visible ~2 mm lengthwise offset between the
    two far holes. A centre plate sketched as a symmetric 4-boss rectangle
    (e.g. patterned/mirrored from 2 holes) leaves the board resting on
    only 3 of its 4 standoffs on the Y axis — an easy mistake to make from
    the board outline alone, a hard one to notice once printed. All four
    bosses must be placed at independently-specified Y positions.
  - **Hole diameter: design to Ø3,8 mm, not 4,0 mm.** The drawing's
    `4x4mm(157.48mil)` callout is the **drill** size (4,0 mm nominal);
    Chris measured the real board at **≈3,8 mm** finished — consistent
    with a plated-through hole finishing ~0,2 mm under its drill. **These
    are M3 holes** (an M4 screw will not pass a 3,8 mm hole) — confirms
    `procurement/einkaufsliste.md` §2.2's M3 nylon standoffs, until now
    correct only by assumption. Boss ID clearance must be sized against
    3,8 mm (the datum boss above; the slotted/oversized bosses use the
    dedicated dimensions listed there instead).
  - Hand measurement is a third, independent source (~±0,5 mm resolution,
    e.g. Geodreieck) — authoritative for "the Y-side offset is real", "the
    hole is under 4 mm, hence M3", **and** "the X-axis printed-chain
    reading is itself ambiguous"; it never overrides an unambiguous
    printed dimension, and on X there isn't one. Full source hierarchy:
    `params_r01` draft.
- **The AURIX breakout PCB** (buy list §2.2 — the 2×-Samtec-connector board
  carrying the sensor breakouts) is itself an "extension board" in exactly
  the sense §7.4 means: it mounts on the TriBoard over those connectors, so
  **Figure 7-11 is its mechanical datum too**, not just the centre plate's.
  Whoever lays that PCB out should start from the same figure — recorded
  here since this is the findable home for TriBoard mechanical facts on the
  mechanical side; the PCB itself is not this directory's design.
- Bambu Lab X2D build volume **256×256×260 mm** ⇒ frame is necessarily
  **centre plate + 4 separate arms** (450 mm diagonal does not fit in one
  piece); a 225 mm arm printed lying down leaves **31 mm** of bed margin —
  printable, but with almost no rotational freedom left over (see gate-2
  report, `params_r01` proposal)

**Still open, not this directory's call:**

- **Material** (SYS-MEC-001) — PETG favoured (60 °C glass transition beats
  PLA), CFK-tube arm + printed centre hybrid an option; Chris decides.
  Drives frame mass, stiffness, and where resonance sits relative to the
  ~83–91 Hz hover fundamental.
- Frame mass **~400 g planning value** (`projektplan` §7) — the single
  largest unsourced number in the AUM budget (see `dispatch/R-012.md` §4).
  Replaced by a real number once material + wall/plate thickness are fixed
  and Fusion's mass properties are read over the MCP.
- Plate thickness, arm wall thickness — depend on the material decision above.

Empty until the first **approved frame design revision** — gate 1
(component selection, R-012) passed 2026-08-30; gate 2 (this directory's
design) is what populates it.
