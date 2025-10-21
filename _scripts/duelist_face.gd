extends Button

var duelist_name : String

#---------------------------------------------------------------------------------------------------
func _ready():
	duelist_name = self.get_name().split("_")[1]
	get_node("visuals/face").texture = load("res://_resources/character_faces/" + duelist_name + "0.png")
	
#	#Only show the duelist button IF the player has fought it in the campaign mode
#	var is_debug = false
#	$visuals.hide()
#	if is_debug or PlayerData.recorded_campaign_defeats.has("campaign_defeat_" + duelist_name.to_upper()) or duelist_name == "shadi":
#		$visuals.show()
#	if duelist_name in ["Nitemare", "Tenma"] and PlayerData.recorded_campaign_defeats.has("campaign_defeat_KAIBA") and PlayerData.recorded_campaign_defeats.has("campaign_defeat_PEGASUS"):
#		$visuals.show()

func _on_duelist_face_button_up():
	# Animate the button click
	if $visuals.is_visible():
		SoundControl.play_sound("poc_decide")

		# Define escalas
		var small_scale := Vector2(0.9, 0.9)
		var normal_scale := Vector2(1, 1)

		# Tween para reduzir o botão
		var tween := create_tween()
		tween.tween_property(self, "scale", small_scale, 0.1)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN_OUT)
		await tween.finished  # espera o tween terminar

		# Tween para restaurar a escala
		var tween_restore := create_tween()
		tween_restore.tween_property(self, "scale", normal_scale, 0.1)\
			.set_trans(Tween.TRANS_LINEAR)\
			.set_ease(Tween.EASE_IN_OUT)
		await tween_restore.finished

		# Chama a função no root
		get_tree().get_root().get_node("free_duel").duelist_face_clicked(duelist_name)
