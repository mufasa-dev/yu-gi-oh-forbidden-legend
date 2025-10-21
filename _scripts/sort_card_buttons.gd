extends Control

var last_sorted_type = "name" #starts as new, can be changed by clicking on the buttons


#---------------------------------------------------------------------------------------------------
@onready var deck_building_node = get_node("../../")
func _on_byNAME_button_up():
	animate_button_click($HBoxContainer/byNAME)
	var new_sorted_array = sort_cards(PlayerData.player_trunk.keys(), "name")
	last_sorted_type = "name"
	deck_building_node.update_left_panel(new_sorted_array)
	
func _on_byATK_button_up():
	animate_button_click($HBoxContainer/byATK)
	var new_sorted_array = sort_cards(PlayerData.player_trunk.keys(), "atk")
	last_sorted_type = "atk"
	deck_building_node.update_left_panel(new_sorted_array)
	
func _on_byDEF_button_up():
	animate_button_click($HBoxContainer/byDEF)
	var new_sorted_array = sort_cards(PlayerData.player_trunk.keys(), "def")
	last_sorted_type = "def"
	deck_building_node.update_left_panel(new_sorted_array)
	
func _on_byTYPE_button_up():
	animate_button_click($HBoxContainer/byTYPE)
	var new_sorted_array = sort_cards(PlayerData.player_trunk.keys(), "type")
	last_sorted_type = "type"
	deck_building_node.update_left_panel(new_sorted_array)
	
func _on_byATTR_button_up():
	animate_button_click($HBoxContainer/byATTR)
	var new_sorted_array = sort_cards(PlayerData.player_trunk.keys(), "attr")
	last_sorted_type = "attr"
	deck_building_node.update_left_panel(new_sorted_array)

#---------------------------------------------------------------------------------------------------
func compare_cards_name(a, b):
	if(PlayerData.game_language == "pt"):
		return CardList.card_list[a]["card_name_pt"].casecmp_to(CardList.card_list[b]["card_name_pt"]) == -1
	return CardList.card_list[a]["card_name"].casecmp_to(CardList.card_list[b]["card_name"]) == -1

func compare_cards_atk(a, b):
	var type_a = CardList.card_list[a]["attribute"]
	var type_b = CardList.card_list[b]["attribute"]
	
	# Coloca as cartas do tipo "trap" no fim
	if type_a == "trap" and type_b != "trap":
		return false
	elif type_b == "trap" and type_a != "trap":
		return true
	
	# Coloca as cartas do tipo "spell" logo depois
	if type_a == "spell" and type_b != "spell":
		return false
	elif type_b == "spell" and type_a != "spell":
		return true
	elif type_a == "spell" and type_b == "spell":
		var spell_type_a = CardList.card_list[a]["type"]
		var spell_type_b = CardList.card_list[b]["type"]
	
		return spell_type_a < spell_type_b
		
	if(CardList.card_list[a]["atk"] != null && CardList.card_list[b]["atk"] != null):
		if(CardList.card_list[a]["atk"] == CardList.card_list[b]["atk"]): #Se atk igual, ordena por nome
			if(PlayerData.game_language == "pt"):
				return CardList.card_list[a]["card_name_pt"].casecmp_to(CardList.card_list[b]["card_name_pt"]) == -1
			return CardList.card_list[a]["card_name"].casecmp_to(CardList.card_list[b]["card_name"]) == -1
		
		return CardList.card_list[a]["atk"] > CardList.card_list[b]["atk"]
	return false;
	
func compare_cards_def(a, b):
	var type_a = CardList.card_list[a]["attribute"]
	var type_b = CardList.card_list[b]["attribute"]
	
	# Coloca as cartas do tipo "trap" no fim
	if type_a == "trap" and type_b != "trap":
		return false
	elif type_b == "trap" and type_a != "trap":
		return true
	
	# Coloca as cartas do tipo "spell" logo depois
	if type_a == "spell" and type_b != "spell":
		return false
	elif type_b == "spell" and type_a != "spell":
		return true
	elif type_a == "spell" and type_b == "spell":
		var spell_type_a = CardList.card_list[a]["type"]
		var spell_type_b = CardList.card_list[b]["type"]
	
		return spell_type_a < spell_type_b
		
	if(CardList.card_list[a]["def"] != null && CardList.card_list[b]["def"] != null):
		if(CardList.card_list[a]["def"] == CardList.card_list[b]["def"]): #Se atk igual, ordena por nome
			if(PlayerData.game_language == "pt"):
				return CardList.card_list[a]["card_name_pt"].casecmp_to(CardList.card_list[b]["card_name_pt"]) == -1
			return CardList.card_list[a]["card_name"].casecmp_to(CardList.card_list[b]["card_name"]) == -1
		
		return CardList.card_list[a]["def"] > CardList.card_list[b]["def"]
	return false;

func compare_cards_type(a, b):
	var type_a = CardList.card_list[a]["attribute"]
	var type_b = CardList.card_list[b]["attribute"]
	# Coloca as cartas do tipo "trap" no fim
	if type_a == "trap" and type_b != "trap":
		return false
	elif type_b == "trap" and type_a != "trap":
		return true
	
	# Coloca as cartas do tipo "spell" logo depois
	if type_a == "spell" and type_b != "spell":
		return false
	elif type_b == "spell" and type_a != "spell":
		return true
	elif type_a == "spell" and type_b == "spell":
		var spell_type_a = CardList.card_list[a]["type"]
		var spell_type_b = CardList.card_list[b]["type"]
	
		return spell_type_a < spell_type_b
		
	return CardList.card_list[a]["type"].casecmp_to(CardList.card_list[b]["type"]) == -1
	
func compare_cards_attr(a, b):
	var type_a = CardList.card_list[a]["attribute"]
	var type_b = CardList.card_list[b]["attribute"]
	# Coloca as cartas do tipo "trap" no fim
	if type_a == "trap" and type_b != "trap":
		return false
	elif type_b == "trap" and type_a != "trap":
		return true
	
	# Coloca as cartas do tipo "spell" logo depois
	if type_a == "spell" and type_b != "spell":
		return false
	elif type_b == "spell" and type_a != "spell":
		return true
	elif type_a == "spell" and type_b == "spell":
		var spell_type_a = CardList.card_list[a]["type"]
		var spell_type_b = CardList.card_list[b]["type"]
	
		return spell_type_a < spell_type_b
		
	return CardList.card_list[a]["attribute"].casecmp_to(CardList.card_list[b]["attribute"]) == -1
		
func sort_cards(list_of_cards_to_sort, type_of_sort):
	var new_sorted_array = []  # Resultado da lista ordenada a ser passada adiante
	var array_to_be_sorted = list_of_cards_to_sort  # PlayerData.player_trunk.keys()
	var card_ids = CardList.card_list.keys()
	
	match type_of_sort:
		"name":
			card_ids.sort_custom(Callable(self, "compare_cards_name"))
		"atk":
			card_ids.sort_custom(Callable(self, "compare_cards_atk"))
		"def":
			card_ids.sort_custom(Callable(self, "compare_cards_def"))
		"type":
			card_ids.sort_custom(Callable(self, "compare_cards_type"))
		"attr":
			card_ids.sort_custom(Callable(self, "compare_cards_attr"))
		"new":
			card_ids.sort_custom(Callable(self, "compare_cards_name"))
			
	
	for card_id in card_ids:
		if card_id in array_to_be_sorted:
			new_sorted_array.append(card_id)
			
	if(type_of_sort == "new"):
		for i in range(PlayerData.last_reward_cards.size()):
			new_sorted_array.erase(PlayerData.last_reward_cards[i])
			new_sorted_array.push_front(PlayerData.last_reward_cards[i])
					
	return new_sorted_array #returns the correctly sorted array

#---------------------------------------------------------------------------------------------------
func sort_with_duplicates(list_of_cards_to_sort, type_of_sort):
	var stored_initial_list = list_of_cards_to_sort
	
	#Call the initial sort as usual
	var new_sorted_list = sort_cards(list_of_cards_to_sort, type_of_sort)
	
	#Check if any duplicates were left behind and add it back
	if new_sorted_list.size() != stored_initial_list.size():
		for card in new_sorted_list:
			stored_initial_list.erase(card)
		var leftover_cards = stored_initial_list
		
		for card in leftover_cards:
			var index_to_insert = new_sorted_list.find(card)
			new_sorted_list.insert(index_to_insert, card)
	
	return new_sorted_list

#---------------------------------------------------------------------------------------------------
func animate_button_click(button):
	SoundControl.play_sound("poc_decide")
	
	$sortables_tween.interpolate_property(button, "scale", button.scale, Vector2(1.1, 1.1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$sortables_tween.start()
	
	await get_tree().create_timer(0.1).timeout
	
	$sortables_tween.interpolate_property(button, "scale", button.scale, Vector2(1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$sortables_tween.start()
	
	#Set the scroll back to the TOP
	var _set_scroll_0 = get_node("../ScrollContainer").set_v_scroll(0)
