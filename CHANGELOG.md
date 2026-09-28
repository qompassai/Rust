# Changelog — qompassai/Rust

## 2026-09-28 — License normalization to Apache 2.0

**Decision (per Matt's directive):** the project's license is now Apache
License 2.0 ONLY.

- **Removed** `LICENSE-AGPL` (GNU Affero General Public License v3) and
  `LICENSE-QCDA` (Qompass Commercial Distribution Agreement 1.0). The
  previous dual-license model (AGPL-3.0 for open use + Q-CDA commercial
  option) is retired for this repo. Rationale per Matt: a single
  permissive license (Apache 2.0) for all Qompass AI language projects.
- **Added** `LICENSE` — the complete, unmodified Apache License 2.0 text
  (https://www.apache.org/licenses/LICENSE-2.0.txt), appendix attributing
  `Copyright 2025 Qompass AI` (year kept from the repo's existing
  copyright headers).
- **README.md**: replaced the AGPL v3 + Q-CDA badges with an Apache 2.0
  badge; replaced the entire "Dual-License Notice" section (AGPL
  rationale, commercial-option rationale, cybersecurity references) with
  a concise `## License` section pointing at `./LICENSE`.
- **Metadata**: `.zenodo.json` and `CITATION.cff` license fields updated
  from `Q-CDA-1.0` to the SPDX identifier `Apache-2.0`.

**Validation:** `LICENSE` diffed against the canonical apache.org text
(only the appendix copyright line differs, as intended); `.zenodo.json`
and `CITATION.cff` parse cleanly; README renders with zero remaining
references to AGPL/Q-CDA/dual-license (verified by grep) and no dangling
links to the deleted license files.
**Exceptions:**
- `Qxet/` is a nested component tracked in this repo (no submodule). It
  was normalized as part of this change: its own `LICENSE-AGPL` /
  `LICENSE-QCDA` were replaced with an Apache 2.0 `LICENSE`, and its
  README badges, "Dual-License Notice" block, `CITATION.cff`, and
  `.zenodo.json` were updated identically to the repo root.
- `Qxet/docs/README.md` — upstream HuggingFace xet-core documentation
  carrying its own `Copyright 2024 The HuggingFace Team` Apache 2.0
  header. Left intact as third-party content.
- `Qxet/hf_xet/Cargo.toml` already declares `license = "Apache-2.0"`;
  no change needed.
- `deny.toml` license allow-lists govern third-party *dependency*
  licenses (cargo-deny); left as-is.

