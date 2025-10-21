extends Node

var save_key = "permittedmemories123"

func save_game():
	#Get from 'PlayerData' the info that will be stored in a savefile
	var info_to_save = {
		#Player information
		"player_name"  : PlayerData.player_name, #String
		"player_deck"  : PlayerData.player_deck, #Array
		"player_trunk" : PlayerData.player_trunk, #Dictionary
		"player_starchips" : PlayerData.player_starchips, #Int
		"password_bought_cards" : PlayerData.password_bought_cards, #Array
		"recorded_duels" : PlayerData.recorded_duels, #Dictionary
		"last_reward_cards" : PlayerData.last_reward_cards, #Array
		"list_of_player_decks" : PlayerData.list_of_player_decks, #Dictionary
		"active_deck_name" : PlayerData.active_deck_name, #String
		"registered_freeduel_speed" : PlayerData.registered_freeduel_speed, #Float
		
		#Story Progression information
		"recorded_campaign_defeats" : PlayerData.recorded_campaign_defeats, #Array
		"recorded_dialogs" : PlayerData.recorded_dialogs, #Array
	}
	
	#Start the file to be written
	var save_file := FileAccess.open_encrypted_with_pass("user://savegame.save", FileAccess.WRITE, OS.get_unique_id())
	if save_file == null:
		push_error("Failed to open save file!")
		return "error"

	# Serializa o dicionário como JSON e grava
	var json := JSON.stringify(info_to_save)
	save_file.store_line(json)
	save_file.close()

	return "success"

func load_game() -> String:
	# Verifica se o arquivo existe
	if not FileAccess.file_exists("user://savegame.save"):
		return "no_save"

	# Abre o arquivo criptografado
	var save_file := FileAccess.open_encrypted_with_pass(
		"user://savegame.save",
		FileAccess.READ,
		OS.get_unique_id()
	)
	if save_file == null:
		push_error("Falha ao abrir o save.")
		return "error"

	# Lê o conteúdo
	var json_text := save_file.get_as_text()
	save_file.close()

	# Converte JSON → Dictionary
	var info_to_load: Dictionary = JSON.parse_string(json_text)
	if typeof(info_to_load) != TYPE_DICTIONARY:
		push_error("Save corrompido ou formato inválido.")
		return "error"

	# Lista de chaves esperadas
	var saved_info: Array = [
		["player_name", "string"],
		["player_deck", "array"],
		["player_trunk", "dictionary"],
		["player_starchips", "int"],
		["password_bought_cards", "array"],
		["recorded_duels", "dictionary"],
		["last_reward_cards", "array"],
		["list_of_player_decks", "dictionary"],
		["active_deck_name", "string"],
		["registered_freeduel_speed", "float"],
		["recorded_campaign_defeats", "array"],
		["recorded_dialogs", "array"],
	]

	# Corrige save antigo (sem deck list)
	if not info_to_load.has("list_of_player_decks"):
		info_to_load["list_of_player_decks"] = {
			"01022": {
				"color": "1,1,1,1",
				"deck": info_to_load.get("player_deck", [])
			}
		}
		info_to_load["active_deck_name"] = "01022"

	# Carrega as informações de forma segura
	for entry in saved_info:
		var key: String = entry[0]
		var expected_type: String = entry[1]

		if info_to_load.has(key):
			match expected_type:
				"string":
					PlayerData[key] = str(info_to_load[key])
				"int":
					PlayerData[key] = int(info_to_load[key])
				"float":
					PlayerData[key] = float(info_to_load[key])
				"array":
					PlayerData[key] = Array(info_to_load[key])
				"dictionary":
					PlayerData[key] = Dictionary(info_to_load[key])
		else:
			print("⚠️ savegame não tinha a chave:", key)

	return "success"
