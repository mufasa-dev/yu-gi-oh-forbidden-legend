extends Control

var transparent = Color(0,0,0, 0.1)
var full_black = Color(0,0,0, 1)
var transition_time = 0.8

func _ready():
	$loading_indicator/loading_label.text = GameLanguage.system.loading[PlayerData.game_language] + " . . ."

func entering_this_scene():
	$loading_indicator/loading_label.text = GameLanguage.system.loading[PlayerData.game_language] + " . . ."
	#Play the scene BGM
	var scene_bgm_file = "lohweo_" + self.get_parent().get_name()
	SoundControl.play_sound(scene_bgm_file, "music")
	
	self.show()
	await get_tree().create_timer(transition_time/3).timeout
	$loading_indicator.hide()
	
	var tween := create_tween()
	tween.tween_property($darker_screen, "modulate", full_black, transition_time / 1.5)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	self.hide()

func scene_transition(scene: String) -> void:
	$loading_indicator/loading_label.text = GameLanguage.system.loading[PlayerData.game_language] + " . . ."

	SoundControl.bgm_fadeout()
	SoundControl.play_sound("poc_scene")

	self.show()
	$loading_indicator.show()

	# Tween do "darker_screen" usando Godot 4
	$darker_screen.modulate = transparent  # define valor inicial
	var tween := create_tween()
	tween.tween_property($darker_screen, "modulate", full_black, transition_time / 1.5)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	self.hide()

	# Troca de cena
	get_tree().change_scene_to_file("res://_scenes/" + scene + ".tscn")
