# Tier 1 Generator Assets — Design Spec
**Date:** 2026-06-25  
**Scope:** Tier 1 generators only (validate pipeline before expanding)

## Problem

Generator machines are currently plain colored 6×6×6 Parts. This spec covers the pipeline for replacing them with AI-generated meshes using Roblox's Cube mesh generation tool via the Studio MCP.

## Art Direction

**Style:** Chaotic/meme aesthetic combined with clean cartoon for broad (kid-friendly) appeal. Think bold outlines, exaggerated proportions, absurd concepts executed cleanly.

**Per-generator visual concepts:**

| Generator | `gen.id` | Visual Concept |
|---|---|---|
| Brain Jar | `BrainJar` | Cartoon mason jar with a cracked lid, overflowing with glowing pink brain fluid. Chunky wobbly proportions, neon liquid dripping down the sides. Bright blue and pink tones, clean cartoon outlines. |
| Meme Farm | `MemeFarm` | Tiny chaotic farm plot with oversized crops shaped like laughing emoji faces. A small tractor with googly eyes drives itself in circles. Bright green, thick cartoon outlines, slightly absurd. |
| Doomscroll Rig | `DoomscrollRig` | Giant smartphone bolted to a janky mechanical rig that auto-scrolls endlessly. Screen shows a blur of meme thumbnails. Dark orange and grey, industrial-cartoon style. |
| Neural Tap | `NeuralTap` | A cartoon brain on a pedestal with thick cables drilled directly into it. Neon blue electrical arcs crackling off the cables. Electric blue and cyan, clean but unsettling. |
| Skibidi Lab | `SkibidiLab` | Mad scientist workbench with bubbling beakers, with a giant toilet as the central apparatus — the iconic skibidi reference. Bright violet, chaotic cartoon lab aesthetic. |

**V0 scope:** Static meshes only. No animations, particles, or idle behavior.

## Asset Storage

`ServerStorage.GeneratorAssets` — a single Folder containing all pre-generated models.

- Each model is named exactly by `gen.id` (e.g. `BrainJar`, `MemeFarm`)
- Models are generated once during a Studio session via `generate_mesh` MCP tool and parented into this folder manually
- The folder persists in the `.rbxl` as the authoritative asset library
- To update a mesh: delete the old model from the folder, generate a new one, rename it to match `gen.id`

## `spawnMachine` Code Change

File: `Scripts/ServerScriptService/PlotSetup.legacy.luau` (lines 84–96)

### New logic

1. Look up `ServerStorage.GeneratorAssets:FindFirstChild(gen.id)`
2. **Found →** clone the model, pivot/position to `slot.Position + Vector3.new(0, 3.5, 0)`, set `Name = gen.id`, parent to `machines`
3. **Not found →** existing 6×6×6 colored Part fallback (no change to that path)
4. Either way: call an extracted `attachLabel(instance, gen.name)` helper with the same BillboardGui code

### Model/MeshPart handling

`generate_mesh` may return a `Model` or a bare `MeshPart`. The clone step handles both:
- `Model` → use `:PivotTo(CFrame.new(targetPos))`
- `MeshPart` → set `.Position = targetPos` and `.Anchored = true`

### Fallback guarantee

Tier 2/3 generators (and any Tier 1 without a mesh yet) silently fall back to the colored box. No other scripts are affected — `PassiveIncomeHandler`, `StatsCalculator`, and upgrade/rebirth systems reference `gen.id` strings, not Part types.

## Pipeline Workflow (repeatable for future tiers)

1. Open Studio with BrainrotClicker loaded
2. For each generator: run `generate_mesh` via MCP with the visual concept prompt
3. Rename result to match `gen.id`, parent into `ServerStorage.GeneratorAssets`
4. Playtest — `spawnMachine` automatically picks up the new model
5. Iterate on prompt if mesh needs adjustment (delete old, regenerate)

## Out of Scope (v0)

- Animations / idle effects
- Particle systems
- Per-tier visual progression (size/complexity scaling)
- Publishing assets to Roblox catalog
