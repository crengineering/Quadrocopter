# mech/ — mechanical design (frame, mounts)

**ASPICE:** MEE — mechanical design, quadrocopter frame · realizes SYS-MEC-001/002 (parents R-011, R-012) · process: QuadSE/requirements/README.md

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

See `QuadSE/architecture/SYS3_SYSARC.md` (E5) and
`Quadrocopter/doc/projektplan.md` §7: X2D-printable, board footprint
100×160 mm, frame ~400 g planning value, resonance off the hover
fundamental, arms print lying down, material open (PETG favoured; CFK-tube
hybrid an option).

Empty until the first approved revision — expected after the R-011/R-012
component gate.
