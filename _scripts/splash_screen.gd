extends Node2D

var skip_once := false

func _ready() -> void:
	# Estado inicial
	$scn_logo.modulate = Color(1, 1, 1, 0)
	$godot_shout.modulate = Color(1, 1, 1, 0)
	
	# Fade-in inicial do node principal
	var tween := create_tween()
	self.modulate = Color(1, 1, 1, 0) # valor inicial
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	SoundControl.play_sound("lohweo_game_over", "music")
	await tween.finished
	
	# SCN LETTERS ENTRANDO
	var letter_timer := 0.7

	# Letra S
	var tween_s := create_tween()
	var final_S_pos := Vector2(356, 174)
	$S.position = Vector2(-196, -202) # valor inicial
	SoundControl.play_sound("letra", "sfx")
	tween_s.tween_property($S, "position", final_S_pos, letter_timer)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN_OUT)
	$timer.start(0.4)
	await $timer.timeout

	# Letra C
	var tween_c := create_tween()
	var final_C_pos := Vector2(553, 174)
	$C.position = Vector2(553, -202)
	SoundControl.play_sound("letra", "sfx")
	tween_c.tween_property($C, "position", final_C_pos, letter_timer)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN_OUT)
	$timer.start(0.4)
	await $timer.timeout

	# Letra N
	var tween_n := create_tween()
	var final_N_pos := Vector2(737, 174)
	$N.position = Vector2(1280, -202)
	SoundControl.play_sound("letra", "sfx")
	tween_n.tween_property($N, "position", final_N_pos, letter_timer)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN_OUT)
	$timer.start(0.8)
	await $timer.timeout

	# LOGO fade in
	SoundControl.play_sound("logo", "sfx")
	$canal.modulate = Color(1, 1, 1, 0)
	var tween_logo := create_tween()
	tween_logo.tween_property($canal, "modulate", Color(1, 1, 1, 1), 1)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween_logo.finished

	$timer.start(0.6)
	await $timer.timeout

	# GODOT SHOUT (made with godot)
	SoundControl.play_sound("shout_out", "sfx")
	$godot_shout.modulate = Color(1, 1, 1, 0)
	var tween_godot := create_tween()
	tween_godot.tween_property($godot_shout, "modulate", Color(1, 1, 1, 1), 1)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween_godot.finished

	# Espera antes de trocar de cena
	$timer.start(3.3)
	await $timer.timeout

	skip_once = true
	$scene_transitioner.scene_transition("main_menu")


func _on_SKIP_button_up() -> void:
	if not skip_once:
		skip_once = true
		$scene_transitioner.scene_transition("main_menu")
