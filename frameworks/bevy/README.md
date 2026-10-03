# Bevy Guides

Learning and migration guides for the [Bevy](https://bevy.org/) game engine (Rust).

## Guides

| Guide | Targets | Status |
|---|---|---|
| [bevy-0.19-competency-guide.md](./bevy-0.19-competency-guide.md) | Bevy 0.19, Rust stable, Arch Linux | Stable track. A competency-based course: Rust fundamentals → Bevy ECS → example archaeology → Breakout-style capstone. Advance by passing each phase's gate, not by time spent. |
| [bevy-0.20-rc2-migration.md](./bevy-0.20-rc2-migration.md) | Bevy 0.20.0-rc.2 | **Pre-release snapshot.** Impact map, subsystem-by-subsystem migration notes (BSN, ECS, WESL shaders, sprites, UI/text, pointer input, rendering, assets), and a migration workflow. Verify every item against the final 0.20 release notes before upgrading production code. |

## Recommended path

1. Work the 0.19 competency guide as the stable track.
2. Tag the capstone baseline before touching 0.20.
3. Use the RC2 migration guide as a post-capstone lab on a separate branch — do not merge into the main line until 0.20 final ships and the migration notes are re-verified.

## License

All guides in this directory are Apache-2.0, like the rest of this repository. See the [LICENSE](../../LICENSE).
