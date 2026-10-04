# Architectural Decisions — Rust

## Bevy guides location (2026-10-03)

**Decision**: Bevy guides live at `frameworks/bevy/` in qompassai/Rust,
NOT in lumen.

**Context**: Matt's call — framework guides belong with the language repo.

**Consequence**: Lumen references but does not host Bevy guides.

## License normalization (2026-09-28)

**Decision**: Apache-2.0 across qompassai language repos. `LICENSE` file
byte-identical to canonical text except filled copyright line; SPDX
`Apache-2.0` in metadata; README badge.
