# Riley vs Kenzie - Dungeon Master

Small Godot 4 fantasy adventure prototype starring Riley and Kenzie. The default scene is now the modular open-world prototype: a compact open valley with branching routes, streamed terrain chunks, landmark ruins, seal objectives, broccoli monsters, ninja-star combat, and a Kenzie tower payoff.

Open `project.godot` in Godot 4.6 or newer, then run the main scene.

Controls:
- Desktop: WASD/arrows move, Q/E turns the camera, Space slices, F throws ninja stars, Shift dashes.
- Mobile/web: left side is a virtual joystick, with Slice, Dash, and Star buttons on the right.

Current entry point:
- `scenes/open_world_prototype.tscn` is the new modular open-world pass.
- `scenes/main.tscn` is the older monolith kept for reference while features are migrated.

Key new systems:
- `scripts/world_generator.gd` streams terrain chunks.
- `scripts/world_chunk.gd` builds rolling terrain, paths, foliage, landmarks, rocks, ruins, and collision.
- `scripts/visual_director.gd` restores the higher-fidelity mood with sky, fog, glow, SSAO, DOF, and lighting.
- `scripts/player_controller.gd` owns modular Riley movement/combat.
- `scripts/enemy_manager.gd` owns modular spawn zones and area-colored enemy placeholders.
- `scripts/world_objective_manager.gd` owns seal collection, Kenzie gate unlock, tower boss prototype, and payoff story card.
