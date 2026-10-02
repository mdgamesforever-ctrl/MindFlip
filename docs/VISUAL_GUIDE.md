# MindFlip visual source of truth

Premium geometric puzzle design, independent of any RPG aesthetic. Base canvas:
960×540 landscape with expansion, 32-unit minimum content margins plus detected
Android safe insets. Board left/center, a 242-unit controls panel on the right.
Tiles scale from roughly 63 to 108 logical units in the first 20 puzzles; keep
at least a 50-unit cell on supported layouts. Native buttons are at least 48 units
high. Supporting captions can be smaller; core numbers and actions are prominent.

Palette: dark navy `#0b1220`, panels `#121e2d`, recessed tray `#0e1926`, unlit tiles
`#1d2d3c`, readable ivory `#ecf3f1`, muted blue `#91a4b7`. Energy is mint `#78efd0`,
neutral targets gold `#f5ca7c`, color routes violet `#b6a0ff` and coral `#ff9a94`.
Never communicate mechanics through hue alone: targets are rings, sources have
lightning marks, arrows show direction, splitters have a center ring, fixed paths
show locks, and gates/switches carry paired letters. Color accessibility needs
further testing/alternate marking before store release.

Original logo: stepped connector between a mint filled source and gold target.
Rounded cards, narrow restrained borders, softly lit tops and small shadows.
The atlas contains three 128×128 anti-aliased cards in one 384×128 image. The
512×288 background lighting gradient is baked. Environment drawing is unnecessary.
No external game assets or generated RPG art appear in this project.

Track width is 5.5 logical units; consistent 37%-of-cell arms, round tips and a
shared center. Soft path glow is low alpha. Pulse dots move along energized arms.
Targets use a restrained activation ripple. Animation: 160ms cubic-out clockwise
rotation, 220ms small scale response; light propagation reveals tiles by graph
hop at 75ms per tile. Completion holds for 1.55 seconds before a separate overlay
CanvasItem appears above the still-live board. No expensive bloom shader or
unbounded particles. Draw steady animations without updating puzzle logic each frame.

Typography: licensed DejaVu Sans and Bold. Headlines 24–68 units, primary controls
15, gameplay counts 22–26, supporting copy 10–15. No giant tutorial walls; one
contextual sentence per level and an initial highlighted tile in level 1.

Generators are the editable originals: `tools/generate_visual_assets.py`,
`tools/generate_audio.py`, and `assets/icon.svg`. Their output is deterministic.
