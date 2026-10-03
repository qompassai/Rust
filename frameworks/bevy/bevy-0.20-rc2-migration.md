# Bevy 0.20 RC2 Changes and Migration Guide

## Status and recommendation

Bevy `v0.20.0-rc.2` is a **pre-release**, published on September 28, 2026 from the `release-0.20.0` branch. Its release page links both the complete `v0.19.1...v0.20.0-rc.2` diff and the smaller `v0.20.0-rc.1...v0.20.0-rc.2` fix set.[^1]

Keep the main learning project on Bevy 0.19.1 until 0.20 final unless the goal is specifically release-candidate testing. Use a separate branch or duplicate project for RC2 because Bevy explicitly warns that major releases contain breaking API changes and provides migration guides rather than guaranteeing easy migrations.[^2]

The official 0.19-to-0.20 migration page is currently marked **draft** and its headline “most important changes” list is unfinished. Treat this report as an RC snapshot: verify every item against the final release notes and migration guide before upgrading production code.[^3]

## Safe test setup

Create a migration branch and preserve the 0.19 lockfile state first:

```bash
git status --short
git add Cargo.toml Cargo.lock src tests assets
git commit -m "chore: checkpoint before Bevy 0.20 migration"
git switch -c test/bevy-0.20-rc2
```

Pin the release candidate exactly in `Cargo.toml`:

```toml
[dependencies]
bevy = "=0.20.0-rc.2"
```

Then update only Bevy, inspect the resolved graph, and establish the first compiler-error inventory:

```bash
cargo update -p bevy --precise 0.20.0-rc.2
cargo tree -i bevy
cargo tree -d
cargo check --all-targets --all-features 2>&1 | tee bevy-020-check.log
```

Do not combine the upgrade with unrelated refactors, plugin additions, asset changes, or module reorganizations. Compiler-guided migration is most reliable when each commit addresses one subsystem and existing tests distinguish API repairs from behavior regressions.

## Impact map

| Area | Expected impact | Main action |
|---|---:|---|
| Basic 2D game using Bevy prelude | Medium | Recompile, check sprite ordering, UI defaults, pointer APIs, and state rename |
| BSN scenes or UI | High | Rewrite scene references, values, enums, and list separators |
| Custom shaders | Very high | Convert naga_oil-flavored WGSL to WESL; plain WGSL remains supported |
| Custom render pipelines | Very high | Audit extraction, bind groups, depth/stencil, camera/view APIs, shader paths, and weak ordering |
| Bevy UI/text widgets | High | Audit font sizing, fallback fonts, editable text, clipping, border radius, and interaction APIs |
| Custom ECS internals | High | Update observers, exclusive systems, `WorldQuery`, dynamic access, and resource-query code |
| Typical `Res`/`Query` systems | Low–medium | Most code should compile after targeted renames |
| Third-party plugin-heavy project | High | Wait for explicit Bevy 0.20 support or test each plugin independently |

## Headline additions

### BSN scenes

BSN syntax is substantially cleaner but source-breaking. Scene references now require `@`, ordinary component expressions no longer need `template_value`, enums can use normal `Default + Clone`, enum fields must be fully specified, and entity lists use `--` separators; brace-delimited `bsn_list! { ... }` is preferred because rustfmt leaves that form alone.[^3]

```rust
// 0.19-style
bsn! {
    Node
    Children [
        (#OkButton @button("Ok")),
        (#CancelButton @button("Cancel")),
    ]
}

// 0.20-style
bsn! {
    Node
    Children [
        #OkButton
        @button("Ok")
        --
        #CancelButton
        @button("Cancel")
    ]
}
```

Migration checklist:

- [ ] Prefix scene variables, scene functions, and scene expressions with `@`.
- [ ] Remove `template_value(...)` wrappers.
- [ ] Remove `VariantDefaults`/`FromTemplate` where normal `Default + Clone` is sufficient.
- [ ] Fill every field in enum variants.
- [ ] Replace list commas/parenthesized entities with `--`.
- [ ] Prefer `bsn! {}` and `bsn_list! {}` delimiters.
- [ ] Load every migrated scene and test all named-template references.

Validation exercise: convert one menu scene containing a template function, local value, enum component, and two children; then deliberately remove an `@` and verify that the resulting diagnostic can be explained.

### Scheduling and ECS

Bevy 0.20 adds `chain_weak`, `before_weak`, and `after_weak`. Unlike strict ordering, weak ordering constrains only systems whose tracked ECS access conflicts, allowing unrelated systems in adjacent sets to overlap for more parallelism; built-in render and UI schedules now use weak ordering in several places.[^4][^5]

This creates one important audit: a custom system must not rely on an implicit set boundary when its real dependency is hidden in atomics, channels, interior mutability, `NonSend` state, or external globals. Express the dependency through ECS access where practical, or add explicit strict `.before(...)`/`.after(...)` ordering.[^3]

Exclusive function systems now use the same `FunctionSystem`/`SystemParam` machinery as regular function systems. `&mut World` implements `SystemParam` and may appear anywhere that does not conflict with other parameters; low-level code using `ExclusiveFunctionSystem`, `ExclusiveSystemParam`, `ExclusiveMarker`, `System::is_exclusive`, or the old `System::initialize` result must migrate.[^3]

Observer lifecycle bundle matching moves into the event pattern:

```rust
// 0.19
world.add_observer(|on: On<Add, Player>| {
    // ...
});

// 0.20
world.add_observer(|on: On<Add<Player>>| {
    // ...
});
```

Other important ECS migrations:

- `NextState::set_if_neq` becomes `NextState::set_if_different`.
- `On<E, B>` becomes `On<Pattern>`; dynamic lifecycle observers use forms such as `On<Add<()>>`.
- `FilteredResources*` is deprecated in favor of `QueryBuilder`, `QueryParamBuilder`, resource entities, and ordinary queries.
- Custom `WorldQuery` implementations must explicitly implement `init_nested_access` and `update_archetypes`.
- `DeferredWorld::query(&mut state)` becomes `state.query_mut(&mut world)`.
- Some APIs using `Entity::PLACEHOLDER` now return `Option<Entity>`.
- Component-ID constants are typed `ComponentId` values; call `.index()` only when a raw index is truly required.

ECS validation:

- [ ] Every observer fires exactly once for its intended component/event pattern.
- [ ] Same-state transitions use `set_if_different` where transition schedules should not rerun.
- [ ] Systems communicating outside tracked ECS data have explicit ordering tests.
- [ ] Change-detection tests cover exclusive systems; RC2 includes a fix specifically for exclusive-system change detection.[^1]
- [ ] Enable schedule ambiguity reporting in tests.
- [ ] With Bevy’s debug support enabled, run deterministic tests under multiple schedule shuffle seeds to expose hidden ordering assumptions.

### Shaders and WESL

Bevy’s engine shaders now use WESL and the naga_oil preprocessor is gone. Custom shaders using naga_oil directives must be translated and generally renamed from `.wgsl` to `.wesl`; plain WGSL without preprocessor directives still works, WESL support is always enabled, the old `shader_format_wesl` feature is gone, and GLSL support has been removed while SPIR-V passthrough remains.[^3]

```wgsl
// Before: naga_oil-flavored WGSL
#import bevy_pbr::forward_io::VertexOutput
#ifdef VERTEX_COLORS
var<private> tint: vec4<f32>;
#endif

// After: WESL
import bevy_pbr::render::forward_io::VertexOutput;
@if(VERTEX_COLORS)
var<private> tint: vec4<f32>;
```

Key migration rules:

- Imports end in semicolons and precede declarations/enables.
- Replace `#import` with WESL `import` paths.
- Replace `#ifdef`/`#elif`/`#else` with WESL conditional attributes.
- Replace numeric shader interpolation such as `#{NAME}` with `constants::NAME`.
- Remove `#define_import_path`; embedded modules use crate/file paths.
- Update moved module paths, including PBR render and prepass modules.
- For custom OIT material shaders, use `MATERIAL_OIT_ENABLED`; pass premultiplied color to `oit_draw` as required by the material alpha mode.

Validation exercise:

1. Convert one custom material shader.
2. Compile it with every shader-def combination the game uses.
3. Exercise opaque, blend, premultiplied, and masked paths as applicable.
4. Run native Vulkan and any supported WebGPU/WebGL target.
5. Fail the test intentionally with an old import to confirm the error identifies the expected module.

### Sprite rendering

The `Sprite` backend is migrated onto `Mesh2d` and `Material2d` infrastructure. `Sprite` gains an `alpha_mode` field supporting blend, opaque, and mask behavior; same-Z draw order can change, so overlapping sprites should have deliberate Z values rather than relying on incidental insertion order.[^3]

This unification enables richer sprite materials and moves 2D rendering toward shared mesh/material infrastructure. It also raises the importance of validating culling, batching, picking, alpha behavior, and ordering; RC2 specifically fixes sprites disappearing after leaving and re-entering the camera view.[^1]

Sprite validation:

- [ ] Assign explicit Z values to every potentially overlapping layer.
- [ ] Check opaque, blended, and alpha-masked sprites.
- [ ] Move sprites out of and back into the frustum.
- [ ] Swap images and custom sizes at runtime.
- [ ] Verify sprite picking after transforms and camera changes.
- [ ] Capture before/after screenshots for representative scenes.
- [ ] Profile draw calls and frame time rather than assuming the backend migration is neutral.

### 2D materials and meshes

Bevy 0.20 adds a 2D counterpart to 3D extended materials through `MaterialExtension2d` and `ExtendedMaterial2d`. Advanced users also gain mesh-shader integration with Bevy’s pipeline cache, aimed at workloads such as meshlets, procedural geometry, and voxels.[^6]

Treat mesh shaders as an advanced, hardware-sensitive path rather than a default replacement. Establish adapter-feature checks, retain a fallback path, and validate on every supported GPU/backend.

### UI and text

The UI/text changes are broad:

- `Val::Em` and `Val::Rem` add font-relative sizing; resolution APIs now need `EmSize` and `RemSize`, and `ComputedNode` stores the resolved values.[^3]
- `TextFont::default()` moves from a fixed 20 px size to `FontSize::Rem(1.0)`; specify `FontSize::Px(20.0)` where exact legacy sizing is required.
- Font sources support CSS-style fallback-family lists, helping cover glyphs absent from the primary font.[^7]
- `InlineBox` reserves custom inline layout space; `InlineImage` provides image content within text layout.
- Border corners support elliptical radii through `CornerRadius`.
- `FixedNode` positions a UI node relative to the target camera viewport rather than its parent.
- Clipping stores transformed rectangles and can represent fully clipped content.
- `EditableText` and interactive `TextInput` responsibilities are separated; a working input field generally needs both components.
- `TextScroll` is removed in favor of `EditableText::viewport`/`TextViewport`.
- Escape now clears text-input focus and continues bubbling, so dialog/window Escape handlers may execute on the same key press.
- Legacy UI `Button` and `Interaction` paths are deprecated in favor of UI widgets plus picking/pressed state.

```rust
// Keep a fixed legacy-equivalent size when desired.
TextFont {
    font_size: FontSize::Px(20.0),
    ..default()
}
```

UI validation:

- [ ] Compare every screen at multiple DPI/scale factors.
- [ ] Test root `RemSize` changes and nested `EmSize` behavior.
- [ ] Test missing-glyph fallback with symbols and non-Latin scripts used by the game.
- [ ] Verify tab order, pointer input, keyboard activation, disabled states, and accessibility roles.
- [ ] Test Escape in a text field inside a modal.
- [ ] Test transformed, nested, and fully clipped UI.
- [ ] Check fixed nodes against viewport resize and multiple cameras.
- [ ] Snapshot critical layouts at 720p, 1080p, ultrawide, and a high-DPI logical size.

### Pointer input

Pointer events are flattened: types such as `Pointer<Press>` become `PointerPress`, event payload fields live directly on that event, and the embedded `Pointer` exposes fields such as `id` and `position`. Generic handlers should use the new `PointerEvent` trait.[^3]

```rust
// 0.19
fn on_press(press: On<Pointer<Press>>) {
    info!("{:?}", press.pointer_location.position);
}

// 0.20
fn on_press(press: On<PointerPress>) {
    info!("{:?}", press.pointer.position);
}
```

Validation exercise: write a generic logger for press, move, and release events; verify original target, bubbling target, pointer ID, position, drag behavior, touch, and mouse input.

### Rendering behavior

`Tonemapping::None` becomes true passthrough: it no longer applies color grading, dithering, or negative-channel clamping. Use `Tonemapping::Linear` to keep those stages while omitting the tone curve; `Camera2d` defaults to linear tonemapping, while `ScreenSpaceTransmission` becomes opt-in for `Camera3d`.[^3]

`Tonemapping` and `DebandDither` move to `bevy_render::view`. Rust re-exports reduce ordinary import breakage, but reflected type paths in scenes and Bevy Remote Protocol keys must be updated.[^3]

Rendering audit:

- [ ] Replace semantic uses of `Tonemapping::None` with `Linear` where grading/dither should remain.
- [ ] Add `ScreenSpaceTransmission` explicitly to cameras that need it.
- [ ] Update reflected paths in serialized scenes and BRP clients.
- [ ] Check HDR, wide-gamut, and negative-channel workflows; luminance adjustment no longer clamps automatically.
- [ ] Review custom depth/stencil code because depth attachment types were generalized for stencil support.
- [ ] Review render-world window access: extracted windows/surfaces are represented through ECS queries rather than old aggregate resources.
- [ ] Audit custom render systems placed in built-in weakly ordered sets.

### Assets and compression

`CompressedImageSaver` moves to a `ctt`-based backend that selects BCn formats for desktop or ASTC for mobile and adds automatic mipmap generation. The old Basis Universal behavior remains behind `compressed_image_saver_universal`; projects needing identical old behavior must rename the feature explicitly.[^8][^9]

```toml
# Preserve the old Basis Universal path
bevy = { version = "=0.20.0-rc.2", features = ["compressed_image_saver_universal"] }
```

Asset validation:

- [ ] Delete processed-asset caches and rebuild from source.
- [ ] Compare output format, size, mip count, load time, and visual quality.
- [ ] Test desktop and mobile target profiles independently.
- [ ] Confirm JPEG processing matches project expectations.
- [ ] Do not commit regenerated assets until the selected backend is intentional.

### Crate splits

Geometry primitives and related traits move from `bevy_math` to the new `bevy_shape` crate; curves and splines move to `bevy_curve`; extraction infrastructure moves from `bevy_render` to `bevy_extract`. The umbrella `bevy::prelude::*` hides much of the first two changes, but direct crate users and projects with default features disabled must update dependencies and imports.[^3]

| 0.19 path/feature | 0.20 replacement |
|---|---|
| `bevy_math::primitives::*` | `bevy_shape::*` / `bevy_shape::prelude::*` |
| `bevy_math::curve::*` | `bevy_curve::*` |
| `bevy_math::cubic_splines::*` | `bevy_curve::cubic_splines::*` |
| `bevy_math/curve` feature | `bevy/bevy_curve` feature |
| `bevy_render::extract_plugin` | `bevy_extract::extract_plugin` |

Extraction derives now identify target sub-apps, allowing extraction to more than one app. Custom rendering code should add `#[extract_app(RenderApp)]`; multi-sub-app code can list additional targets.

### Error handling

`BevyError` gains `context` and lazy `with_context`, providing human-readable context chains similar to error-reporting crates. This is useful at asset, configuration, scene-loading, and plugin boundaries where a bare lower-level error lacks operational meaning.[^10]

Exercise: replace one context-free `?` chain with two useful boundaries, then trigger the failure and verify that the message describes both the failed operation and the underlying cause without requiring a backtrace.

### Reflection and low-level APIs

Advanced integrations should audit these changes:

- `FromType` is replaced by parameterized `CreateTypeData`.
- `ReflectFromPtr` methods are split/renamed for `Any` and raw-pointer use.
- `Ptr::as_ptr` returns `*const u8`; mutation requires an explicit cast where sound.
- `WgpuWrapper` is removed in favor of direct wrapper constructors/accessors.
- Manual `AsBindGroup` implementations migrate from `UnpreparedBindGroup`/`unprepared_bind_group` to `BindGroupBuilder`/`build_bind_group`.
- `ShaderBuffer` construction and mutation favor owned buffers and `extend`/`extend_from_slice`.
- `MeshAabb::compute_aabb` becomes `get_aabb`.
- `MeshTag(x)` becomes `MeshTag::new(x)`, and the value is available as `tag.value`.
- `CustomAttributes::with_attribute` becomes `CustomAttributesBuilder`.

These are unlikely to affect the learning capstone unless it implements custom reflection, rendering, or unsafe ECS access. Plugin authors should treat them as first-class migration work.

## RC2-specific fixes

RC2 is primarily a stabilization update over RC1. Notable fixes in the linked RC1-to-RC2 comparison include sprite re-entry visibility, meshlet texture sampling and UV derivatives, bindless extended-material cleanup, disabled Feathers number-input despawning, environment-map filtering, deferred alpha-mask rendering, text cursor clearing, settings serialization of `None`, and exclusive-system change detection.[^1]

RC2 should still be treated as provisional. The Bevy 0.20 milestone includes release-candidate issues, and current repository issues include rendering and text-layout reports that may not yet be reflected in the draft migration guide.[^11][^12][^13][^14]

RC validation checklist:

- [ ] Reproduce every project-specific 0.19 rendering baseline on RC2.
- [ ] Run tests under release mode as well as dev mode.
- [ ] Exercise minimize/restore, resize, monitor disconnect, and GPU/backend changes.
- [ ] Move sprites through frustum boundaries repeatedly.
- [ ] Exercise text wrapping with every shipped font.
- [ ] Run leak checks while spawning/despawning materials, UI, and scenes.
- [ ] Record any regression with a minimal reproduction and exact RC commit.

## Migration workflow

### Inventory

Search before changing dependencies:

```bash
rg -n 'bsn!|bsn_list!|template_value|VariantDefaults|FromTemplate' src assets
rg -n '#import|#ifdef|#define_import_path|\.wgsl' assets src
rg -n 'Pointer<|Interaction|TextScroll|EditableText|FontSize|BorderRadius' src
rg -n 'Tonemapping::None|ScreenSpaceTransmission|DebandDither' src assets
rg -n 'FilteredResources|ExclusiveFunctionSystem|WorldQuery|On<[^>]+,' src
rg -n 'bevy_math::(primitives|curve|cubic_splines)' src Cargo.toml
rg -n 'UnpreparedBindGroup|ShaderBuffer|MeshTag\(|compute_aabb' src
```

### Compiler pass

Fix errors in dependency order:

1. Cargo features and incompatible plugins.
2. Crate moves and imports.
3. Removed/renamed Rust APIs.
4. Observer/system signatures.
5. BSN syntax and reflected paths.
6. Shader compilation.
7. Behavior regressions after compilation succeeds.

After each cluster:

```bash
cargo fmt --all -- --check
cargo check --all-targets --all-features
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
```

### Behavior pass

```bash
cargo test --release --all-targets --all-features
cargo build --release --locked
RUST_BACKTRACE=1 cargo run --release
```

Manually validate input, state transitions, UI layout, text, sprite order/culling, audio, scene loading, asset processing, and every custom render path. A clean compile is not proof of equivalent behavior because several changes deliberately alter defaults or ordering.

### Commit structure

Use surgical commits:

```text
chore: pin Bevy 0.20 RC2
fix: update Bevy crate splits and imports
fix: migrate ECS observers and state APIs
fix: migrate BSN syntax
fix: convert custom shaders to WESL
fix: migrate UI and pointer input APIs
fix: restore explicit rendering semantics
fix: update asset processing features
```

## Plugin compatibility

Do not force a plugin onto 0.20 by patching its Bevy version alone. A plugin can compile while relying on changed ordering, reflected type paths, render extraction, material preparation, pointer events, or sprite internals.

For every plugin:

- [ ] Find an explicit 0.20-compatible release or upstream branch.
- [ ] Read its migration notes and Bevy feature matrix.
- [ ] Inspect `cargo tree -d` for simultaneous Bevy 0.19 and 0.20 crates.
- [ ] Run the plugin’s examples and tests against RC2.
- [ ] Verify serialization/reflection paths.
- [ ] Verify native and web targets used by the project.
- [ ] Keep a rollback commit or branch.

## Guide integration

The original 0.19 learning guide should remain the stable track for now. Add a short “Bevy 0.20 preview” callout to its setup phase and use this report as an optional post-capstone migration lab.

Recommended lab gate:

- [ ] Complete the capstone on 0.19.1.
- [ ] Tag the baseline: `git tag bevy-0.19-capstone`.
- [ ] Migrate on a separate branch to exact RC2.
- [ ] Preserve all original tests.
- [ ] Add regression tests for changed defaults and scheduling behavior.
- [ ] Produce a migration log mapping each failure to the relevant subsystem.
- [ ] Repeat against 0.20 final before merging into the main branch.

## Final knowledge check

Explain and demonstrate all of the following without opening this report:

1. Why RC2 should not silently replace the stable version in the main learning track.
2. The difference between strict and weak system ordering.
3. How observer bundle matching changed.
4. How to convert naga_oil directives to WESL.
5. Why same-Z sprite ordering must not be assumed.
6. The semantic difference between `Tonemapping::None` and `Tonemapping::Linear` in 0.20.
7. How `Em` and `Rem` are resolved.
8. Why interactive editable text needs both state and input behavior.
9. Which direct `bevy_math` imports moved to `bevy_shape` and `bevy_curve`.
10. How to prove a plugin is actually 0.20-compatible rather than merely compiling.

Passing criterion: the RC branch passes fmt, check, Clippy, debug/release tests, and manual subsystem checks; all behavior changes are intentional; and the project can return to the 0.19 baseline with a clean branch switch.

---

## References

1. [Releases · bevyengine/bevy](https://github.com/bevyengine/bevy/releases) - Releases: bevyengine/bevy · Release list · v0.20.0-rc.2.

2. [GitHub - bevyengine/bevy: A refreshingly simple data-driven game ...](https://github.com/bevyengine/bevy) - A refreshingly simple data-driven game engine built in Rust - bevyengine/bevy

3. [0.19 to 0.20](https://bevy.org/learn/migration-guides/0-19-to-0-20/) - Like every major Bevy release, Bevy 0.20 comes with its own set of breaking changes. The most import...

4. [Overlap system set executions #19650 - bevyengine/bevy](https://github.com/bevyengine/bevy/issues/19650?timeline_page=1) - The system sets are ordered (X, Y).chain(). chain methods for a cycle, provide weak and strict varia...

5. [bevy/crates/bevy_ecs/src/schedule/config.rs at main](https://github.com/bevyengine/bevy/blob/main/crates/bevy_ecs/src/schedule/config.rs) - ... system between them in the chain are still ordered. This is useful for ordering large /// groups...

6. [Guidance on adding Mesh Shader support #24785](https://github.com/bevyengine/bevy/discussions/24785) - I've been experimenting with running mesh shaders in Bevy. I would like to help add mesh shader supp...

7. [Some characters display as boxes with Text2d · Issue #24425](https://github.com/bevyengine/bevy/issues/24425) - I expected the code to display a Ω character, but it instead displays as a box. Additional informati...

8. [Improve compressed image workflows · Issue #24903](https://github.com/bevyengine/bevy/issues/24903) - improved the compressed image workflow by adding BCn/ASTC support, mipmapping, and other features.

9. [bevyengine/bevy at finder.usmans.me](https://github.com/bevyengine/bevy?ref=finder.usmans.me) - CompressedImageSaver revamp. A new version of Bevy containing breaking changes to the API is release...

10. [Add the ability to attach context to `BevyError` · Issue #19714](https://github.com/bevyengine/bevy/issues/19714) - What problem does this solve or what need does it fill? I sometimes call functions inside Bevy syste...

11. [0.20 · Milestone #43 · bevyengine/bevy](https://github.com/bevyengine/bevy/milestone/43) - [v0.20.0-rc.1] PS4 Controller triggers (LeftTrigger2, RightTrigger2) incorrectly register as Other(6...

12. [Issues · bevyengine/bevy](https://github.com/bevyengine/bevy/issues) - A refreshingly simple data-driven game engine built in Rust - Issues · bevyengine/bevy.

13. [Grayscale images are yellow #25945 - bevyengine/bevy](https://github.com/bevyengine/bevy/issues/25945) - Appears correct in 0.19.1. Image. I didn't see anything related in the release notes or migration gu...

14. [Text wrapping behaves poorly in flex layouts with some fonts](https://github.com/bevyengine/bevy/issues/25941) - With some fonts, text nodes in flex layouts will wrap incorrectly, seemingly without updating the no...

