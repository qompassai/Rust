# Rust and Bevy 0.19: Competency-Based Learning Guide

A step-by-step, test-driven path from Rust fundamentals to a finished 2D Bevy game. This edition targets **Bevy 0.19**, **Rust stable**, and **Arch Linux**. Last reviewed October 2026.

> Advancement rule: do not move to the next phase because time passed. Move on only when its checklist, exercises, automated checks, and explanation gate pass.

## Purpose and target

This guide turns a "Rust fundamentals → Bevy mental model → examples → small game → ecosystem" outline into a competency-based course. It assumes an Arch Linux development machine with Neovim or another LSP-capable editor.

The capstone is a small 2D Breakout-style game. Advance by passing each gate rather than by spending a fixed number of days: every phase has reading, hands-on work, a checklist, automated checks, and an explanation exercise.

## Official references

### Rust

- [Install Rust](https://rust-lang.org/tools/install/)
- [The Rust Programming Language](https://doc.rust-lang.org/stable/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Rustlings](https://github.com/rust-lang/rustlings)
- [The rustup Book](https://rust-lang.github.io/rustup/)
- [Cargo Book](https://doc.rust-lang.org/cargo/)
- [Cargo command reference](https://doc.rust-lang.org/cargo/commands/)
- [Clippy documentation](https://doc.rust-lang.org/clippy/)
- [rustfmt](https://github.com/rust-lang/rustfmt)

### Bevy

- [Bevy Learn](https://bevy.org/learn/)
- [Bevy Quick Start](https://bevy.org/learn/quick-start/getting-started/)
- [Bevy API documentation](https://docs.rs/bevy/0.19.0/bevy/)
- [Official examples](https://bevy.org/examples/)
- [Bevy 0.19 release notes](https://bevy.org/news/bevy-0-19/)
- [Migration guides](https://bevy.org/learn/migration-guides/)
- [Current Bevy errors](https://bevy.org/learn/errors/)
- [Bevy Assets and plugins](https://bevy.org/assets/)
- [Bevy GitHub repository](https://github.com/bevyengine/bevy)

## Ground rules

- Keep `Cargo.lock` committed for the game application.
- Use stable Rust unless a specific experiment requires nightly. Bevy's minimum supported Rust version is the latest stable release.
- Use Bevy 0.19 documentation and examples consistently. Bevy releases can contain breaking changes, so mixing tutorial versions is a common source of false problems.
- Prefer pure Rust functions for game rules and thin Bevy systems for ECS access. Pure functions are easier to test.
- Add third-party plugins only after implementing the relevant feature once with core Bevy.
- Do not advance merely because code compiles. Advance when the checklist, tests, and verbal explanation all pass.

## Mastery method

A concept is solid only when all four tests pass:

1. **Recognition:** identify it in unfamiliar code.
2. **Recall:** implement a small example without copying.
3. **Diagnosis:** fix a deliberately broken example and explain the compiler or Bevy error.
4. **Transfer:** use it in the capstone without restructuring unrelated code.

Maintain a `LEARNING_LOG.md` with one entry per exercise:

```markdown
## YYYY-MM-DD — Topic
- Built:
- Failure encountered:
- Root cause:
- Fix:
- Rule learned:
- Can reproduce without notes: yes/no
```

---

## Phase 0 — Arch and Rust setup

### Install native packages

```bash
sudo pacman -Syu
sudo pacman -S --needed \
  base-devel clang lld mold pkgconf \
  libx11 alsa-lib libxcursor libxrandr libxi

# Select the package matching your sound server:
sudo pacman -S --needed pipewire-alsa
# or:
# sudo pacman -S --needed pulseaudio-alsa
```

Install the Vulkan driver matching the actual GPU if one is not installed:

```bash
# AMD
sudo pacman -S --needed vulkan-radeon

# Intel
sudo pacman -S --needed vulkan-intel

# Other Mesa-supported hardware, where appropriate
sudo pacman -S --needed mesa-vulkan-drivers
```

Reference: [Bevy Linux dependencies](https://github.com/bevyengine/bevy/blob/latest/docs/linux_dependencies.md).

### Install Rust with rustup

Use the official installer rather than Arch's `rust` package when per-project toolchain control through rustup is desired:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"

rustup default stable
rustup update stable
rustup component add rustfmt clippy rust-analyzer rust-src
```

### Validate the toolchain

```bash
rustc --version
cargo --version
rustup show active-toolchain
rustup component list --installed
rust-analyzer --version
cargo fmt --version
cargo clippy --version
clang --version
ld.lld --version
vulkaninfo --summary
```

Create a toolchain smoke test:

```bash
mkdir -p ~/src/learning
cd ~/src/learning
cargo new rust-smoke
cd rust-smoke
cargo run
cargo fmt --all -- --check
cargo check --all-targets
cargo clippy --all-targets -- -D warnings
cargo test --all-targets
```

`cargo check` type-checks a package without final code generation and is normally faster than a full build; `cargo test` compiles and runs unit, integration, and documentation tests.

### Setup gate

- [ ] All Rust commands resolve from the shell.
- [ ] The active toolchain is stable.
- [ ] `cargo run` prints `Hello, world!`.
- [ ] fmt, check, Clippy, and test exit successfully.
- [ ] `vulkaninfo --summary` detects the intended GPU.
- [ ] Neovim attaches rust-analyzer and shows diagnostics for an intentional type error.
- [ ] Explain the roles of rustup, rustc, Cargo, rust-analyzer, rustfmt, and Clippy without notes.

### Common setup failures

- `cargo: command not found`: source `~/.cargo/env` and ensure `~/.cargo/bin` is on `PATH`.
- `alsa-sys` failure: verify `pkgconf --modversion alsa`, then install `alsa-lib` and the appropriate sound-server ALSA package.
- GPU/adapter failure: run `vulkaninfo --summary` and install/update the correct Vulkan driver.
- Linker unavailable: verify `clang --version` and `ld.lld --version`; remove custom linker configuration until the default build works.

---
## Phase 1 — Rust foundations

Use the Rust Book for explanation and Rustlings for repetition:

```bash
cargo install rustlings --locked
rustlings init
cd rustlings
rustlings
```

Rustlings is designed to accompany the Rust Book and provides short exercises for reading compiler diagnostics and writing Rust.

### Ownership and borrowing

Read:

- [Understanding Ownership](https://doc.rust-lang.org/book/ch04-00-understanding-ownership.html)
- [References and Borrowing](https://doc.rust-lang.org/book/ch04-02-references-and-borrowing.html)

Rust permits either one mutable reference or any number of immutable references to the same value at a time, and references must remain valid. These rules directly explain many ECS query conflicts later.

Exercises:

1. Implement `word_count(text: &str) -> usize` without allocating.
2. Implement `normalize_names(names: &mut [String])` that trims and lowercases each value in place.
3. Trigger E0382 by using a moved `String`; repair it three ways — borrow, clone, and redesign ownership. Explain which repair is best and why.
4. Return a borrowed slice from a function and explain why its lifetime is tied to the input.
5. Trigger E0502 with overlapping mutable and immutable borrows; shorten one borrow's scope to fix it.
6. Complete the Rustlings ownership, move-semantics, and borrowing exercises.

Suggested tests:

```rust
fn word_count(text: &str) -> usize {
    text.split_whitespace().count()
}

fn normalize_names(names: &mut [String]) {
    for name in names {
        *name = name.trim().to_lowercase();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn counts_words_without_changing_input() {
        let input = String::from("rust  and bevy");
        assert_eq!(word_count(&input), 3);
        assert_eq!(input, "rust  and bevy");
    }

    #[test]
    fn normalizes_in_place() {
        let mut names = vec!["  Player ".to_owned(), "ENEMY".to_owned()];
        normalize_names(&mut names);
        assert_eq!(names, ["player", "enemy"]);
    }
}
```

Gate:

- [ ] Predict whether a function call moves, immutably borrows, or mutably borrows each argument.
- [ ] Explain why `String` usually moves while integers usually copy.
- [ ] Fix E0382 and E0502 without reflexively adding `.clone()`.
- [ ] Explain why two simultaneous mutable references are prohibited.
- [ ] All tests and quality checks pass.

### Structs, enums, and matching

Read:

- [Structs](https://doc.rust-lang.org/book/ch05-00-structs.html)
- [Enums and Pattern Matching](https://doc.rust-lang.org/book/ch06-00-enums.html)

Enums encode a closed set of alternatives, while `Option<T>` forces callers to handle the presence or absence of a value.

Exercises:

1. Define `Position`, `Velocity`, `Health`, and `ActorKind` types.
2. Define `GameMode::{Menu, Playing, Paused, GameOver { score: u32 }}`.
3. Write an exhaustive `match` returning an on-screen label for every state.
4. Add a new enum variant and use compiler failures to locate every incomplete match.
5. Model optional power-ups with `Option<PowerUp>`, not sentinel values.
6. Define `Score(u32)` and `Lives(u8)` newtypes to prevent accidental mixing.

Gate:

- [ ] No wildcard arm is used merely to silence a meaningful exhaustive match.
- [ ] Newtypes distinguish semantically different values.
- [ ] Tests cover every enum variant and both `Some` and `None` paths.
- [ ] Explain when a field belongs in a struct versus a separate ECS component.
- [ ] Explain how newtypes create semantic type safety.

### Traits and generics

Read:

- [Generic Data Types](https://doc.rust-lang.org/book/ch10-01-syntax.html)
- [Defining Shared Behavior with Traits](https://doc.rust-lang.org/book/ch10-02-traits.html)

Traits define shared behavior, and trait bounds let generic code require that behavior at compile time. This matters because Bevy APIs rely extensively on derived traits such as `Component`, `Resource`, `States`, and `Plugin`.

Exercises:

1. Define a `Damageable` trait and implement it for two unrelated structs.
2. Write a generic `clamp_stat<T>` with only the bounds it needs.
3. Compare a generic function with `&dyn Damageable`; explain static versus dynamic dispatch.
4. Create a custom derive-heavy data type using `Debug`, `Clone`, `Copy`, `PartialEq`, and `Default`; justify each derive.
5. Remove one required trait bound, read the compiler error it produces, then restore it.

Gate:

- [ ] Read a generic signature such as `Query<(&mut Transform, &Velocity), With<Player>>` from the outside inward.
- [ ] Explain derive macros versus traits.
- [ ] Add only necessary bounds.
- [ ] Explain monomorphization at a high level.
- [ ] Tests pass for at least two concrete implementations.

### Closures and iterators

Read:

- [Closures](https://doc.rust-lang.org/book/ch13-01-closures.html)
- [Iterators](https://doc.rust-lang.org/book/ch13-02-iterators.html)

Closures can capture by immutable borrow, mutable borrow, or ownership, while Rust iterators are lazy until consumed.

Exercises:

1. Transform a loop into `filter`, `map`, and `collect`.
2. Demonstrate `iter`, `iter_mut`, and `into_iter`; state what each yields and whether the source collection remains usable.
3. Write `living_enemy_ids` from a collection of actors using iterator adaptors.
4. Use a `move` closure and explain what it captures.
5. Write one closure accepted by `Fn`, one requiring `FnMut`, and one requiring `FnOnce`.
6. Implement a tiny custom iterator with `next`.

Gate:

- [ ] Predict whether the source collection remains usable after iteration.
- [ ] Explain why iterator adaptors do nothing until consumed.
- [ ] Avoid unnecessary intermediate `Vec` allocations.
- [ ] Explain closure capture by shared borrow, mutable borrow, and move.

### Errors, modules, and tests

Read:

- [Recoverable Errors with Result](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html)
- [Packages, Crates, and Modules](https://doc.rust-lang.org/book/ch07-00-managing-growing-projects-with-packages-crates-and-modules.html)
- [How to Write Tests](https://doc.rust-lang.org/book/ch11-01-writing-tests.html)
- [Cargo tests](https://doc.rust-lang.org/cargo/guide/tests.html)

Use `Result` for expected failure and reserve panics for violated invariants or prototypes/tests where immediate failure is appropriate. Rust tests normally arrange state, execute behavior, and assert the result; Cargo discovers unit tests in source files and integration tests under `tests/`.

Exercises:

1. Parse a text level into `Result<Level, LevelError>`.
2. Split it into `src/level.rs`, expose only the necessary API, and test malformed input and boundary values.
3. Add a documentation example and confirm `cargo test --doc` executes it.
4. Add one integration test under `tests/`.
5. Replace one unjustified `unwrap()` with `?` and meaningful error context.

### Rust foundation gate

Build a deterministic command-line simulation with position, velocity, health, game states, and turns. It must contain no Bevy dependency.

```bash
cargo fmt --all -- --check
cargo check --all-targets
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
cargo test --doc
cargo doc --no-deps
```

Do not advance until:

- [ ] All commands succeed.
- [ ] At least ten meaningful tests cover normal, boundary, and error cases.
- [ ] No unexplained `clone`, `unwrap`, broad wildcard match, or lint suppression remains.
- [ ] A fresh `cargo clean && cargo test` succeeds.
- [ ] The ownership model of every main data structure can be explained.

---
## Phase 2 — Bevy environment

### Create and pin the project

The official Bevy quick start creates a normal Cargo binary and adds Bevy as a dependency; the 0.19 guide uses Rust edition 2024 and `bevy = "0.19"`.

```bash
cd ~/src/learning
cargo new bevy-lab
cd bevy-lab
cargo add bevy@0.19
```

For a tutorial project, preserve `Cargo.lock`. If exact reproducibility across machines matters, use `bevy = "=0.19.0"`; otherwise `bevy = "0.19"` permits compatible patch updates. Do not mix Bevy 0.19 dependencies with code copied from another version without consulting the matching migration guide.

Add the official development profiles to `Cargo.toml`:

```toml
[profile.dev]
opt-level = 1

[profile.dev.package."*"]
opt-level = 3
```

The official setup warns that unoptimized dependency code can make debug Bevy applications run poorly and recommends these split optimization levels.

### Configure a faster linker

Create `.cargo/config.toml`:

```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=lld"]
```

Bevy's setup guide recommends LLD as a faster alternative linker and provides this Linux configuration; it also documents Mold as an optional, sometimes faster alternative.

Validate:

```bash
cargo check
cargo build --timings
cargo run
```

If iterative links remain slow, test Mold by changing only the rustflags line:

```toml
rustflags = ["-C", "link-arg=-fuse-ld=/usr/bin/mold"]
```

Do not enable nightly, Cranelift, generic sharing, and dynamic linking simultaneously while learning. Establish a correct stable baseline, then benchmark one change at a time. Dynamic linking can reduce iterative link time, but the official guide advises disabling it for shipped builds.

### Minimal app

Replace `src/main.rs` with:

```rust
use bevy::prelude::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .run();
}

fn setup(mut commands: Commands) {
    commands.spawn(Camera2d);
}
```

Run:

```bash
cargo run
```

Expected result: a window opens without a panic and closes normally. A Bevy `App` contains a `World` and orchestrates systems, resources, and plugins.

### Run official examples

Use release-tagged source instead of `main`:

```bash
cd ~/src/learning
git clone https://github.com/bevyengine/bevy.git bevy-engine
cd bevy-engine
git checkout v0.19.0
cargo run --example breakout
cargo run --example sprite
cargo run --example move_sprite
```

The official guide explicitly recommends checking out `latest` or a specific release tag before running examples because the repository's default branch is development code.

### Environment gate

- [ ] The empty camera app opens and closes.
- [ ] `breakout`, `sprite`, and `move_sprite` run from the v0.19.0 tag.
- [ ] The application rebuilds after a one-line change.
- [ ] `cargo tree -i bevy` shows the expected version; `cargo tree -d` is inspected for duplicate versions.
- [ ] `cargo fmt`, `cargo check`, Clippy, and tests pass.
- [ ] Explain why `DefaultPlugins` creates a window while `App::new()` alone does not.

---

## Phase 3 — ECS mastery

Bevy ECS models unique entity identifiers carrying component data, processed by systems. Systems are ordinary Rust functions, and their parameter types tell Bevy what world data they access and which systems may safely run in parallel.

### Lab 1: Entities and components

Build a headless ECS lab first:

```rust
use bevy::prelude::*;

#[derive(Component, Debug, PartialEq)]
struct Position(Vec2);

#[derive(Component, Debug, PartialEq)]
struct Velocity(Vec2);

fn movement(mut movers: Query<(&mut Position, &Velocity)>) {
    for (mut position, velocity) in &mut movers {
        position.0 += velocity.0;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn movement_updates_matching_entities() {
        let mut app = App::new();
        app.add_systems(Update, movement);
        let entity = app
            .world_mut()
            .spawn((Position(Vec2::ZERO), Velocity(Vec2::new(2.0, -1.0))))
            .id();

        app.update();

        assert_eq!(
            app.world().entity(entity).get::<Position>(),
            Some(&Position(Vec2::new(2.0, -1.0)))
        );
    }
}
```

`App::update()` runs the default schedules once, making it useful for deterministic system tests without launching the normal event loop.

Exercises:

1. Spawn ten entities, only six with `Velocity`; prove only six move.
2. Add marker components `Player` and `Enemy`.
3. Filter with `With<Player>` and `Without<Dead>`.
4. Despawn dead entities through `Commands`.
5. Add a test proving unrelated entities remain unchanged.

Gate:

- [ ] Define entity, component, bundle/tuple, system, query, and world accurately.
- [ ] Explain why an entity is an ID rather than an object.
- [ ] Predict which archetypes a query can match.
- [ ] Tests verify positive and negative query matches.

### Lab 2: Resources and system parameters

Resources represent unique, global-by-type data and are accessed through `Res<T>` or `ResMut<T>`.

Exercises:

1. Create `Score(u32)`, `RoundTimer(Timer)`, and `GameConfig` resources.
2. Write one read-only system and one mutation system.
3. Intentionally request both `Res<T>` and `ResMut<T>` in the same system, observe B0002, then remove the redundant immutable access.
4. Test score changes through `app.update()`.

Gate:

- [ ] Use a component for per-entity state and a resource for genuinely unique state.
- [ ] Explain why `ResMut<T>` already permits reads.
- [ ] No "manager" singleton entity is used merely to emulate a resource.

### Lab 3: Commands and deferred changes

`Commands` queues structural world changes such as spawning, despawning, and inserting components; queued commands are applied when deferred operations run.

Exercises:

1. Spawn an entity in one system and query it in a later ordered system.
2. Demonstrate that un-ordered expectations can fail because the command has not yet been applied.
3. Fix the behavior with explicit ordering or by separating work across frames.
4. Write a test that calls `app.update()` the required number of times and documents why.

Gate:

- [ ] Explain deferred versus immediate world mutation.
- [ ] Never add `.chain()` blindly; state the dependency it enforces.
- [ ] Verify entity counts before and after deferred commands.

### Lab 4: Scheduling and ordering

Systems may run in parallel when accesses do not conflict; ordering must be explicit when behavior depends on it. The official introductory ECS tutorial uses `.chain()` when one system must update data before another reads it.

Exercises:

1. Implement `read_input → apply_velocity → resolve_collisions → update_ui`.
2. Create `SystemSet` labels for input, simulation, and presentation.
3. Move simulation to `FixedUpdate`; leave visual/UI work in `Update`.
4. Remove ordering, reproduce a wrong result, and restore the minimal dependency.

Gate:

- [ ] Distinguish schedule membership from execution order.
- [ ] Explain `Startup`, `Update`, `FixedUpdate`, `OnEnter`, and `OnExit`.
- [ ] No ordering constraints exist without a real data or semantic dependency.

### Lab 5: Messages, observers, and states

Build three states: `Menu`, `Playing`, and `GameOver`. The official game-menu example uses `States`, `OnEnter`, state-scoped update systems, and `NextState` to manage transitions.

Exercises:

1. Spawn state-specific UI in `OnEnter` and clean it in `OnExit`.
2. Run movement only while `Playing`.
3. Trigger a collision notification and update score separately from collision detection.
4. Add a restart transition from `GameOver`.
5. Test every legal state transition and verify gameplay systems do not run in `Menu`.

Gate:

- [ ] State-specific entities do not leak across transitions.
- [ ] Producers do not directly own every reaction to an event.
- [ ] Illegal transitions are impossible or explicitly ignored.
- [ ] State transition tests pass headlessly.

### Lab 6: Plugins

A Bevy plugin is a reusable collection of code that modifies an `App`; engine functionality itself is organized this way.

Refactor without changing behavior:

```text
src/
├── main.rs
├── game.rs
├── player.rs
├── ball.rs
├── collision.rs
└── ui.rs
```

Each feature module exposes one plugin. `main.rs` should construct the app and add plugins, not contain game rules.

Gate:

- [ ] Each plugin has a narrow purpose and owns its registrations.
- [ ] Feature modules do not reach through unrelated module internals.
- [ ] At least one plugin has a headless integration test.
- [ ] Refactoring changes structure only; pre-existing tests remain green.

---
## Phase 4 — Example archaeology

Do not copy whole examples. For each official example, use this loop:

1. Run it unchanged.
2. Predict which systems and components are responsible for one visible behavior.
3. Change one constant.
4. Change one data model element.
5. Add one testable behavior.
6. Rebuild the same behavior in the lab project without looking.
7. Compare and write the difference in `LEARNING_LOG.md`.

Recommended sequence:

| Example | Learn | Required modification | Validation |
|---|---|---|---|
| [`sprite`](https://bevy.org/examples/2d-rendering/sprite/) | Camera, asset loading, sprite spawn | Spawn two independently tagged sprites | Query exactly one of each marker |
| [`move_sprite`](https://bevy.org/examples/2d-rendering/move-sprite/) | Time-scaled movement | Add vertical motion and configurable bounds | Test direction reversal as pure logic |
| [`sprite_sheet`](https://bevy.org/examples/2d-rendering/sprite-sheet/) | Atlas and timer animation | Add idle/run rates | Test frame-index wraparound |
| [`spatial_audio_2d`](https://bevy.org/examples/audio/spatial-audio-2d/) | Audio source/listener | Toggle one-shot versus looping sound | Manual auditory check plus state test |
| [`game_menu`](https://bevy.org/examples/games/game-menu/) | States and UI | Add pause and resume | Test state transitions |
| [`breakout`](https://bevy.org/examples/games/breakout/) | Integrated game loop | Change one rule without breaking scoring | Regression tests and manual playthrough |

The official Breakout example integrates startup setup, ordered simulation systems, score resources, collision handling, UI, and collision sound, making it an appropriate final example before the capstone.

---

## Phase 5 — Capstone game

Build the game in vertical slices. Every milestone must be playable, committed, and green before adding the next.

### Milestone 1: Window and arena

- Spawn a 2D camera.
- Draw paddle, ball, walls, and bricks with simple colored primitives; use no external art yet.
- Tag each gameplay role with a marker component.

Validation:

- [ ] Exactly one camera, paddle, and ball exist.
- [ ] Wall and brick counts match constants.
- [ ] Window opens with no warnings or panic.
- [ ] A headless setup test queries expected entity counts.

### Milestone 2: Paddle input

- Read left/right input.
- Convert input to intent or velocity.
- Apply movement using `Time::delta_secs()`.
- Clamp the paddle inside the arena.

Validation:

- [ ] Holding left/right produces frame-rate-independent movement.
- [ ] Opposing inputs cancel predictably.
- [ ] Boundary clamping is a pure function with tests for left, middle, and right positions.
- [ ] No input code directly updates score or collision state.

### Milestone 3: Ball simulation

- Store velocity as a component.
- Apply velocity in `FixedUpdate`.
- Reflect against arena walls.
- Reset when the ball crosses the loss boundary.

Validation:

- [ ] Axis reflection tests cover all four normals.
- [ ] Position updates are deterministic for a fixed timestep.
- [ ] A reset restores both position and velocity.
- [ ] The ball cannot remain embedded in a wall after repeated updates.

### Milestone 4: Collision and bricks

- Separate overlap detection from collision response.
- Despawn hit bricks through `Commands`.
- Emit a collision notification.
- Increment score in a separate reaction system.

Validation:

- [ ] Hitting one brick removes exactly one brick.
- [ ] A miss removes none.
- [ ] One collision increments score once.
- [ ] Collision direction is tested at edges and corners.
- [ ] Deferred despawn behavior is explicitly covered by an integration test.

### Milestone 5: States and UI

- Add `Menu`, `Playing`, `Paused`, `GameOver`, and `Won`.
- Add score, lives, restart, and pause UI.
- Scope gameplay systems with state run conditions.

Validation:

- [ ] The ball does not move in menu, paused, won, or game-over states.
- [ ] Restart creates one clean game, not duplicate entities.
- [ ] UI reflects score/lives after one update cycle.
- [ ] Every state has a reachable entry and exit path.

### Milestone 6: Audio and animation

- Add collision, loss, and win sounds.
- Add a simple paddle or ball animation.
- Keep asset handles in an intentional resource or component.

Validation:

- [ ] One event creates one sound instance.
- [ ] Missing optional polish does not affect core simulation tests.
- [ ] Animation timer wraps correctly.
- [ ] Assets are licensed and attribution is recorded.

### Milestone 7: Packaging

```bash
cargo fmt --all -- --check
cargo check --all-targets --all-features
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
cargo test --doc
cargo build --release
cargo tree -d
```

Cargo builds the package and its dependencies, and `--release` selects optimized artifacts. Use `cargo update` deliberately because it changes dependency versions recorded in `Cargo.lock`, rather than treating it as a routine fix for unrelated errors.

Release gate:

- [ ] Fresh clone builds with `cargo build --locked --release`.
- [ ] Fresh clone runs with all required assets present.
- [ ] README contains controls, build commands, platform dependencies, Bevy version, and screenshots.
- [ ] No warnings, failed tests, undocumented lint suppressions, or uncommitted generated files.
- [ ] A complete playthrough can reach both win and loss states.

---
## Testing strategy

### Test pyramid

1. **Pure unit tests:** collision math, clamping, scoring, state-transition decisions, animation-frame selection.
2. **ECS system tests:** construct `App::new()`, insert only required resources/entities, call `app.update()`, and inspect the world.
3. **Plugin integration tests:** add a plugin to a minimal app and verify registrations and behavior.
4. **Manual rendering/audio tests:** visual placement, input feel, GPU behavior, and sound output.

Bevy also supports running a system directly on a `World` through `RunSystemOnce`, which is useful for focused tests, but its system-local state is discarded each invocation; use `App::update()` or cached systems when change detection, `Local`, or reader state matters.

### Quality gate script

Create `scripts/validate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cargo fmt --all -- --check
cargo check --all-targets --all-features
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
cargo test --doc
cargo build --release
```

Then:

```bash
chmod +x scripts/validate.sh
./scripts/validate.sh
```

rustfmt formats crate targets, while Clippy adds lints for correctness, suspicious constructs, style, complexity, and performance. Clippy's official CI guidance recommends turning warnings into errors; `-D warnings` remains the broadly compatible invocation.

### Per-concept validation template

For every new concept, add:

- One happy-path test.
- One boundary test.
- One failure or non-match test.
- One deliberate break/fix exercise.
- One two-minute verbal explanation.
- One clean run of `scripts/validate.sh`.

---

## Troubleshooting

| Symptom | Diagnostic | Fix |
|---|---|---|
| `alsa-sys` or `pkg-config` build failure | `pkgconf --modversion alsa` | Install Arch packages from Bevy's Linux dependency list and the sound-stack compatibility package |
| "Unable to find a GPU" or adapter failure | `vulkaninfo --summary` | Install/update the driver appropriate for the actual GPU |
| Example code has missing/renamed methods | `cargo tree -i bevy`; check the page's Bevy version | Use Bevy 0.19 docs/examples and the `v0.19.0` source tag; consult the official migration guide before adapting older code |
| Runtime panic B0001 | Inspect every `Query` in that system | Prove disjointness with `Without`, combine access appropriately, or use `ParamSet` sequentially |
| Runtime panic B0002 | Search system parameters for `Res<T>` plus `ResMut<T>` | Keep only `ResMut<T>` when both read and write access are needed |
| Spawned/modified entity is not visible immediately | Log before and after a schedule boundary | Account for deferred `Commands`; add only the required ordering/apply boundary or redesign across frames |
| Behavior changes between runs | Identify read-after-write dependencies | Use system sets, `.before`, `.after`, or `.chain()` only for real dependencies |
| Test expecting one entity fails | Count matching entities and inspect markers | Make setup invariant explicit; test duplicate and missing cases — `single` succeeds only for exactly one match |
| Rebuild/link is very slow | `cargo build --timings`; `cargo tree -e features` | Enable dev dependency optimization; use LLD/Mold; consider development-only dynamic linking after establishing a baseline |
| Duplicate crate versions | `cargo tree -d` | Align compatible dependency/plugin versions |
| Clippy suddenly reports many dependency or target issues | Compare `cargo tree -e features` and command flags | Run the same toolchain and feature matrix locally and in CI; do not suppress an entire lint category |
| `cargo clean` appears to "fix" builds repeatedly | Compare active toolchain, target, features, and environment | Fix the configuration mismatch; do not use cleaning as the permanent solution |

Key error references:

- [Bevy B0001](https://bevy.org/learn/errors/b0001/)
- [Bevy B0002](https://bevy.org/learn/errors/b0002/)
- [Bevy troubleshooting](https://bevy.org/learn/quick-start/troubleshooting/)
- [rustc error index](https://doc.rust-lang.org/error_codes/error-index.html)

### Diagnostic sequence

Use this order rather than changing several things at once:

```bash
rustup show active-toolchain
rustc --version --verbose
cargo --version
cargo metadata --format-version=1 --no-deps
cargo tree -i bevy
cargo tree -d
cargo check -vv
RUST_BACKTRACE=1 cargo run
```

---

## Plugin adoption

Bevy Assets is the official catalogue for community plugins, learning resources, and applications. Treat catalogue inclusion as discovery, not as proof that a crate fits the current project.

Evaluate each plugin with this checklist:

- [ ] Explicitly supports Bevy 0.19.
- [ ] Recent release and maintenance activity are visible.
- [ ] License is compatible with the project.
- [ ] Minimal example compiles in an isolated branch.
- [ ] Added dependencies and duplicate versions are reviewed with `cargo tree -d`.
- [ ] Required Cargo features are understood.
- [ ] Web/native target support matches the release plan.
- [ ] Core game rules remain independent of the plugin where practical.
- [ ] Removal cost is documented.

Recommended order:

1. `bevy-inspector-egui` for development inspection, after ECS basics; version 0.37 depends on Bevy 0.19 crates.
2. `bevy_rapier2d` only after writing and testing simple collision logic; Rapier exposes optional debug-render, SIMD, parallelism, serialization, and determinism features, so enable only those required.
3. Tilemap tooling only when the game actually needs authored or large maps; `bevy_ecs_tilemap` treats tiles as entities and identifies itself as an ECS-driven rendering library.

For a plugin crate, disable Bevy default features and enable only required capabilities where feasible; Bevy's official plugin-development guidance notes that features are additive and cannot be disabled downstream.

---

## Competency schedule

Use this as a planning aid, not a time-based promotion system.

| Stage | Typical effort | Deliverable | Exit evidence |
|---|---|---:|---|
| Toolchain | 0.5–1 day | Reproducible Rust/Arch setup | Setup gate |
| Rust core | 2–4 weeks | CLI simulation | Rust foundation gate |
| Bevy setup | 1–2 days | Minimal app and examples | Environment gate |
| ECS labs | 1–2 weeks | Tested headless ECS project | Six lab gates |
| Example archaeology | 3–7 days | Six modified examples | Rebuild-from-memory notes |
| Capstone | 1–3 weeks | Playable Breakout-style game | Release gate |
| Ecosystem | Ongoing | One justified plugin at a time | Plugin checklist |

Given prior Linux, Neovim, and programming experience, toolchain setup will likely be quick; do not let that familiarity hide Rust ownership or Bevy scheduling gaps. The fastest route is to shorten phases only when their gates already pass.

---

## Final practical exam

Complete without copying the official Breakout source:

1. Start from `cargo new` and Bevy 0.19.
2. Implement menu, play, pause, win, and loss states.
3. Implement paddle input, fixed-step ball motion, collision, bricks, score, lives, UI, and sound.
4. Write at least fifteen tests, including pure logic and ECS integration tests.
5. Introduce and repair one ownership error, one B0001 query conflict, one ordering bug, and one deferred-command misunderstanding; record each root cause.
6. Run the full validation script.
7. Build from a fresh clone with `--locked`.
8. Explain the application's ECS model, schedules, state transitions, and plugin boundaries in ten minutes without opening the code.

Passing criterion: every automated check is green, both manual playthrough outcomes work, and each architectural decision can be connected to an ownership, ECS, scheduling, or maintainability requirement.
