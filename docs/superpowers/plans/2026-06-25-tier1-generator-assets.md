# Tier 1 Generator Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the plain colored-box placeholders for the 5 Tier 1 generators with AI-generated meshes stored in `ServerStorage.GeneratorAssets`, and update `spawnMachine` to clone from that folder with a colored-box fallback.

**Architecture:** Meshes are generated once at design time via the Roblox Cube MCP tool (`generate_mesh`) and stored in `ServerStorage.GeneratorAssets` named by `gen.id`. `spawnMachine` in `PlotSetup` checks that folder first; if a model is found it clones and positions it, otherwise falls back to the existing colored-box path. All changes are synced back to the disk mirror.

**Tech Stack:** Roblox Studio MCP (`generate_mesh`, `execute_luau`, `inspect_instance`), Luau, Edit/Write file tools for disk mirror sync.

## Global Constraints

- Studio must be open and in Edit mode (not Play mode) for all execute_luau calls
- All `execute_luau` calls use `datamodel_type="Edit"`
- Model names in `ServerStorage.GeneratorAssets` must exactly match `gen.id` strings: `BrainJar`, `MemeFarm`, `DoomscrollRig`, `NeuralTap`, `SkibidiLab`
- Art style: chaotic/meme + clean cartoon. No animations or particles in v0.
- Disk mirror suffix `.legacy.luau` → Studio Script (RunContext Legacy)

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `Scripts/ServerScriptService/PlotSetup.legacy.luau` | Modify lines 84–96 | Add `attachLabel` helper, update `spawnMachine` with clone-or-fallback logic |
| `Studio: ServerStorage.GeneratorAssets` | Create folder + 5 models | Asset library for generated meshes |

---

### Task 1: Create GeneratorAssets folder in Studio

**Files:**
- Modify: `Studio: ServerStorage`

- [ ] **Step 1: Create the folder via execute_luau**

```lua
local ss = game:GetService("ServerStorage")
if not ss:FindFirstChild("GeneratorAssets") then
    local f = Instance.new("Folder")
    f.Name = "GeneratorAssets"
    f.Parent = ss
end
return "GeneratorAssets created"
```

Call: `execute_luau(code=<above>, datamodel_type="Edit")`

Expected output: `"GeneratorAssets created"` (or no error if folder already existed)

- [ ] **Step 2: Verify the folder exists**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets")`

Expected: instance with `className: "Folder"`, `name: "GeneratorAssets"`, zero children.

---

### Task 2: Generate and place BrainJar mesh

**Files:**
- Modify: `Studio: ServerStorage.GeneratorAssets`

- [ ] **Step 1: Generate the mesh**

Call `generate_mesh` with:
```json
{
  "textPrompt": "Cartoon mason jar with a cracked lid, overflowing with glowing pink brain fluid. Chunky wobbly proportions, neon liquid dripping down the sides. Bright blue and pink tones, clean cartoon outlines. Low-poly Roblox style.",
  "size": { "x": 6, "y": 6, "z": 6 }
}
```

Note the path of the generated instance returned in the result (e.g. `Workspace.BrainJar` or similar).

- [ ] **Step 2: Rename and parent into GeneratorAssets**

Replace `<generated_path>` with the actual path from the generate_mesh result:

```lua
local ss = game:GetService("ServerStorage")
local assets = ss:FindFirstChild("GeneratorAssets")
-- Walk the path returned by generate_mesh to find the instance
-- e.g. if result path was "Workspace.MeshPart" use game.Workspace.MeshPart
local mesh = game:GetService("Workspace"):FindFirstChild("BrainJar")
    or game:GetService("Workspace"):GetChildren()[#game:GetService("Workspace"):GetChildren()]
if mesh then
    mesh.Name = "BrainJar"
    mesh.Parent = assets
    return "BrainJar parented to GeneratorAssets"
else
    return "ERROR: could not find generated mesh"
end
```

> If the generate_mesh result includes the exact instance path, use that directly instead of the fallback search above.

- [ ] **Step 3: Verify placement**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets.BrainJar")`

Expected: instance named `BrainJar` with className `MeshPart` or `Model`.

---

### Task 3: Generate and place MemeFarm mesh

**Files:**
- Modify: `Studio: ServerStorage.GeneratorAssets`

- [ ] **Step 1: Generate the mesh**

Call `generate_mesh` with:
```json
{
  "textPrompt": "Tiny chaotic farm plot with oversized crops shaped like laughing emoji faces. A small tractor with googly eyes drives itself in circles. Bright green, thick cartoon outlines, slightly absurd. Low-poly Roblox style.",
  "size": { "x": 6, "y": 5, "z": 6 }
}
```

Note the path of the generated instance from the result.

- [ ] **Step 2: Rename and parent into GeneratorAssets**

```lua
local ss = game:GetService("ServerStorage")
local assets = ss:FindFirstChild("GeneratorAssets")
local mesh = game:GetService("Workspace"):FindFirstChild("MemeFarm")
    or game:GetService("Workspace"):GetChildren()[#game:GetService("Workspace"):GetChildren()]
if mesh then
    mesh.Name = "MemeFarm"
    mesh.Parent = assets
    return "MemeFarm parented to GeneratorAssets"
else
    return "ERROR: could not find generated mesh"
end
```

- [ ] **Step 3: Verify placement**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets.MemeFarm")`

Expected: instance named `MemeFarm`.

---

### Task 4: Generate and place DoomscrollRig mesh

**Files:**
- Modify: `Studio: ServerStorage.GeneratorAssets`

- [ ] **Step 1: Generate the mesh**

Call `generate_mesh` with:
```json
{
  "textPrompt": "Giant smartphone bolted to a janky mechanical rig that auto-scrolls endlessly. Screen shows a blur of meme thumbnails. Dark orange and grey, industrial-cartoon style. Low-poly Roblox style.",
  "size": { "x": 5, "y": 8, "z": 4 }
}
```

Note the path of the generated instance from the result.

- [ ] **Step 2: Rename and parent into GeneratorAssets**

```lua
local ss = game:GetService("ServerStorage")
local assets = ss:FindFirstChild("GeneratorAssets")
local mesh = game:GetService("Workspace"):FindFirstChild("DoomscrollRig")
    or game:GetService("Workspace"):GetChildren()[#game:GetService("Workspace"):GetChildren()]
if mesh then
    mesh.Name = "DoomscrollRig"
    mesh.Parent = assets
    return "DoomscrollRig parented to GeneratorAssets"
else
    return "ERROR: could not find generated mesh"
end
```

- [ ] **Step 3: Verify placement**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets.DoomscrollRig")`

Expected: instance named `DoomscrollRig`.

---

### Task 5: Generate and place NeuralTap mesh

**Files:**
- Modify: `Studio: ServerStorage.GeneratorAssets`

- [ ] **Step 1: Generate the mesh**

Call `generate_mesh` with:
```json
{
  "textPrompt": "A cartoon brain on a pedestal with thick cables drilled directly into it. Neon blue electrical arcs crackling off the cables. Electric blue and cyan tones, clean but unsettling. Low-poly Roblox style.",
  "size": { "x": 6, "y": 7, "z": 6 }
}
```

Note the path of the generated instance from the result.

- [ ] **Step 2: Rename and parent into GeneratorAssets**

```lua
local ss = game:GetService("ServerStorage")
local assets = ss:FindFirstChild("GeneratorAssets")
local mesh = game:GetService("Workspace"):FindFirstChild("NeuralTap")
    or game:GetService("Workspace"):GetChildren()[#game:GetService("Workspace"):GetChildren()]
if mesh then
    mesh.Name = "NeuralTap"
    mesh.Parent = assets
    return "NeuralTap parented to GeneratorAssets"
else
    return "ERROR: could not find generated mesh"
end
```

- [ ] **Step 3: Verify placement**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets.NeuralTap")`

Expected: instance named `NeuralTap`.

---

### Task 6: Generate and place SkibidiLab mesh

**Files:**
- Modify: `Studio: ServerStorage.GeneratorAssets`

- [ ] **Step 1: Generate the mesh**

Call `generate_mesh` with:
```json
{
  "textPrompt": "Mad scientist workbench with bubbling beakers and test tubes, with a giant cartoon toilet as the central apparatus. Bright violet and purple tones, chaotic cartoon lab aesthetic. Low-poly Roblox style.",
  "size": { "x": 7, "y": 6, "z": 6 }
}
```

Note the path of the generated instance from the result.

- [ ] **Step 2: Rename and parent into GeneratorAssets**

```lua
local ss = game:GetService("ServerStorage")
local assets = ss:FindFirstChild("GeneratorAssets")
local mesh = game:GetService("Workspace"):FindFirstChild("SkibidiLab")
    or game:GetService("Workspace"):GetChildren()[#game:GetService("Workspace"):GetChildren()]
if mesh then
    mesh.Name = "SkibidiLab"
    mesh.Parent = assets
    return "SkibidiLab parented to GeneratorAssets"
else
    return "ERROR: could not find generated mesh"
end
```

- [ ] **Step 3: Verify all 5 assets are present**

Call: `inspect_instance(path="ServerStorage.GeneratorAssets")`

Expected: `childrenCount: 5`, children named `BrainJar`, `MemeFarm`, `DoomscrollRig`, `NeuralTap`, `SkibidiLab`.

---

### Task 7: Update spawnMachine — add attachLabel helper and clone-or-fallback logic

**Files:**
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` lines 84–96
- Modify: `Studio: ServerScriptService.PlotSetup` (sync via execute_luau)

**Interfaces:**
- Consumes: `ServerStorage.GeneratorAssets.<gen.id>` (Models/MeshParts from Tasks 2–6)
- Produces: `spawnMachine` clones the asset model when available; falls back to colored Part otherwise

- [ ] **Step 1: Edit the disk file**

In `Scripts/ServerScriptService/PlotSetup.legacy.luau`, replace the current `spawnMachine` block (lines 84–96):

**old_string** (exact match required):
```lua
local function spawnMachine(gen,plot)
    local machines=plot:FindFirstChild("Machines")
    if not machines or machines:FindFirstChild(gen.id) then return end
    local slot=plot:FindFirstChild("Slot"..(GEN_SLOTS[gen.id] or 0)); if not slot then return end
    local m=Instance.new("Part");m.Name=gen.id;m.Size=Vector3.new(6,6,6)
    m.Position=slot.Position+Vector3.new(0,3.5,0);m.Anchored=true
    m.BrickColor=GEN_COLORS[gen.id] or BrickColor.new("Medium stone grey")
    m.Material=Enum.Material.SmoothPlastic;m.Parent=machines
    local bg=Instance.new("BillboardGui",m);bg.Size=UDim2.new(0,130,0,26);bg.StudsOffset=Vector3.new(0,4.5,0)
    local tl=Instance.new("TextLabel",bg);tl.Size=UDim2.new(1,0,1,0)
    tl.BackgroundTransparency=1;tl.Text=gen.name;tl.TextColor3=Color3.new(1,1,1)
    tl.TextStrokeTransparency=0;tl.Font=Enum.Font.GothamBold;tl.TextSize=13
end
```

**new_string**:
```lua
local function attachLabel(instance, genName)
    local labelTarget
    if instance:IsA("Model") then
        labelTarget = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    else
        labelTarget = instance
    end
    if not labelTarget then return end
    local bg = Instance.new("BillboardGui", labelTarget)
    bg.Size = UDim2.new(0, 130, 0, 26)
    bg.StudsOffset = Vector3.new(0, 4.5, 0)
    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = genName
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 13
end

local function spawnMachine(gen, plot)
    local machines = plot:FindFirstChild("Machines")
    if not machines or machines:FindFirstChild(gen.id) then return end
    local slot = plot:FindFirstChild("Slot"..(GEN_SLOTS[gen.id] or 0))
    if not slot then return end
    local targetPos = slot.Position + Vector3.new(0, 3.5, 0)
    local assets = game:GetService("ServerStorage"):FindFirstChild("GeneratorAssets")
    local template = assets and assets:FindFirstChild(gen.id)
    if template then
        local m = template:Clone()
        m.Name = gen.id
        if m:IsA("Model") then
            m:PivotTo(CFrame.new(targetPos))
        else
            m.Position = targetPos
            m.Anchored = true
        end
        m.Parent = machines
        attachLabel(m, gen.name)
    else
        local m = Instance.new("Part")
        m.Name = gen.id
        m.Size = Vector3.new(6, 6, 6)
        m.Position = targetPos
        m.Anchored = true
        m.BrickColor = GEN_COLORS[gen.id] or BrickColor.new("Medium stone grey")
        m.Material = Enum.Material.SmoothPlastic
        m.Parent = machines
        attachLabel(m, gen.name)
    end
end
```

- [ ] **Step 2: Sync updated source to Studio**

Read the full updated `Scripts/ServerScriptService/PlotSetup.legacy.luau` from disk (using the Read file tool), then apply it to Studio:

```lua
local ss = game:GetService("ServerScriptService")
local script = ss:FindFirstChild("PlotSetup")
-- Splice new attachLabel+spawnMachine block in place of old spawnMachine
-- Find the boundary markers in the current source
local src = script.Source
local startMarker = "local function spawnMachine(gen,plot)"
local endMarker = "\nlocal function updatePadLabel"
local startIdx = src:find(startMarker, 1, true)
local endIdx = src:find(endMarker, 1, true)
if not startIdx or not endIdx then
    return "ERROR: markers not found. startIdx=" .. tostring(startIdx) .. " endIdx=" .. tostring(endIdx)
end
local newBlock = [[
local function attachLabel(instance, genName)
    local labelTarget
    if instance:IsA("Model") then
        labelTarget = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
    else
        labelTarget = instance
    end
    if not labelTarget then return end
    local bg = Instance.new("BillboardGui", labelTarget)
    bg.Size = UDim2.new(0, 130, 0, 26)
    bg.StudsOffset = Vector3.new(0, 4.5, 0)
    local tl = Instance.new("TextLabel", bg)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = genName
    tl.TextColor3 = Color3.new(1, 1, 1)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextSize = 13
end

local function spawnMachine(gen, plot)
    local machines = plot:FindFirstChild("Machines")
    if not machines or machines:FindFirstChild(gen.id) then return end
    local slot = plot:FindFirstChild("Slot"..(GEN_SLOTS[gen.id] or 0))
    if not slot then return end
    local targetPos = slot.Position + Vector3.new(0, 3.5, 0)
    local assets = game:GetService("ServerStorage"):FindFirstChild("GeneratorAssets")
    local template = assets and assets:FindFirstChild(gen.id)
    if template then
        local m = template:Clone()
        m.Name = gen.id
        if m:IsA("Model") then
            m:PivotTo(CFrame.new(targetPos))
        else
            m.Position = targetPos
            m.Anchored = true
        end
        m.Parent = machines
        attachLabel(m, gen.name)
    else
        local m = Instance.new("Part")
        m.Name = gen.id
        m.Size = Vector3.new(6, 6, 6)
        m.Position = targetPos
        m.Anchored = true
        m.BrickColor = GEN_COLORS[gen.id] or BrickColor.new("Medium stone grey")
        m.Material = Enum.Material.SmoothPlastic
        m.Parent = machines
        attachLabel(m, gen.name)
    end
end]]
script.Source = src:sub(1, startIdx - 1) .. newBlock .. src:sub(endIdx)
return "PlotSetup patched successfully"
```

Expected output: `"PlotSetup patched successfully"`

- [ ] **Step 3: Playtest verification**

Start play mode: `start_stop_play(is_start=true)`

Use `execute_luau(datamodel_type="Server")` to trigger spawnMachine for BrainJar on plot 1:

```lua
local ss = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local GD = require(RS:WaitForChild("GameData"))
local plot = game:GetService("Workspace").Plots:GetChildren()[1]
local machines = plot:FindFirstChild("Machines")
return machines and machines:FindFirstChild("BrainJar") and machines.BrainJar.ClassName or "not found"
```

> Note: spawnMachine only fires on pad Touched, so to test the clone path directly you can temporarily call it via execute_luau Server — or just walk a test character onto the BrainJarPad and check via inspect_instance.

Expected: returns `"MeshPart"` or `"Model"` (not `"Part"` which would indicate the fallback ran).

- [ ] **Step 4: Stop play mode**

`start_stop_play(is_start=false)`

---

### Task 8: Commit disk mirror changes

**Files:**
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` (already edited in Task 7 Step 1)

- [ ] **Step 1: Verify git diff looks correct**

```bash
git diff Scripts/ServerScriptService/PlotSetup.legacy.luau
```

Expected: diff shows old 13-line `spawnMachine` replaced with new `attachLabel` helper + updated `spawnMachine`.

- [ ] **Step 2: Commit**

```bash
git add Scripts/ServerScriptService/PlotSetup.legacy.luau docs/superpowers/specs/2026-06-25-tier1-generator-assets-design.md docs/superpowers/plans/2026-06-25-tier1-generator-assets.md
git commit -m "feat: Tier 1 generator mesh assets — ServerStorage.GeneratorAssets pipeline

- Add attachLabel helper extracted from spawnMachine
- spawnMachine clones from ServerStorage.GeneratorAssets with colored-box fallback
- 5 Tier 1 meshes generated via Roblox Cube (BrainJar/MemeFarm/DoomscrollRig/NeuralTap/SkibidiLab)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- ✅ `ServerStorage.GeneratorAssets` folder created (Task 1)
- ✅ All 5 Tier 1 meshes generated with visual concept prompts from spec (Tasks 2–6)
- ✅ `spawnMachine` clone-or-fallback logic with `attachLabel` helper (Task 7)
- ✅ Tier 2/3 fallback guaranteed — `GeneratorAssets` lookup returns nil for any gen without a mesh
- ✅ Disk mirror synced and committed (Task 8)
- ✅ Static meshes only — no animations/particles (v0 constraint)

**Placeholder scan:** No TBDs. All code blocks are complete and specific.

**Type consistency:** `attachLabel(instance, genName)` called identically in both branches of `spawnMachine`. `template:Clone()` used consistently. `gen.id` and `gen.name` field names match GameData schema throughout.
