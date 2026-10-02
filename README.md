# MindFlip

An original landscape Android logic game. Tap to rotate a tile, connect the mint
source to every target, and watch the circuit illuminate. Twenty handcrafted
puzzles progressively teach branching, fixed paths, switches/gates, direction,
splitters, and color routing.

## Play

Open `project.godot` in **Godot 4.6.3** and press F6/F5, or run:

```sh
godot --path .
```

The Android debug APK is `builds/MindFlip-debug.apk`. A standalone Linux build is
`builds/MindFlip.x86_64`. Build outputs are intentionally ignored by Git; source,
export presets, tests, asset generators and rendered evidence are committed.

On Android, install the APK using the phone's normal APK installation flow, or:

```sh
adb install -r builds/MindFlip-debug.apk
```

Tap a path tile to rotate clockwise. Switches toggle their letter-matched gates.
Fixed tiles show locks. Arrow paths accept energy only at their tail. Splitters
accept at the tail and output on three other arms. Color pieces tint neutral
energy; incompatible colors cannot pass. All required targets must activate.

Undo restores a rotation or switch toggle and removes its move. Restart resets
the board immediately. Hint highlights one tile toward a verified solution and
does not rotate it. There is no move limit. Three stars require at most the authored
par; two stars allow `par + max(3, ceil(par/2))`; all other completions earn one.
Pars are achievable authored goals, not claims of globally minimal solutions.

Keyboard: arrow keys select tiles, Enter/Space rotates, Z undoes, R restarts,
H hints, Escape pauses/backs out. Touch is primary. Controller UI navigation
uses Godot's standard UI actions; full controller board mapping is future work.

## Architecture and assets

Native Godot 4 GDScript, Compatibility renderer, scalable 960×540 canvas, expanded
for landscape aspect ratios. No web runtime, network account or server is required.

- `scripts/puzzle_rules.gd`: side-effect-free port and directed/color connectivity.
- `scripts/puzzle_state.gd`: mutable board, move history, undo, restart, one-step hints.
- `data/levels.json`: complete portable definitions for all 20 levels.
- `tools/author_levels.py`: literal designer-authored routes, branches and scrambles;
  compiles level data without random generation.
- `tools/validate_levels.py`: independent Python evaluator, structural validation,
  witness replay, and a general backtracking solver with optimistic reachability
  pruning. It searches orientations independently of authored witnesses.
- `scripts/board.gd`: hit testing, rotation tweens, bounce, batched tile card atlas,
  light travel, pulses, target ripples, hint highlight and mechanism glyphs.
- `scripts/game.gd`, `scripts/overlay.gd`, `scripts/visuals.gd`: screens, responsive
  composition, native buttons, correct modal layering and shared visual language.
- `scripts/save_store.gd`: versioned JSON, temporary-file/backup/rename writes,
  backup recovery, best results, unlocked levels, settings and resumable sessions.
- `scripts/audio.gd`: bounded six-voice effects pool, looping ambience, lifecycle
  suspension. Headless CI loads assets but suppresses playback.
- `assets/visual/`: original small tile atlas and baked lighting background.
- `assets/audio/`: six original synthesized WAVs.
- `assets/icon.svg`: original MindFlip mark and app icon.
- `assets/fonts/`: DejaVu Sans, distributed under its included license.
- `tools/generate_visual_assets.py`, `tools/generate_audio.py`: editable art/audio
  sources. No RPG files or external game assets are used.

Tile definitions use `type`, `rotation` (0–3 clockwise), coordinates and optional
mechanism metadata. `fixed` decorates a path type rather than replacing its shape.
Start, target, cross and gate defaults stay fixed. Switches toggle instead of
rotating. Gate/switch `shape` preserves bends. Teleporter pairs are implemented
and tested as an extension point; none is introduced in this first campaign.

Network propagation tracks `(tile, entry port, energy color)`, respects directed
inputs and color filters, and terminates even with loops. Gates open from their
matching switch state; the switch does not have to be energized to control them.
Targets never forward energy. The completion predicate checks each required
individual target, including color. Level additions primarily require new data. The selector paginates larger catalogs
in groups of 20; save limits and progression use the loaded catalog length.

## Screens and saving

Custom splash → main menu → level select → gameplay, plus pause, settings and a
completion result. Completing N unlocks N+1. The energized board stays visible for
1.55 seconds before the result appears. Best moves and stars never regress.

Progress resides at `user://mindflip.json` (Godot's application-private storage).
Moves save immediately, including switch states and undo history. Continue restores
the current puzzle. App background/focus loss pauses gameplay, checkpoints and
suspends audio. App resume keeps the pause screen until the player chooses Resume.
Completion is saved before the celebration so interruption cannot lose a win.
No Android storage or Internet permission is required.

## Validation and builds

```sh
python3 tools/author_levels.py
python3 tools/generate_audio.py
python3 tools/generate_visual_assets.py
python3 tools/validate_levels.py
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --export-debug Android builds/MindFlip-debug.apk
godot --headless --path . --export-release Linux builds/MindFlip.x86_64
```

See [Android build notes](docs/ANDROID.md), [test evidence](docs/TEST_REPORT.md),
and the [visual guide](docs/VISUAL_GUIDE.md). The completed wrong-prompt safety
snapshot is on `safety/abandoned-rpg` (`01cf384`); `7a164c4` removed it from `work`.
The repository was empty before the mistake; no previous configuration was removed.

## Current limits and next work

English only. Twenty small handcrafted boards, with modest decoys in a few levels;
playtest difficulty and tune par goals before extending the campaign. Teleporters
are supported/tested but not taught or used yet. This build has no accounts, ads,
purchases, combat, story or online dependency.

The debug APK has been built and signature/manifest/alignment verified. No Android
phone/emulator was connected, so device installation, real touch hardware, cutout
behavior, audio routing and phone GPU/battery performance need device QA. The
software-renderer benchmark is not an Android performance guarantee. A Play-ready
release still needs an owner-controlled release key, Gradle AAB export and store
QA/materials. Next: install on a representative Android phone and play all 20
levels, then tune pacing, accessibility and animation/audio from those results.
