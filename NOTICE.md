# Third-Party Notice

The [MIT license](LICENSE) covers all original work in this repository: the
Simulink models (`*.slx`), the MATLAB scripts (`*.m`), the controller C sources
under `sil/`, the tests and the documentation.

**No third-party source code is vendored here.** In particular:

- **MATLAB®, Simulink®, Embedded Coder®** and the MinGW-w64 compiler used by
  `mex` are **not** redistributed in this repository. They are licensed
  separately by their respective vendors and are required to open and run this
  project.

- **`sil/*.mexw64`** are compiled MEX binaries built by `sil/build_sfun.m` from
  the original C sources in the same directory. They are original work, contain
  no MathWorks code, and can be regenerated from source at any time.

- **`sil/flight_ctrl.c` / `.h`** are byte-identical to the controller sources in
  the [AurixTricore](https://github.com/crengineering/AurixTricore) firmware
  repository and are original work under the same MIT license. That is
  deliberate: the identical translation unit is what makes the SiL and PiL
  comparison meaningful.

- **`doc/*.html`** are original documents written for this project. They load
  webfonts from Google Fonts (Space Grotesk, IBM Plex Sans/Mono, Archivo — all
  under the SIL Open Font License) by reference; no font files are redistributed
  here. The documents were drafted with Claude Code from the model, the design
  decisions and the measured results of this project, then reviewed and
  corrected against the working model.

## Trademarks

MATLAB®, Simulink® and Embedded Coder® are registered trademarks of The
MathWorks, Inc. AURIX™ and TriCore™ are trademarks of Infineon Technologies AG.
Their use here is descriptive — to identify the tools and the target hardware
this project uses — and implies no affiliation with, sponsorship by, or
endorsement from The MathWorks, Inc. or Infineon Technologies AG.
