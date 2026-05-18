# interaction-system

**Status:** Shipped

## Goal

Two paired mechanics that keep "dash is the only verb" honest:
1. **Interaction** — dashing into an interactable fires its `on_dash_into` (per the GDD's *dash IS interact*).
2. **Magnet pickup** — interactables can drop `Pickup` instances that float to the player and apply a payload on contact, so the heal / loot moment has weight instead of teleporting into the stat line.

Ships the framework + one concrete interactable (water cooler → heal pickups).

## Player-facing behavior

- Each interactable carries an `Interaction` Resource declaring `stops_dash: bool` and an `on_dash_into` body. Dashing into one fires it once.
- **Water Cooler** (*Office Hydration Station*) — drops three heal pickups at its base on first dash-into, then visibly drains (modulate dims). Subsequent dashes are no-ops.
- Heal pickups idle in place. Once the player enters their attract radius, they lerp toward the player and disappear on contact, restoring `heal_amount` HP each (capped at `equipped_amulet.max_health`).
- `stops_dash = false` (the cooler's default): slash dash continues past, hitting enemies behind.
- `stops_dash = true` (future doors etc.): dash terminates at the interactable like a wall hit.

## Data

`Interaction` (`scripts/interaction/interaction.gd`, `class_name Interaction extends Resource`):
- `stops_dash: bool` — default `false`; player consults this on contact.
- `on_dash_into(player: Node, interactable: Node) -> void` — virtual no-op default.

`Interactable` (`scripts/interaction/interactable.gd`, attached to an Area2D node):
- `@export var interaction: Interaction` — the behavior Resource.
- `var consumed: bool = false` — set by the Interaction's body when the prop is spent. Player skips firing when true.
- Layer: `INTERACTABLE_LAYER = 16` (new). Player's InteractArea masks this.

`Pickup` (`scripts/interaction/pickup.gd`, attached to an Area2D node, `class_name Pickup`):
- `@export var tuning: InteractionTuning` — shared magnet feel.
- `var _seeking: bool = false` — flips true once the player enters attract radius (no rescind once seeking).
- `_physics_process(delta)`: if player in tree, compute distance; once ≤ `tuning.attract_radius`, set `_seeking = true`; while seeking, `global_position = global_position.lerp(player.global_position, clampf(tuning.lerp_factor * delta, 0.0, 1.0))`.
- `body_entered(Player)` → consumes via `_apply_payload(player); queue_free()`, **gated on `_seeking`**. Direct overlap during the pre-seek window is a no-op so the magnet phase is the only consumption path.
- `_apply_payload(player: Node) -> void` — virtual no-op default; subclasses override.

`InteractionTuning` (`scripts/resources/interaction_tuning.gd`, `class_name InteractionTuning`) at `resources/interaction_tuning.tres`:
- `attract_radius: float` — default 60.0; pixels at which a pickup starts seeking the player.
- `lerp_factor: float` — default 8.0; pickup position lerp coefficient per second.
- `seek_delay: float` — default 0.1; seconds a fresh pickup waits before auto-seeking. Brief enough that the scatter still reads but the magnet kicks in fast. Consumption is gated on the seek phase — overlap during the delay is ignored.
- `scatter_friction: float` — default 4.0; per-second velocity decay for the pre-seek scatter motion. Higher = drops stop sooner.

`Pickup.velocity: Vector2` — public field, set by the spawner before add_child. During the pre-seek window, velocity is integrated into position and decayed via `tuning.scatter_friction`. Zeroes when seeking begins. `WaterCoolerInteraction` randomizes `scatter_speed_min..scatter_speed_max` along the same outward direction used for spawn offset, so each drop visibly flies out from the cooler.

`HealPickup` (`scripts/interaction/pickups/heal_pickup.gd`, `class_name HealPickup extends Pickup`):
- `@export var heal_amount: int = 1`.
- Overrides `_apply_payload`: caps to `player.equipped_amulet.max_health`, mutates `player.health`, emits `player.damaged.emit(-heal_amount, null)` as the placeholder healed-popup hook (consistent with Vampiric gem until a real `healed` signal lands).

`WaterCoolerInteraction` (`scripts/interaction/interactions/water_cooler_interaction.gd`, `class_name WaterCoolerInteraction extends Interaction`):
- `@export var heal_pickup_scene: PackedScene` — the HealPickup scene to spawn.
- `@export var drop_count: int = 3`.
- `@export var scatter_radius: float = 14.0`.
- `on_dash_into`: if `interactable.consumed` → return. Set `consumed = true`. Spawn `drop_count` HealPickup instances at `interactable.global_position + (random unit vector × scatter_radius)`. Tint the interactable's visual modulate to a `depleted_color` (read from the cooler scene's exported field) to signal spent state.

`Player` (`scripts/player.gd`) drift:
- New `@onready var interact_area: Area2D = $InteractArea` (added to player.tscn — `collision_layer = 0`, `collision_mask = 16`, `monitoring = true`).
- `interact_area.area_entered.connect(_on_interact_area_entered)`.
- `_on_interact_area_entered(area: Area2D)`: only fires while `is_dashing`; walks to `area.get_parent()` (the Interactable root); guards on `consumed` and presence of `interaction`; calls `interaction.on_dash_into(self, root)`. If `interaction.stops_dash`, calls the existing wall-hit termination path so the dash ends at current position and emits `wall_hit`.

`core_dash` drift:
- Dash can now terminate via interactable contact (`stops_dash = true`) in addition to walls / distance / stamina. Existing `wall_hit` signal is reused as the termination event for both surfaces. (Future spec may rename if other terminators land.)

Scenes:
- `scenes/interactables/water_cooler.tscn` — Area2D root + script attaching `Interactable`; visual Polygon2D (blue rectangle); `CollisionShape2D` (CircleShape2D radius ~10); `interaction` field set to a new `resources/interactions/office_hydration_station.tres` (WaterCoolerInteraction with `heal_pickup_scene` pointing at heal_pickup.tscn, `drop_count = 3`).
- `scenes/interaction/heal_pickup.tscn` — Area2D root + Pickup script; small green dot Polygon2D; CollisionShape2D radius ~3; `collision_layer = 32` (new PICKUP_LAYER), `collision_mask = 8` (player body) so `body_entered` fires.

## Edge cases & out-of-scope

- Multiple dashes into a depleted cooler: `consumed` short-circuits; no pickups, no popup.
- Pickup spawned with no player present: idle forever (no warning). Acceptable.
- Player dies before reaching pickups: pickups continue idling; reset on scene reload.
- Pickup at full HP: HealPickup still consumes the pickup (intentional — drops are a finite resource). `_apply_payload` no-ops the heal but `queue_free`s the pickup.
- Two pickups land on the player same frame: each calls `_apply_payload` independently; both consumed.
- Interactable inside a wall: collision shape may not be reachable; layout problem, not a code problem.
- Reposition dash (sword unloaded) into an interactable: fires per pillar 1 — dash is the verb, weapon state is irrelevant. (Different from enemies, which require the slash dash.)
- Lerp overshoot at high frame rates: clampf cap on lerp factor prevents NaN; pickup never overshoots player position.
- `stops_dash = true` mid-flight: reuses `wall_hit` event; downstream consumers (SFX wall clang) fire on interactables too. Acceptable until per-source events split.
- Out of scope: vending machine / door / form / NPC / Dark Gem interactables, pickup inventory state, save/load of consumed flags across rooms, attract sound, pickup VFX (sparkle), heal-flash on the player, real `healed` signal + HUD, telegraphed cooldown UI, multi-payload pickups, knockback on interactable hit, screen shake.

## Tasks

- [x] `scripts/interaction/interaction.gd` — `Interaction` base Resource with `stops_dash` + `on_dash_into` no-op.
- [x] `scripts/interaction/interactable.gd` — `Interactable` script attaching to Area2D root, with `@export interaction` and `consumed: bool`.
- [x] `scripts/resources/interaction_tuning.gd` + `resources/interaction_tuning.tres` (`attract_radius = 60.0`, `lerp_factor = 8.0`).
- [x] `scripts/interaction/pickup.gd` — `Pickup` script with seeking state machine + virtual `_apply_payload`.
- [x] `scripts/interaction/pickups/heal_pickup.gd` + `scenes/interaction/heal_pickup.tscn` (Area2D, layer 32, mask 8, green dot visual).
- [x] `scripts/interaction/interactions/water_cooler_interaction.gd`; create `resources/interactions/office_hydration_station.tres` referencing the heal_pickup scene with `drop_count = 3`.
- [x] `scenes/interactables/water_cooler.tscn` (Area2D root, blue rectangle visual, CollisionShape2D, `Interactable` script with `interaction` set to the cooler Resource).
- [x] `scenes/player.tscn` — add `InteractArea` child (Area2D, mask 16, monitoring on); CollisionShape2D matching body radius.
- [x] `player.gd` — `@onready interact_area`; connect `area_entered`; dispatcher (dash gate, consumed gate, on_dash_into call, optional dash-termination on `stops_dash`).
- [x] `m3_combat_demo.tscn` — place one water cooler near the player spawn for smoke-testing.
- [x] Smoke-test: dash into cooler → three green dots scatter; walk near them → they lerp to the player and disappear; HP popup shows `-1` per pickup; HP visibly rises in subsequent damage exchanges; second dash into the cooler is a no-op (no new drops, visual stays dimmed).
