# Patterns — Rust

## Repo hygiene

- Seed zero-commit repos via Contents API PUT (blob endpoint 409s).
- Remove `__pycache__` before `git add -A` (py_compile artifacts).
- `push_via_api.py` cannot push repos with no local parent commit.

## Tiger Style Rust

Skill: `~/workspace/skills/tiger-style-rust/SKILL.md` (+
`references/TIGER_STYLE_RUST.md`). Applies to all Rust work in this repo.

## Repomap (codebase map for agents)

One-shot generation (no flake wiring in this repo):

```
nix run github:qompassai/nix?dir=repomap -- /path/to/repo --budget 15000 --out .repomap.txt
```

`.repomap.txt` is a derived artifact — gitignore it, never commit it.
For automatic regeneration on `nix develop`, wire the flake input per
github.com/qompassai/nix/tree/main/repomap/README.md.
