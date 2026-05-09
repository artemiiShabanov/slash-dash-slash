extends Node

## Audio autoload.
##
## Loads a SfxPalette and spawns one AudioStreamPlayer per slot as children.
## Game systems call `Audio.bind_to_player(player_node)` once at the player's
## _ready; this autoload subscribes to all relevant player signals and dispatches
## sounds. Player code stays audio-agnostic.

const PALETTE_PATH := "res://resources/sfx_palette.tres"

var palette: SfxPalette

# One player per slot.
var _player_dash: AudioStreamPlayer
var _player_slash: AudioStreamPlayer
var _player_thunk: AudioStreamPlayer
var _player_splat: AudioStreamPlayer
var _player_clang: AudioStreamPlayer

# ===== Lifecycle =====

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	palette = load(PALETTE_PATH) as SfxPalette
	if palette == null:
		push_error("Audio: failed to load SfxPalette at %s; using defaults." % PALETTE_PATH)
		palette = SfxPalette.new()

	_player_dash = _make_player(palette.dash_whoosh)
	_player_slash = _make_player(palette.slash_swing)
	_player_thunk = _make_player(palette.hit_thunk)
	_player_splat = _make_player(palette.hit_splat)
	_player_clang = _make_player(palette.wall_clang)

func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = palette.master_volume_db
	add_child(p)
	return p

# ===== Public API =====

## Subscribe to a player's signals. Call once from `Player._ready()`.
##
## `weapon_loaded` and `stamina_changed` are intentionally not consumed here —
## visual feedback (body tint, stamina pips) already communicates those states;
## adding audio for them would crowd the mix without adding information.
func bind_to_player(player: Node) -> void:
	if player == null:
		return
	if player.has_signal("dash_started"):
		player.dash_started.connect(_on_dash_started)
	if player.has_signal("weapon_fired"):
		player.weapon_fired.connect(_on_weapon_fired)
	if player.has_signal("hit_landed"):
		player.hit_landed.connect(_on_hit_landed)
	if player.has_signal("wall_hit"):
		player.wall_hit.connect(_on_wall_hit)

# ===== Handlers =====

func _on_dash_started(_dir: Vector2) -> void:
	_play(_player_dash)

func _on_weapon_fired(_dir: Vector2) -> void:
	_play(_player_slash)

func _on_hit_landed(_target: Node, _final_damage: int, _position: Vector2, _dash_direction: Vector2, is_back_hit: bool) -> void:
	if is_back_hit:
		_play(_player_splat)
	else:
		_play(_player_thunk)

func _on_wall_hit(_position: Vector2, _normal: Vector2) -> void:
	_play(_player_clang)

# ===== Internals =====

func _play(p: AudioStreamPlayer) -> void:
	if p == null or p.stream == null:
		return
	p.play()
