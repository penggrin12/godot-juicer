class_name ButtonJuicer extends Node

@export var enabled := true

@export_group("Tween Durations", "tween_")
@export var tween_squash_duration := 0.05
@export var tween_duration := 0.3

@export_group("Scale", "scale_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var scale_enabled := true
@export var scale_pressed := 0.9
@export var scale_hovered := 1.15
@export var scale_normal := 1.0

@export_group("Follow Mouse", "fm_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var fm_enabled := true
@export var fm_go_back_strength := 32.0
@export var fm_strength := 16.0
@export var fm_travel_pixels := 8.0

@export_group("Squash", "squash_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var squash_enabled := true
@export var squash_vector := Vector2(0.15, -0.25)

@export_group("Audio", "audio_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var audio_enabled := true
@export var audio_pressed: AudioStream:
	get: return _player.stream
	set(x): _player.stream = x

var _button: BaseButton
var _player := AudioStreamPlayer.new()
var _tw: Tween = null


func _enter_tree() -> void:
	if (_player.owner == null) and (audio_enabled):
		add_child(_player)
	
	_button = get_parent()
	_button.offset_transform_enabled = true
	
	_button.button_down.connect(_tween_to_and_squash)
	_button.button_up.connect(_tween_to_and_squash)
	_button.mouse_entered.connect(_tween_to)
	_button.mouse_exited.connect(_tween_to)
	
	_button.pivot_offset_ratio = Vector2.ONE * 0.5

func _exit_tree() -> void:
	_button.button_down.disconnect(_tween_to_and_squash)
	_button.button_up.disconnect(_tween_to_and_squash)
	_button.mouse_entered.disconnect(_tween_to)
	_button.mouse_exited.disconnect(_tween_to)
	
	_button = null

func _create_tween() -> Tween:
	if _tw != null:
		_tw.kill()
	_tw = create_tween()
	return _tw

func _lerp_position(to: Vector2, delta: float) -> void:
	_button.offset_transform_position = \
		_button.offset_transform_position.lerp(to, delta)

func _process(delta: float) -> void:
	if (_button == null) or (not fm_enabled) or (not enabled):
		return
	if !_button.button_pressed:
		_lerp_position(Vector2.ZERO, delta * fm_go_back_strength)
		return
	
	var travel = _button.get_local_mouse_position() - _button.size / 2
	_lerp_position(travel.normalized() * fm_travel_pixels, delta * fm_strength)

func _get_target_scale() -> float:
	if !scale_enabled:
		return 1.0
	
	if _button.button_pressed:
		return scale_pressed
	if _button.is_hovered():
		return scale_hovered
	return scale_normal

func _tween_to(squash: bool = false) -> void:
	if !enabled:
		return
	
	var target := Vector2.ONE * _get_target_scale()
	
	var tw := _create_tween().set_trans(Tween.TRANS_EXPO)
	if squash_enabled and squash:
		tw.tween_property(_button, "offset_transform_scale", target + squash_vector, tween_squash_duration) \
			.set_ease(Tween.EASE_OUT)
	tw.tween_property(_button, "offset_transform_scale", target, tween_duration) \
		.set_ease(Tween.EASE_OUT)

func _tween_to_and_squash() -> void:
	if !enabled:
		return
	if audio_enabled:
		_player.play()
	_tween_to(true)
