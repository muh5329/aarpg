# Hollowmere — Survive the Hollow Vale

A single-player, isometric open-world survival level in Godot 4.7. The level is approximately **176 × 188 meters**, with eight charted districts, seven enterable buildings, 50 gathering/loot/station sites and 16 enemies. It combines medieval scavenging and camp-building with direct sword/bow combat.

## Play and save

Double-click **Play.command** to play or continue the saved journey. It runs `builds/Hollowmere.pck` with Godot at `/Applications/Godot.app`. Godot is required; this is a playable pack, not a bundled standalone runtime.

Progress saves automatically every 60 seconds, when claiming/resting/restoring the beacon, on normal window close, and with **F5**. The save is `user://hollowmere_survival_v1.json` in Godot's application user-data directory. Inventory, needs, time, discovery, depleted resources/containers, defeated enemies, placed camps, upgrades, shelter, respawn and objectives persist.

**New Journey.command** starts fresh. This uses the same save slot: its next save replaces the previous journey. Verification uses a separate save and does not touch the player's slot.

To edit, open `project.godot` and press F5 in Godot. Forward+ rendering is tested on Apple M4 Pro / Metal.

## Controls

| Input | Action |
| --- | --- |
| WASD / arrows | Camera-relative movement |
| Shift | Sprint, using stamina |
| E / Enter | Gather, scavenge, use a station, talk, place a structure |
| J | Sword attack with nearby-target aim assistance |
| K | Bow attack with nearby-target aim assistance; consumes arrows |
| Q + left click | Equip weapon with Q; aim and attack toward cursor |
| Space | Dodge while moving; uses stamina and grants brief invulnerability |
| R | Use a bandage, or a legacy healing tonic |
| F / G | Eat a ration / drink carried water |
| Tab / I | Inventory |
| C, then 1–6 | Crafting and recipe selection |
| B | Preview placement of a crafted campfire kit or bedroll |
| E / Escape while building | Place / cancel |
| M | Full valley map |
| Mouse wheel | Camera zoom |
| F5 | Save while exploring |
| Escape | Close overlay/dialogue/build mode, or pause |

Inventory and crafting overlays pause simulation. Crafting feedback explains missing materials or required stations. Bandages use fiber; arrows use wood and stone; campfires use wood and stone; bedrolls use fiber and hide. Cooking needs a campfire and consumes raw food plus wood. Sword tempering needs ore, wood, and a claimed outpost workbench.

## Full-level progression

1. Search the settlement supply crate just east of the starting spot. Refill at the village well.
2. Follow the west road into **Timberwood**. Gather fallen logs, flax and field stones; search the woodcutter's cabin.
3. Craft a **campfire kit** with C → 3. Press B, find green valid ground, and press E to place. Campfires support cooking. Bedrolls can be placed after campfire kits are exhausted; E sets a respawn/rest point.
4. Gather **12 wood and 8 stone** beyond the campfire cost. Follow the western trail south and enter the **Ranger's Lodge** from its southern doorway. E at the workbench claims shelter. E again rests until morning and sets respawn.
5. Explore **Briar Farm** for raw food, rations and supplies. The **Drowned Marsh** has a clean spring, reeds and a fishing cache. Cook raw food near your campfire.
6. Travel to the **Iron Quarry** for ore. Prowlers and a brute inhabit the area. Temper the sword at the claimed outpost if desired.
7. Travel north to **Blackthorn Keep**. Defeat its two guards and the warden, then search the chest for the **signal lens**.
8. Return to the outpost beacon with the lens and **4 ore**. Restore it to establish a foothold. The world remains open for scavenging, crafting and exploration afterward.

The original **Last Lantern** quest from Mara is still available as an optional sanctuary expedition. Its ward requires the three sanctuary guardians specifically, not unrelated kills elsewhere in the valley.

## Places

| District | What to find |
| --- | --- |
| Hollowmere | Starting supplies, well, village cooking station, Mara and Iven |
| Timberwood | Logs, fiber, woodcutter's cabin |
| Briar Farm | Farmhouse, storehouse, crops, food, roaming enemies |
| Iron Quarry | Stone, iron veins, prowlers and brute |
| Drowned Marsh | Clean spring, reeds, fishing cache, shallow wetland |
| Ranger Outpost | Claimable lodge, workbench, shelter, signal beacon |
| Blackthorn Keep | Fortified ruin, guards, warden, signal chest |
| Ashen Sanctuary | Optional ember quest |

An abandoned tannery on the northeast loop provides extra hide, fiber and bandages. All buildings use automatic roof/front-wall cutaways; hidden walls remain physical. Roads form loops between districts. Navigation agents use a mesh baked from physical obstacles, and walls block melee as well as arrows.

Food and water decline over time. Low needs reduce stamina recovery; empty needs damage health. Night reduces daylight and increases enemy detection distance. Rest is blocked by nearby enemies and advances to morning at a food/water cost. Death returns you to your chosen respawn with progress preserved. Gatherable nodes and caches are finite in this level; the marked well and spring are renewable water sources.

## Verification

Actual Godot runs and viewport captures are in `evidence/survival/`. The survival verifier walks the physical road network, interacts through input events, pays crafting costs, places a camp, claims shelter, scavenges remote buildings, cooks/eats/drinks, gathers ore, upgrades the sword, defeats the keep encounter, restores the beacon and saves. A separate fresh process verifies persistent state.

```sh
# Full physical survival route from source
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --verify --survival-test --evidence-dir="$PWD/evidence/survival"

# Independently reload the verifier's save
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --verify --survival-test --resume-test --evidence-dir="$PWD/evidence/survival"

# Original quest / controls regression
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --verify --review --evidence-dir="$PWD/evidence/survival"

# Survival boundary fixtures (separate from the physical progression route)
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --verify --edge-test --evidence-dir="$PWD/evidence/survival"

# Explore remaining remote buildings in the exported pack
./Play.command -- --verify --survival-test --building-tour --evidence-dir="$PWD/evidence/survival"

# Build playable pack
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-pack macOS builds/Hollowmere.pck
```

## Source layout

- `scripts/frontier.gd` — larger level, districts, resources, interiors and encounters
- `scripts/survival.gd` — inventory, needs, crafting, placement, shelter, progression, saves
- `scripts/survival_verifier.gd` — survival progression and independent reload tests
- `scripts/main.gd` — world coordination, combat projectiles, original quest, camera/navigation
- `scripts/player.gd`, `scripts/enemy.gd` — movement, combat, stamina and AI
- `scripts/house.gd` — furnished interiors and reversible cutaway
- `scripts/world.gd`, `scripts/art.gd`, `shaders/` — environmental geometry/materials
- `scripts/hud.gd` — survival gauges, map, pack, crafting and dialogue
- `progress.md` — iterations, evidence, failures and remaining budget

Scanned materials are CC0 from Poly Haven; asset links are in `assets/textures/SOURCES.md`. Geometry and synthesized cues are original procedural assets. The gameplay direction draws from open-world survival games; no Project Zomboid, V Rising or Diablo game assets were copied.
# aarpg
