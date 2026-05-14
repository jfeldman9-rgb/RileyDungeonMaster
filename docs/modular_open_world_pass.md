# Modular Open World Pass

This pass starts the DeepSeek architecture migration without destabilizing the current playable scene.

## New Runnable Prototype

`res://scenes/open_world_prototype.tscn` is a separate modular sandbox for the next-generation open-world version. It includes:

- `RileyPlayer` as a `CharacterBody3D`
- `WorldGenerator` with streaming 48x48 terrain chunks
- `WorldChunk` rolling terrain, foliage multimeshes, landmark markers, paths, and landmark ruins
- `CameraRig` with third-person adventure follow, Q/E orbit, and portrait pullback
- `EnemyManager` with Area3D spawn zones
- `ObjectPool` for reusable enemy placeholders
- `LODManager` for chunk visibility and shadow culling
- `DayNightCycle` scaffold
- `AudioManager` scaffold

## Main Scene Safety

`res://scenes/main.tscn` still runs the current game. The new modular managers are attached there in inactive mode so scripts parse and stay available without replacing working gameplay yet.

## Next Integration Step

When ready, migrate one feature at a time from `scripts/game.gd` into the modular prototype:

1. Move Riley combat into `PlayerController`.
2. Replace placeholder enemies with broccoli/fruit monster scenes managed by `EnemyManager`.
3. Move the static open-world landmarks from `game.gd` into `WorldChunk` landmark data.
4. Switch `run/main_scene` to `open_world_prototype.tscn` only after combat, HUD, and boss flow are restored there.
