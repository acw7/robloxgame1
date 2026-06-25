# BrainrotClicker: AdCap-Direction Endless Loop — Design Spec

**Date:** 2026-06-25
**Status:** Approved

## Overview

Take BrainrotClicker in an Adventure Capitalist direction: an endless idle clicker with a seemingly infinite number scale, a deep rebirth/prestige system granting permanent buffs, offline earnings as a core mechanic, and all content in one world. The core loop (click → earn → buy generators → BPS → buy upgrades → rebirth) stays intact. Three pillars are added: **Scale**, **Breadth**, and **Depth**.

---

## 1. Architecture Overview

**Scale** — A `FormatNumber` utility replaces all raw number display, handling numbers from 0 to infinity with suffixes and scientific notation.

**Breadth** — Generators expand from 5 to 15+ across 3 tiers. Tiers 2 and 3 unlock at milestone rebirths. New tiers have ~100× the BPS of the previous tier's top generator.

**Depth** — The rebirth system earns scaling Neurons, stacks a permanent global multiplier each reset, and triggers one-time content unlocks at milestone rebirth counts.

**Foundational addition** — DataStore persistence. Required for offline earnings, RebirthCount, and unlocked tiers to survive across sessions. Must land before anything else.

---

## 2. Data Persistence (DataStore)

### What gets saved

| Field | Type | Notes |
|-------|------|-------|
| `Brain` | number | Spendable at logout |
| `TotalBrains` | number | Lifetime total |
| `RP` | number | Neurons |
| `RebirthCount` | number | Milestone gate |
| `Generators` | table | `{id: count}` |
| `Upgrades` | table | `{id: true}` |
| `MetaUpgrades` | table | `{id: true}` |
| `LastLogout` | number | `os.time()` timestamp |

### Save/load flow

- **On join:** `DataStore:GetAsync(userId)` populates all `PlayerData` folders. First-time players get hardcoded defaults.
- **On leave:** `PlayerRemoving` calls `DataStore:SetAsync(userId, snapshot)`.
- **Auto-save:** every 60 seconds as crash backup (Roblox can drop `PlayerRemoving` on server crash).
- **Error handling:** all DataStore calls wrapped in `pcall`. Load failure → fresh defaults, no error screen.

### Offline earnings

Calculated at load time, before the session starts:

```
elapsed = min(os.time() - savedData.LastLogout, 28800)  -- cap 8 hours
bonus = BPS * elapsed * 0.5  -- 50% offline efficiency
Brain += bonus
```

Client shows a "Welcome back! You earned X Brains while away" popup on join.

---

## 3. Generator Tiers

All tier definitions live in `GameData` — never hardcoded elsewhere.

| Tier | Unlocked at | Generators | BPS ballpark |
|------|-------------|------------|-------------|
| 1 | Start | BrainJar, MemeFarm, SynapseTower, CortexFactory, SkibidiLab | 1 – 500 BPS |
| 2 | 1st rebirth | NeuralNetwork, MemeVault, DopamineDen, CortexCollider, QuantumQuirk | 50K – 2M BPS |
| 3 | 5th rebirth | (5 TBD — named at implementation) | 100M – 10B BPS |

Each tier's cheapest generator costs ~10–50× more than the previous tier's most expensive generator.

### Unlock mechanic

- `PlotSetup` reads `RebirthCount` on join and only spawns pads for unlocked tiers.
- On rebirth, if `RebirthCount` hits a milestone, newly unlocked tier pads are added to the plot live and a `TierUnlocked` RemoteEvent fires to the client for a banner.
- Locked pads are absent entirely — no grayed-out placeholders.

### Physical layout

- Tier 1 pads: ground floor (current positions)
- Tier 2 pads: second floor (already built)
- Tier 3 pads: extended second floor or deeper into the plot (decided at build time)

---

## 4. Rebirth System

### Scaling Neuron formula

```lua
neurons = math.max(1, math.floor(TotalBrains / GD.NeuronFormulaDivisor))
-- GD.NeuronFormulaDivisor = 100000 (tweakable)
```

Examples: 100K TotalBrains → 1 Neuron; 1M → 10 Neurons; 10M → 100 Neurons.

### Permanent stacking multiplier

Each rebirth applies a permanent global BPS & BPC multiplier:

```lua
rebirthMult = (1 + GD.RebirthMultPerLevel) ^ RebirthCount
-- GD.RebirthMultPerLevel = 0.10 (tweakable)
```

`StatsCalculator.Recalculate` folds `rebirthMult` into every BPS/BPC calculation. After 10 rebirths: ~2.6×. After 25: ~10.8×.

### Milestone unlocks (tweakable in GameData)

```lua
GD.RebirthMilestones = {
    [1]  = { unlockTier = 2, upgradeCategory = "NeuralExpansion" },
    [5]  = { unlockTier = 3, upgradeCategory = "CortexOverdrive" },
    [10] = { extraMetaSlot = true },
    [25] = { reserved = true },
}
```

Change any key here and `RebirthHandler` + `PlotSetup` adjust automatically.

### Reset scope

| Resets | Persists |
|--------|----------|
| Brain, TotalBrains, RawBrains | MetaUpgrades |
| ClickCount | RebirthCount |
| All Generators | Unlocked tiers |
| All Upgrades | Permanent multiplier |
| | RP (Neurons accumulate) |

---

## 5. Number Scaling

A single `FormatNumber(n)` function in `GameData`, required by both server and client.

### Format: `##.###` + suffix

- Up to 2 digits before decimal, exactly 3 after.
- Suffix steps up when the integer part would exceed 2 digits (at 100 of a unit).

### Suffix table

```lua
local SUFFIXES = {"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
-- Beyond Dc (~1e33): scientific notation "1.234e34"
```

### Examples

| Raw value | Display |
|-----------|---------|
| 947 | `"947"` |
| 1,234 | `"1.234K"` |
| 12,345 | `"12.345K"` |
| 1,234,567 | `"1.234M"` |
| 12,345,678 | `"12.345M"` |

### Usage rule

**No raw `tostring(number)` calls in any UI code.** Every number shown to the player goes through `FormatNumber`. This covers: HUD labels, pad billboards, upgrade cards, rebirth progress, offline earnings popup.

---

## 6. New RemoteEvents & Data Values

### New RemoteEvents (ReplicatedStorage)

| Event | Direction | Payload |
|-------|-----------|---------|
| `TierUnlocked` | server → client | tier number |
| `OfflineEarnings` | server → client | amount earned |

### New PlayerData values

| Value | Type | Location |
|-------|------|----------|
| `RebirthCount` | IntValue | `player.PlayerData` |

---

## 7. Implementation Order

1. **DataStore persistence** — foundational; everything else depends on `RebirthCount` and `LastLogout` surviving sessions.
2. **FormatNumber utility** — wire into all existing UI before adding new content.
3. **RebirthCount + scaling Neurons + permanent multiplier** — deepen the existing rebirth system.
4. **Milestone unlock logic** — gate tier spawning behind `RebirthCount`.
5. **Tier 2 generators** — new `GameData` entries, new pads on second floor, new upgrade category.
6. **Offline earnings** — calculate at load, fire client notification.
7. **Tier 3 generators** — follow same pattern as Tier 2.
