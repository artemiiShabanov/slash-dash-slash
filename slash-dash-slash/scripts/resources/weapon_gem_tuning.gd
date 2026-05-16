class_name WeaponGemTuning
extends Resource

## Tunables for weapon-gem proc presentation + per-element effects. Stored at
## `res://resources/weapon_gem_tuning.tres`. Upgrade specs (future) will
## extend / wrap these via per-gem upgrade state — these are the *defaults*.

# ===== Presentation =====

## Seconds the element-color modulate holds on a struck enemy before
## tweening back to white.
@export var proc_flash_duration: float = 0.12

# ===== Fire (burn DoT) =====

@export var fire_burn_duration: float = 3.0
@export var fire_burn_tick_interval: float = 0.5
## Per-tick damage = equipped_sword.base_damage * this.
@export var fire_burn_damage_mult: float = 0.1

# ===== Water (radius + vulnerability) =====

@export var water_radius_bonus: float = 4.0
@export var water_vulnerability_mult: float = 1.25
@export var water_vulnerability_duration: float = 3.0

# ===== Ice (slow stacks) =====

## Per-instance slow fraction in [0, 1]. Stacks sum and cap at 0.95.
@export_range(0.0, 1.0) var ice_slow_pct: float = 0.5
@export var ice_slow_duration: float = 2.0

# ===== Wind (radius multiplier + knockback) =====

@export var wind_radius_mult: float = 1.5
@export var wind_knockback_distance: float = 24.0

# ===== Lightning (stun) =====

@export var lightning_stun_duration: float = 1.0
