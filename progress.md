# Hollowmere development progress

## Baseline — 2026-09-06
Workspace was empty. No previous project or progress file was present. Godot 4.7 stable is installed at `/Applications/Godot.app`. Reference is visual guidance only. All assets in this project are original procedural geometry; no external licenses or downloads required.

Verifier rubric (10 categories): launch/runtime; exploration/town; multiple interiors; cutaway and restoration; NPC dialogue; quest acceptance/completion; sword combat; bow combat; loot/quest objects; cohesive presentation/camera/controls. A full pass requires all categories and independent fresh review. Automated checks are supplemental evidence, not proof of aesthetic quality.

## Round 1 — connected slice implementation
- Changed: Created Godot project, procedural village/forest/sanctuary, two furnished houses, character animation, movement, sword/bow, NPCs, quest, HUD, audio cues.
- Actual evidence: `evidence/import.log` and `evidence/round1-runtime.log` from Godot import and graphical launch.
- Score: 0/10 verified; launch blocked.
- Failed approach: HUD reused local variable `lines` in a nested scope, which GDScript rejects.
- Next action: Rename the variable and run the rendered end-to-end verifier.
- Remaining budget: 19 of 20 meaningful attempts. Session/tool budget not exposed numerically.

## Round 2 — launch repair and actual route verification (in progress)
- Changed: Fixed HUD scope parse error. Added a verifier that moves through normal physics with Input actions and interacts via InputEventAction. Combat uses real hit tests and projectiles. No quest/health/position shortcuts in the main route.
- Evidence: `evidence/round2-runtime.log`, `evidence/verification.json`, and `evidence/verification-*.png`.
- Current results: Both houses reached through doors, roofs removed and restored, two NPC dialogues, quest accepted, gate crossed, pause verified, sword kill passed.
- Failed approach: Compatibility renderer with bright directional/ambient lighting produces a flat, washed-out world compared with reference.
- Next action: Finish quest route, then adjust lighting and inspect fresh renders.
- Remaining budget: 18 of 20 meaningful attempts.

### Round 2 final result
- 16/20 automated checks passed; rubric 7/10. Bow damage failed (0 hits), cascading into missing seed and quest completion, with one death. Archived evidence in `evidence/round2/`.

## Round 3 — requested isometric camera
- Changed: Lower diagonal orthographic camera (18,20,24), tighter framing, screen-relative movement, lower and cooler outdoor lighting. Updated verifier input projection for the new camera.
- Evidence: `evidence/round3/verification-01-village.png` and `verification-02-interior.png` show the new angle and unobstructed furnished room. `evidence/round3-runtime.log`.
- Score: 16/20 checks, rubric 7/10. Camera request addressed; both houses still accessible. Bow failure remains.
- Failed approach: Full-route bow test fails while isolated `evidence/bow-probe.log` shows nine real hits. Suspected point-blank projectile spawn skipping an overlapping target; rays do not detect starts inside a collider by default.
- Next action: Spawn arrows near the player center, enable inside-hit detection, rerun the unchanged physical quest route.
- Remaining budget: 17 of 20 meaningful attempts.

## Round 4 — close-range bow collision repair (in progress)
- Changed: Projectile origin moved from 0.65m ahead to 0.1m; swept collision rays detect starts inside an enemy. Added hit diagnostics. Enabled 4x MSAA.
- Evidence: `evidence/round4-runtime.log` and refreshed verifier screenshots.
- Next action: Review full-route results before environmental polish and independent review.
- Remaining budget: 16 of 20 meaningful attempts.

### Round 4 final result
- 20/20 automated checks passed, 0 deaths, 3 sword hits and 6 bow hits. Full quest reward delivered. Rubric 9/10, with presentation/final review outstanding. Evidence archived in `evidence/round4/`.
- Failed approach confirmed: Spawning a ray-tested projectile too far forward can put its origin beyond a nearby enemy. The repaired origin and inside-hit handling pass the unchanged full route.

## Round 5 — isometric presentation and environmental integration
- Changed: Forward+ renderer on Metal, soft shadows, ambient occlusion, subtle glow, textured masonry and ground, less repetitive path colors, 4x MSAA, larger contextual labels, readable location panel, tree-canopy occlusion, far walls retained in interiors, distinct house props, visible warm hearth reward, fixed idle enemy leg animation.
- Evidence: `evidence/round5-runtime.log`; archived `evidence/round5/verification-*.png`. Compared village and interior against rounds 2–4. The final style is a stylized low-poly interpretation, not photorealism.
- Score: 20/20 checks pass, 0 deaths; rubric 10/10 provisionally, independent review pending. Full quest route remains intact after visual changes.
- Failed approach: Initial terrain rectangle edge was visible at the lower camera angle; expanded surrounding ground so the playable region is not displayed as a floating board.
- Next action: Fresh independent review of input, combat collision, camera, and the packaged build.
- Remaining budget: 15 of 20 meaningful attempts.

## Round 6 — fresh independent packaged-build review
- Changed: Added a separate review route that visits Iven first and checks screen-relative movement, dodge invulnerability, Q switching, actual mouse-event shooting, dialogue input lockout, Escape cancellation, and physical collision with a visually hidden wall. Exported `builds/Hollowmere.pck` and created `Play.command` using the installed Godot runtime. Added README controls, route and reproduction commands.
- Evidence: `evidence/independent-review-runtime.log`, `evidence/independent-review.json`, and `evidence/independent-review-*.png`. Actual rendered packaged build, started fresh with no existing quest. Final interior screenshot visibly shows the completed quest, 65 silver, five tonics, restored hearth light, and visible player/furniture.
- Score: **28/28 independent checks passed**, including all 20 core route checks. Rubric **10/10** for this stylized vertical slice. Three sword hits, six bow hits, three kills, complete quest, zero deaths, 203.9m physical travel. No errors or warnings in final source, packaged-review, or fresh-launch runtime logs.
- Evidence correction: Earlier commentary counted the base route as 21 checks and independent review as 29; the JSON reports contain 20 and 28 respectively. The recorded pass counts above have been corrected to match the files.
- Failed approach / limitation: The optional desktop Computer Use inspection did not return and was terminated. No claim of that extra manual keyboard inspection is made. Real input-event, physics and rendered-build tests all passed independently of that tool. Visual style is low-poly; progress is session-only. The PCK uses installed Godot rather than bundling a standalone executable.
- Next action: Success stop condition reached. A fresh playable packaged game is left running (`evidence/manual-launch.log`). Begin by talking to Mara in the western house.
- Remaining budget: **14 of 20 meaningful attempts** unused. Session/tool budget not numerically exposed.

## User-directed visual overhaul — rounds 7 onward
The user rejected the earlier appearance as basic and requested a Diablo IV-like direction. The previous 10/10 presentation score was overstated: the mechanical checks passed, but they did not validate the desired art quality. This round treats visual quality as an outstanding criterion and keeps the lower isometric camera.

## Round 7 — scanned materials, gothic silhouettes, character and HUD rebuild
- Changed: Integrated six CC0 Poly Haven material sets (color, normal and roughness), replaced conical trees with branching bare trees/roots, introduced gothic arches, grave markers, rubble, dry weeds, volumetric mist and ash. Rebuilt player/enemy geometry with layered armor, helmets, articulated limbs, cloth capes and bone spikes. Rebuilt roof shingles, door surrounds and buttresses. Replaced panel-heavy HUD with a red vitality globe, compact skill bar and subdued map/quest overlays.
- Evidence: `evidence/overhaul/round7-preview.png`, `evidence/overhaul/preview1.log`. Actual Forward+ Metal render compared with `before-village.png`.
- Score: Launch/render passed without errors. Core mechanics await regression. Visual target improved materially but old flat well/market/lamps remain inconsistent; no full-success claim.
- Failed approach: urllib access to Poly Haven returned HTTP 403; changed download strategy to curl, which fetched the public assets successfully. Scanned materials alone revealed remaining primitive prop silhouettes.
- Next action: Replace the inconsistent props, add combat impact feedback, then run the full physical quest verifier.
- Remaining budget: 13/20 original meaningful attempts. This is resumed improvement work after user rejection, not acceptance of the former presentation score.

## Round 8 — prop consistency and combat impact
- Changed: Replaced cube lamps with iron fire baskets and animated flame meshes; added shadowed warm point lights. Applied scanned surfaces to the well, market, barrels, boundary masonry, ruins and interior timber. Added curved fading sword trails, directional hit particles, impact sounds and camera impulse; differentiated enemy silhouettes and contextual labels.
- Evidence: `evidence/overhaul/round8-runtime.log`, `evidence/overhaul/round8/verification-*.png` and JSON.
- Score: **20/20 core gameplay checks**, 3 sword hits, 6 bow hits, 3 kills, no deaths. Visual comparison confirms a materially darker and more detailed scene; no claim of AAA-production equivalence.
- Failed approach: The rigid rectangular paving edges and fine texture shimmer remained conspicuous in the first render.
- Next action: Blend path edges into mud, use temporal antialiasing, refine camera framing and verify the exported pack independently.
- Remaining budget: 12/20 meaningful attempts.

## Round 9 — composition, road blending and packaged review
- Changed: Added irregular dirt/stone blending at road edges, temporal antialiasing, camera framing further into the village, civilian material/weapon differences, and rebuilt the 20MB PCK with all textures included.
- Evidence: `evidence/overhaul/independent-runtime.log`, `independent-review.json` and corresponding screenshots. Compared the same fresh-launch view against the preserved pre-overhaul screenshot.
- Score: **28/28 independent packaged gameplay checks passed**, no deaths. Source/runtime and export logs contain no errors or warnings. User acceptance of the new art is not assumed from functional tests.
- Failed approach: The camera-framing review exposed open gable triangles below the taller rebuilt roof. Added textured gables within the same roof cutaway group.
- Next action: Targeted fresh-pack visual and physical entry/exit review for both houses after that geometry-only fix, then launch the new build.
- Remaining budget: 11/20 meaningful attempts.

## Round 10 — final gable/cutaway review and delivery
- Changed: Added textured front/back gables inside each reversible roof group. Added a targeted fresh-pack visual route for both house entrances, cutaways and restoration. Rebuilt the local playable pack.
- Evidence: `evidence/overhaul/visual-review-runtime.log`, `visual-review.json`, `visual-review-village.png`, `visual-review-interior.png`, `visual-review-eastern-interior.png`. Final screenshots were opened and visually inspected. Preserved before/after village screenshots for comparison.
- Score: **4/4 final architecture checks passed** after the **28/28 full packaged gameplay review**. No errors or warnings in final review/export logs. Darker art direction is visibly implemented; user approval of its quality remains separate from the functional verifier.
- Failed approach: No new failure in final review. Known visual limit: geometry and animation remain custom procedural assets rather than commercial-game production assets.
- Next action: Deliver the new pack and launch a fresh game. No public deployment or external publishing performed.
- Remaining budget: **10/20 meaningful attempts** unused; session/tool budget is not numerically exposed.

## Survival direction — clarified by user
The requested reference is gameplay from Project Zomboid / V Rising: an open-world survival loop, not merely Diablo-like visuals. Retained the original medieval setting and action controls, and built a larger connected valley around scavenging, gathering, finite supplies, crafting, camps, shelter, day/night and persistent state.

## Round 11 — survival systems and full valley foundation
- Changed: Expanded navigable space to about 176 x 188 m; seven buildings, eight charted districts, 16 enemies including variants and a warden, 50 resource/container/station sites. Added inventory, hunger/thirst/stamina, sprint, finite arrows, six recipes, placement preview, outpost/workbench/beacon progression, day/night, map/pack/crafting overlays and atomic save/load.
- Evidence: `evidence/survival/round11-runtime.log` and `verification-frontier.png` from a real graphical launch.
- Score: Runtime/render passed; initial population assertion failed because it expected more than 50 sites when the designed count is exactly 50. No runtime errors.
- Failed approach: Incorrect verifier threshold; replaced with exact expected population and a physical end-to-end progression test.
- Next action: Test resource costs, camp placement, all travel routes, outpost claim, the keep encounter, and independent save reload.
- Remaining budget: 9/20 original meaningful attempts.

## Round 12 — actual survival route exposes a blocked main road
- Evidence: `evidence/survival/round12-runtime.log`, `survival-route-01-valley-map.png`, crafting/resource/camp screenshots and blocked-route capture.
- Score: 9 checks passed before route failure. Scavenging, depletion, denied crafting, paid crafting and placement work.
- Failed approach: A lodge centered on the north–south road blocked through travel with its back wall. The test also needed to budget gathering for both a campfire and shelter rather than only the first recipe.
- Changed strategy: Offset remote buildings from through-roads, approach their front doors explicitly, and gather sufficient materials for the whole progression. Combat verification now approaches each encounter into actual weapon range instead of firing from beyond aggro range.
- Next action: Repeat the real route on the revised layout.
- Remaining budget: 8/20 original meaningful attempts.

## Round 13 — connected survival route (in progress)
- Changed: Moved ranger lodge, farmhouse, storehouse and tannery off through-roads. Corrected test travel to use front entrances and to budget both camp and shelter costs. Added encounter approach movement rather than assuming enemies were in range.
- Evidence: `evidence/survival/round13-runtime.log` and survival-route screenshots. Scavenging, harvesting, crafting, placement, shelter claiming and setting respawn have passed so far.
- Failed approach addressed: A physically connected road network must remain clear behind buildings as well as at their front doors. The corrected layout preserves a continuous outer loop.
- Next action: Finish resource/cooking/keep/beacon checks and load the saved world in an independent process.
- Remaining budget: 7/20 original meaningful attempts.

### Round 13 final evidence
- 20 checks passed through guarded-lens recovery; return route failed at the old/new terrain seam. `survival-route-blocked-route.png` shows the obstruction near the keep road. Full route traversed about 839m without death before stopping.
- Root cause: the expanded ground surface was 6cm lower than the original ground. CharacterBody3D could step down into the expansion but could not walk back up that vertical seam.

## Round 14 — continuous ground, camera clearance and pursuit
- Changed: Leveled both terrain surfaces; grouped decorative arches for near-player cutaway; added a navigation mesh baked from actual static collision and enemy path agents; added line-of-sight checks to both melee attacks so walls block damage. Fixed survival starvation tick cadence and next-morning rest; restored the beacon light when loading a completed save.
- Next action: Run the entire physical survival route, then independently reload its saved state. Test original quest interactions again after the combat/navigation changes.
- Remaining budget: 6/20 original meaningful attempts.

### Round 14 verifier correction
- The next route stopped at the village well: the verifier's diagonal from spawn to the western road cut through the well's physical rim. This is a test-path issue, distinct from the resolved terrain seam. Added the actual road junction and navigation-generated intermediate waypoints; movement still uses normal input and collision, with no teleportation.
- Navigation emitted a cell-height mismatch warning. Set both map cell size and height before assigning the mesh rather than suppressing the warning. Removed queued-for-deletion cleared trees from the scene before geometry parsing so they cannot leave phantom navigation obstacles.

## Round 15 — fresh route and legacy regression
- Changed: Corrected navigation configuration and verification path traversal.
- Next action: Re-run survival progression and the original quest independently, then check a fresh-process save reload.
- Remaining budget: 5/20 original meaningful attempts.

### Round 15 final evidence
- Actual Forward+ Godot route: **25/25 passed**, 1,015.9 meters traveled using physics/input, 22 bow hits, six encounter kills, zero deaths. Scavenging, finite resources, camp construction, shelter, cooking, ore, sword upgrade, keep encounter, lens, beacon and atomic save passed. Evidence: `evidence/survival/survival-route.json`, `round15-runtime.log`, and ten numbered viewport captures.
- Independent original-slice regression: **28/28 passed**, including NPC quest acceptance/completion, sword/bow combat, interior cutaways/restoration and controls. Evidence: `evidence/survival/independent-review.json`, `legacy-regression.log`.
- Visual review: farmhouse screenshot shows an unobstructed furnished interior with neighboring roof intact; valley map shows connected districts. This verifies readability and cutaway behavior, not parity with the commercial reference games.

## Round 16 — survival safeguards and save persistence
- Changed: Centralized healing input so one R press consumes one bandage, including while the pack is open. B exits crafting before opening placement. Added isolated boundary fixtures for zero arrows/stamina, recipe costs, placement rejection/cancel, bedroll crafting/respawn, melee wall obstruction, live doorway pursuit, night lighting and incomplete-save rejection.
- Failed approach: A bedroll inventory assertion ran before buffered input was dispatched, while later placement succeeded. Instrumentation showed the full unspent recipe immediately before the check. The verifier now explicitly flushes Godot's input queue after press/release; the recipe and placement both pass with unchanged gameplay recipe code.
- Actual running evidence: **20/20 edge checks passed**, `evidence/survival/survival-edges.json` and `edge-runtime.log`. Viewport captures `survival-edges-enemy-indoor-pursuit.png` and `survival-edges-night-camp.png` verify doorway pursuit and nighttime bedroll presentation.
- Fresh-process save evidence: **7/7 passed**, `survival-reload.json` / `reload-runtime.log`; outpost, beacon, depleted resources, camp, defeated warden, upgrade, discovery and respawn persist. Exported updated `builds/Hollowmere.pck`; packaged fresh-process reload also **7/7 passed** in `evidence/survival/pack-review/`.
- Score against verifier: 80/80 source runtime assertions pass across survival, legacy, edges and independent reload. Core requested gameplay is covered; final delivery review is checking additional remote buildings in the exported pack. Art remains procedural with scanned materials, and the level has finite gatherables rather than an endless survival economy.
- Next action: Finish the independent packaged remote-building tour, inspect its renders/logs, and launch the delivered pack.
- Remaining budget: 4/20 original meaningful attempts; no explicit token budget was supplied.

### Round 16 final review
- Exported-pack remote-building tour: **11/11 passed**, 269 meters physically traveled, zero deaths; woodcutter/storehouse/tannery entrances, loot, cutaways and roof restoration all passed. However, the tannery render showed a tree clipping through the furnished interior. Visual review therefore rejected final delivery despite the gameplay checks passing.

## Round 17 — clear building footprints in the full valley
- Changed: Remove nearby trees from both the original and expanded woodland passes after all buildings are created, with an eight-meter trunk clearance for overhanging branches. Removal happens before navigation geometry is baked. Added an all-seven-building clearance assertion to the independent packaged tour.
- Failed approach: Keeping trees away from named POI centers did not protect the outlying tannery, which is away from a district center. Building positions are now checked directly.
- Next action: Re-export and repeat the physical packaged tour; compare the tannery interior render against Round 16.
- Remaining budget: 3/20 original meaningful attempts.

### Round 17 final evidence and stop decision
- Fresh exported-pack tour: **12/12 passed**, zero deaths. Evidence: `evidence/survival/round17-pack-tour.log` and `survival-building-tour.json`. All seven footprints clear, and all three remote houses reachable, lootable, visibly open inside and restored after exit.
- Visual comparison: `round16-tannery-before.png` has a trunk through the room; `survival-building-tour-tannery_cache-interior.png` now shows clear flooring, furniture and doorway. Cabin/storehouse renders were also reviewed. No runtime errors or warnings in the final tour or export log.
- Final verifier coverage: 25 survival route + 28 original quest/control regression + 20 boundary fixtures + 7 independent source reload checks passed; exported-pack reload 7/7 and final tour 12/12 passed. The long route completed the survival objective; the separate legacy run completed Mara's quest using sword and bow. Additional final tour was an independent fresh launch of the packaged build.
- Stop: requested playable level and core verifier criteria pass, with independent final review complete. This is a finite survival level, with procedural art and a Godot-dependent local pack; it is not commercial-game feature or visual parity.
- Delivery: `Play.command` runs the updated pack, `New Journey.command` starts fresh in the same save slot, and `README.md` contains controls and progression.
- Next action: User playthrough and feedback on combat feel, survival pacing and visual direction.
- Remaining budget: 3/20 meaningful attempts unused; no explicit token budget supplied.
