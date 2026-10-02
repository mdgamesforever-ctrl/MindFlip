# MindFlip build evidence — 2026-10-02

## Cleanup

Initial Git inspection found no commits, no tracked configuration, and only
mistaken RPG-generated art/source files. `01cf384` preserves those files on
`safety/abandoned-rpg`; `7a164c4` removed them from `work`. `.git` and both commits
remain intact. The correct project begins from the resulting empty working tree.
RPG implementation is absent from the finished tree and exported game.

## Automated validation

`python3 tools/validate_levels.py`: **20/20 PASS**, 582 independent search nodes,
about 0.022 seconds. Checks dimensions/coordinates, tile kinds, rotations, start,
targets, mechanism metadata and portal pair definitions. Every initial board is
unsolved. Every authored witness activates all required targets and all mandatory
non-decoy pieces. Independent generic orientation/switch search finds a solution
for every level without taking witness rotations as its answer.

| Level | Puzzle | Introduction | 3-star goal | Validated |
|---|---|---|---:|---|
| 1 | A little twist | One highlighted rotation | 1 | PASS |
| 2 | Find your flow | Multiple pieces | 9 | PASS |
| 3 | Around the bend | Rotation reinforcement | 11 | PASS |
| 4 | Two destinations | T-junction branches | 7 | PASS |
| 5 | The long way | Longer routes / decoys | 17 | PASS |
| 6 | Cross currents | Four-way junction | 8 | PASS |
| 7 | Anchored | Locked tile | 6 | PASS |
| 8 | Between the anchors | Several locks | 10 | PASS |
| 9 | Hold the center | Fixed branching | 10 | PASS |
| 10 | Open sesame | Switch and gate | 1 | PASS |
| 11 | Switchback | Gated bent route | 7 | PASS |
| 12 | Double permission | Two gate channels | 12 | PASS |
| 13 | Go with the arrow | One-way paths | 5 | PASS |
| 14 | A directed detour | Rotated direction | 12 | PASS |
| 15 | No turning back | Directed branches | 15 | PASS |
| 16 | Three ways forward | Splitter | 7 | PASS |
| 17 | Divide and deliver | Three target routes | 13 | PASS |
| 18 | A change of color | Color path/target | 3 | PASS |
| 19 | Separate spectra | Independent colors | 16 | PASS |
| 20 | The MindFlip | Combined 7×5 board | 14 | PASS |

Goals are achievable authored pars; global optimality is not claimed.

`godot --headless --path . --script tests/test_game.gd`: **398 checks, 0 failures**.
Runtime replays all 20 puzzles through actual move/hint APIs. Coverage includes:

- Four rotations restore shapes; straight/corner/T/cross connectivity via campaign.
- Forward/reverse one-way, splitter input/output, blocked cells, fixed paths.
- Switch toggle, open/closed gate, independent channel isolation.
- Color acceptance, mismatch rejection, incompatible path-color rejection.
- Paired and unpaired teleporters (supported but not included in campaign).
- Every puzzle's initial unsolved state, useful nonmutating hint, undo, restart,
  moves, completion, required targets and achievable par.
- Atomic persistence, reload, corrupt-primary backup recovery, best result retention,
  stars, progressive unlocking, settings and session/undo checkpoint.
- Actual scene callbacks, touch events, ignored emulated duplicate mouse event,
  safe-inset coordinate offset, invalid taps, paused input blocking, lifecycle
  save/pause/resume, and continued session reconstruction.
- Completion saved before its 1.55s celebration; overlay/board/control layer order.
- 960×540, 1200×540, 960×600 and 960×720 layouts, board bounds and touch cells.
- Larger appended catalogs paginate and load without rewriting puzzle code.
- Audio asset loading and 16-second looping ambience. Playback is intentionally
  suppressed in headless CI; native previews exercise the audio player lifecycle.

## Native interaction and visual checks

`tests/native_interaction.py` uses X11/xdotool, not puzzle API shortcuts, to tap
a wrong tile, press Undo, tap the solution tile, then verify the persisted result:
level 1, **1 move, 3 stars**, next level unlocked. It clicks Next, Pause and Resume,
and verifies a level-2 session. PASS. Screenshots include that real completion and
pause state. Separate fixture screenshots show the larger board and all screens.
The renderer uses the actual Godot scene/viewport rather than a drawn mockup.

Inspected menu, board, levels, settings, completion, pause, ultrawide and tablet
renders. Inspection found a modal stacking problem and it was fixed with a separate
overlay CanvasItem above the board. Minimum button height was increased to 48
logical units, and locked level cards retain visible numbers. No developer UI or
RPG visuals ship. Supporting copy and color accessibility still need phone/user QA.

Evidence files:

- `menu.png`, `levels.png`, `tutorial.png`, `gameplay.png`
- `build-gameplay.png` (actual exported standalone build)
- `gameplay-ultrawide.png` (1600×720, 20:9)
- `gameplay-tablet.png` (1280×800, 16:10)
- `completion-native.png`, `pause.png` (real native clicks)
- `completion.png` (level-20 solved fixture), `settings.png`

## Performance observations

A 10,000-iteration level-20 evaluator benchmark averaged **98.03 µs/evaluation**.
Connectivity updates on moves, not on animation frames. Rendering has 35 tiles
at most, one small tile-card atlas, one baked gradient, bounded audio voices and
finite lightweight effects. No full-screen bloom or expensive shaders.

Single native instance, Xvfb, Mesa llvmpipe software rendering, 1280×720:
**40.4 measured frames/sec**, median CPU frame **31.740ms**, median **394 draw calls**,
Godot static memory **35.7 MiB**. The scene is capped/targeted at 60 FPS. These are
host software-renderer measurements, not phone GPU measurements. Android device
performance, memory/battery and sustained 60 FPS need representative-device QA.

## Android and export

Godot native debug export succeeded and the exporter verified signing. The exported Linux executable also passes a packaged headless launch and actual
rendered-launch smoke check. Its gameplay screenshot confirms embedded resources
load correctly. Independent
apksigner verification reports valid v2/v3 signatures; zipalign verification passes.
AAPT confirms package `com.mindflip.game`, label `MindFlip`, version 0.1.0/code 1,
min SDK 24, target/compile SDK 36, landscape orientation and VIBRATE only.
Immersive mode, safe-inset conversion, scalable touch UI and app lifecycle handling
are configured. No Android hardware/emulator was attached: on-device install/run
was not claimed or tested. Release signing, AAB export and Play submission remain.

Outputs: `builds/MindFlip-debug.apk`, `builds/MindFlip.x86_64`.
See `BUILD_ARTIFACTS.txt` for final sizes, hashes and verification results.
