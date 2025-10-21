extends Node

func check_for_fusion(card_1 : String, card_2 : String):
	#Initializing variables
	var fusion_result : Array #[ID:String, Extra Info]
	
	#If every check fails, default is to return ID:String and 'Extra Info":null
	var default_result : Array = [card_2, null]
	#Can't return card_2 if it is a Spell and card_1 is a monster. Monster has priority.
	if CardList.card_list[card_2].attribute in ["spell", "trap"] and !(CardList.card_list[card_1].attribute in ["spell", "trap"]):
		default_result = [card_1, null]
	
	#First check if one of the members of the fusion is a Token monster. Those can't be used.
	if CardList.card_list[card_1].card_name == "Token" or CardList.card_list[card_2].card_name == "Token":
		#print("cant fuse with token")
		return default_result #by default Tokens will only be on the field, so they would be card1, returning card2 will always make sense
	
	#Check for equipments, return will be [monster_card_id, [status, value_change]]
	var check_for_equip = equip_fusion(card_1, card_2)
	if check_for_equip != null:
		return check_for_equip
	
	#Check for Specific Fusions, both cards are fixed
	var specific_fusion = specific_fusion(card_1, card_2)
	if specific_fusion[1] != false:
		#Correct so these cards bellow do not result as fusions cards (purple borders)
		var names_to_check = ["Metalmorph", "Level Up!"]
		if CardList.card_list[card_1].card_name in names_to_check or CardList.card_list[card_2].card_name in names_to_check:
			specific_fusion[1] = false #set this to false so Fusion Type isn't set by game_logic
			
		return specific_fusion
	
	#Check for Attribute Fusions, these are way more rare, so should be prioritized
	var attribute_fusion = attribute_fusion(card_1, card_2)
	if attribute_fusion[1] != false:
		return attribute_fusion
	
	#Implement tuner here
	
	#Check for Special Fusions, only one card restricted, and it's gotta be specific
	var special_fusion = special_fusion(card_1, card_2)
	if special_fusion[1] != false:
		#Correct so these cards bellow do not result as fusions cards (purple borders)
		var names_to_check = ["Metalmorph", "Level Up!"]
		if CardList.card_list[card_1].card_name in names_to_check or CardList.card_list[card_2].card_name in names_to_check:
			special_fusion[1] = false #set this to false so Fusion Type isn't set by game_logic
			
		return special_fusion
	
	#Check for Generic Fusions, classic forbidden memories kind of fusion between types
	var generic_fusion = generic_fusion(card_1, card_2)
	if generic_fusion[1] != false:
		return generic_fusion
	
	#If every check fail, Return [ID:String, Extra Info], whatever it is
	fusion_result = default_result
	return fusion_result 

#-------------------------------------------------------------------------------
#Fusion type checks are ordered by priority
func equip_fusion(card_1 : String, card_2 : String):
	var equip_result : Array
	equip_result = [card_2, false]
	
	#Check if at least one of the cards is a equip
	var card_1_type : String = CardList.card_list[card_1].type
	var card_2_type : String = CardList.card_list[card_2].type
	if !([card_1_type, card_2_type].has("equip")):
		return null #if there is no "equip" involved in this fusion, fail the check for 'equip_fusion'
	
	#Define which card is the monster, which card is the equip
	var monster_card_id = null
	var equip_card_id = null
	if card_1_type != "equip" and !(CardList.card_list[card_1].attribute in ["spell", "trap"]):
		monster_card_id = card_1
		equip_card_id = card_2
	if card_2_type != "equip" and !(CardList.card_list[card_2].attribute in ["spell", "trap"]):
		monster_card_id = card_2
		equip_card_id = card_1
	if monster_card_id == null:
		return equip_result #if there is no monster involved in this fusion, fail the check for 'equip_fusion'
	if equip_card_id == null:
		return equip_result #for safety
	
	#There is a Equip card and a Monster card, check if they're compatible
	var attributes : Array = ["dark", "light", "water", "fire", "earth", "wind"]
	var types : Array = ["aqua", "beast", "beast-warrior", "dinosaur", "dragon", "fairy", "fiend", "fish", "insect", "machine", "plant",
				 "pyro", "reptile", "rock", "sea serpent", "spellcaster", "thunder", "warrior", "winged beast", "zombie"]
	var secondary_types : Array = ["harpie", "crystal"]
	
	var equip_restriction : String = CardList.card_list[equip_card_id].effect[2]
	if equip_restriction in attributes and CardList.card_list[monster_card_id].attribute == equip_restriction:
		equip_result = [monster_card_id, [CardList.card_list[equip_card_id].effect[0], CardList.card_list[equip_card_id].effect[1]] ]
	elif equip_restriction in types and CardList.card_list[monster_card_id].type == equip_restriction:
		equip_result = [monster_card_id, [CardList.card_list[equip_card_id].effect[0], CardList.card_list[equip_card_id].effect[1]] ]
	elif equip_restriction in secondary_types and CardList.card_list[monster_card_id].count_as == equip_restriction:
		equip_result = [monster_card_id, [CardList.card_list[equip_card_id].effect[0], CardList.card_list[equip_card_id].effect[1]] ]
	elif equip_restriction == "any":
		equip_result = [monster_card_id, [CardList.card_list[equip_card_id].effect[0], CardList.card_list[equip_card_id].effect[1]] ]
	elif equip_restriction == "special_case": #MAGE POWER, count spelltraps on callers field and give stats of 500 times that
		var spelltrap_count_on_field = 0.00000000001
		var spell_caller = "player"
		if get_node("../").GAME_PHASE != "checking_for_fusions":
			spell_caller = "enemy"
		var target_side_of_field = get_node("../").get_parent().get_node("duel_field/" + spell_caller + "_side_zones")
		for i in range(5):
			var card_being_checked = target_side_of_field.get_node("spelltrap_" + String(i))
			if card_being_checked.is_visible():
				spelltrap_count_on_field += 1
		
		equip_result = [monster_card_id, [CardList.card_list[equip_card_id].effect[0], CardList.card_list[equip_card_id].effect[1] * spelltrap_count_on_field] ]
	else:
		#print("fusions.gd failed to equip: restriction = ", equip_restriction)
		var special_check_is_ritual = equip_card_id == "00991"
		equip_result = [monster_card_id, ["stats_up", 0, "equipment failed"], special_check_is_ritual] #if equip fail, add 0 to stats. Failsafe.
	
	return equip_result #[monster_card_id, [status, value_change]]

#-------------------------------------------------------------------------------
#Specific Card + Specific Card
func specific_fusion(card_1 : String, card_2 : String):
	var fusion_result : Array
	
	#Some fusions that use the same monsters, but in different orders, can skip the sorting process
	var dont_sort = false
	if card_1 in ["01148", "01149"] and card_2 in ["01148", "01149"]: #Roboyarou, Robolady
		dont_sort = true
	
	var specific_string_to_check = card_1 + "_" + card_2
	if dont_sort == false:
		var ordered_ids = [card_1, card_2] #sort in ascending numerical order because I check for it like that
		ordered_ids.sort()
		specific_string_to_check = ordered_ids[0] + "_" + ordered_ids[1]
	
	if specific_fusion_list.keys().has(specific_string_to_check):
		fusion_result = [specific_fusion_list[specific_string_to_check], true]
	else:
		fusion_result = [card_2, false]
	
	return fusion_result #[monster_card_id, is_fusion_success]

#-------------------------------------------------------------------------------
#Specific Keyworded Card + Attribute that matches it
func attribute_fusion(card_1 : String, card_2 : String):
	var fusion_result : Array
	
	#Cards with these keywords on it's name will have attribute fusions
	var card_name_keywords = ["Mask Change", "Elemental HERO", "Destiny HERO", "Gem-Knight", "Dharc", "Lyna", "Aussa", "Hiita", "Eria", "Wynn"]
	
	#Check if Card_1 or Card_2 has a Keyword on it's name
	var attribute_holder : String
	var attribute_matcher : String
	var keyword_found = null
	for i in range(card_name_keywords.size()):
		if CardList.card_list[card_1].card_name.findn(card_name_keywords[i]) != -1:
			attribute_holder = card_1
			attribute_matcher = card_2
			keyword_found = card_name_keywords[i]
			break
		elif CardList.card_list[card_2].card_name.findn(card_name_keywords[i]) != -1:
			attribute_holder = card_2
			attribute_matcher = card_1
			keyword_found = card_name_keywords[i]
			break
	
	#If Card_1 or Card_2 HAS a keyword on it's name, check if the other card's attribute matches what it needs
	if keyword_found != null:
		#Special check so Mask Change can only work with Elemental HEROs
		if keyword_found == "Mask Change":
			#print(CardList.card_list[attribute_matcher].card_name)
			if CardList.card_list[attribute_matcher].card_name.find("HERO") == -1:
				return [card_2, false] #return a failed fusion
		
		#If there is a Keyword : Attribute found, look inside 'Keyword : Attribute' for the first result with atk > than both the materials used
		if attribute_fusion_list[keyword_found].has(CardList.card_list[attribute_matcher].attribute):
			var keyword_attribute_results_array = attribute_fusion_list[keyword_found][CardList.card_list[attribute_matcher].attribute]
			var holder_atk = CardList.card_list[attribute_holder].atk
			var match_atk = CardList.card_list[attribute_matcher].atk
			if CardList.card_list[attribute_holder].attribute in ["spell", "trap"]: holder_atk = 0 #safeguard for cards like Mask Change
			
			for i in range(keyword_attribute_results_array.size()):
				if holder_atk < CardList.card_list[keyword_attribute_results_array[i]].atk and match_atk < CardList.card_list[keyword_attribute_results_array[i]].atk:
					fusion_result = [keyword_attribute_results_array[i], true] #[ID:STRING, Success = true]
					return fusion_result
	
	fusion_result = [card_2, false] #failsafe result for failed fusion. Return second card and success = false
	return fusion_result #[monster_card_id, is_fusion_success]

#-------------------------------------------------------------------------------
#func tuner_fusion(card_1, card_2):
	#pass #not implemented yet

#-------------------------------------------------------------------------------
#Specific card + generic types
func special_fusion(card_1 : String, card_2 : String):
	var fusion_result : Array
	#Test both ways of combining cards, 1 has priority as always
	var test_1_2 : Array = [card_1, CardList.card_list[card_2].type]
	var test_2_1 : Array = [card_2, CardList.card_list[card_1].type]
	
	for test in [test_1_2, test_2_1]:
		if test[0] in special_fusion_list.keys(): #card_1 has special fusions to do?
			if test[1] in special_fusion_list[test[0]]: #card_2 has a matching type to it?
				#Look for the first result with atk > than both the materials used
				for i in range(special_fusion_list[test[0]][test[1]].size()):
					var card_1_atk = CardList.card_list[card_1].atk
					var card_2_atk = CardList.card_list[card_2].atk
					if CardList.card_list[card_1].attribute in ["spell", "trap"]: card_1_atk = 0 #safeguard for cards like Level Up
					if CardList.card_list[card_2].attribute in ["spell", "trap"]: card_2_atk = 0 #safeguard for cards like Level Up
					var resulting_fusion_id = special_fusion_list[test[0]][test[1]][i]
					
					if card_1_atk < CardList.card_list[resulting_fusion_id].atk and card_2_atk < CardList.card_list[resulting_fusion_id].atk:
						fusion_result = [resulting_fusion_id, true] #[ID:STRING, Success = true]
						return fusion_result
	
	fusion_result = [card_2, false] #failsafe result for failed fusion. Return second card and success = false
	return fusion_result #[monster_card_id, is_fusion_success]

#-------------------------------------------------------------------------------
#Generic Type + Generic Type
func generic_fusion(card_1: String, card_2 : String):
	var fusion_result : Array
	#Define main types used for fusion
	var card_1_type = CardList.card_list[card_1].type
	var card_2_type = CardList.card_list[card_2].type
	
	#If aplicable, define count_as types for fusion
	var card_1_count_as = ""
	if CardList.card_list[card_1].count_as != null:
		card_1_count_as = CardList.card_list[card_1].count_as
	var card_2_count_as = ""
	if CardList.card_list[card_2].count_as != null:
		card_2_count_as = CardList.card_list[card_2].count_as
	
	#Priority of fusion should be 1a_2a, 1a_2b, 1b_2a, 1b_2b then 2a_1a, 2a_1b, 2b_1a, 2b_1b
	#NOTE: this has to be sorted in alphabetical order to do proper checks, so there will be redundancies
	var check_fusion_combinations = [alphabetically_sorted_types(card_1_type, card_2_type),
									 alphabetically_sorted_types(card_1_type, card_2_count_as),
									 alphabetically_sorted_types(card_1_count_as, card_2_type),
									 alphabetically_sorted_types(card_1_count_as, card_2_count_as),
									 #alphabetically_sorted_types(card_2_type, card_1_type),         #REDUNDANT
									 #alphabetically_sorted_types(card_2_type, card_1_count_as),     #REDUNDANT
									 #alphabetically_sorted_types(card_2_count_as, card_1_type),     #REDUNDANT
									 #alphabetically_sorted_types(card_2_count_as, card_1_count_as), #REDUNDANT
									 ]
	
	for combination in check_fusion_combinations:
		if generic_fusion_list.keys().has(combination):
			#Look for the first result with atk > than both the materials used
			for i in range(generic_fusion_list[combination].size()):
				var card_1_atk = CardList.card_list[card_1].atk
				var card_2_atk = CardList.card_list[card_2].atk
				var resulting_fusion_id = generic_fusion_list[combination][i]
				
				if card_1_atk < CardList.card_list[resulting_fusion_id].atk and card_2_atk < CardList.card_list[resulting_fusion_id].atk:
					fusion_result = [resulting_fusion_id, true] #[ID:STRING, Success = true]
					return fusion_result
				if CardList.card_list[resulting_fusion_id].atk == 0:
					fusion_result = [resulting_fusion_id, true] #[ID:STRING, Success = true]
					return fusion_result
	
	fusion_result = [card_2, false] #failsafe result for failed fusion. Return second card and success = false
	return fusion_result #[monster_card_id, is_fusion_success]

func alphabetically_sorted_types(type_1 : String, type_2 : String):
	var to_sort : Array = [type_1, type_2]
	to_sort.sort()
	return to_sort[0] + "_" + to_sort[1]

#-------------------------------------------------------------------------------
# LIST OF THE FUSION RESULTS
#-------------------------------------------------------------------------------

#Fusions between specific card with specific card
var specific_fusion_list = {
	"00069_00070" : "00068",                                                        #Battle Ox + Mystic Horseman = Rabid Horseman
	"00072_00073" : "00071",                                                        #Summoned Skull + Red-Eyes Black Dragon = Black Skull Dragon
	"00072_00159" : "00071",                                                        #Summoned Skull + Red-Eyes Black Metal Dragon = Black Skull Dragon
	"00072_00628" : "00071",                                                        #Summoned Skull + Red-Eyes Darkness Metal Dragon = Black Skull Dragon
	"00072_00643" : "00071",                                                        #Summoned Skull + Red-Eyes Black Flare Dragon = Black Skull Dragon
	"00072_00645" : "00071",                                                        #Summoned Skull + Red-Eyes Darkness Dragon  = Black Skull Dragon
	"00072_00646" : "00071",                                                        #Summoned Skull + Red-Eyes Zombie Dragon = Black Skull Dragon	
	"00073_00075" : "00074",                                                        #Red-Eyes Black Dragon + Meteor Dragon = Meteor Black Dragon
	"00071_00075" : "00074",                                                        #Black Skull Dragon + Meteor Dragon = Meteor Black Dragon
	"00075_00159" : "00074",                                                        #Meteor Dragon + Red-Eyes Black Metal Dragon = Meteor Black Dragon
	"00075_00628" : "00074",                                                        #Meteor Dragon + Red-Eyes Darkness Metal Dragon = Meteor Black Dragon
	"00075_00643" : "00074",                                                        #Meteor Dragon + Red-Eyes Black Flare Dragon = Meteor Black Dragon
	"00075_00645" : "00074",                                                        #Meteor Dragon + Red-Eyes Darkness Dragon = Meteor Black Dragon
	"00075_00646" : "00074",                                                        #Meteor Dragon + Red-Eyes Zombie Dragon = Meteor Black Dragon
	"00078_00080" : "00079",                                                        #Time Wizard + Dark Magician = Dark Sage
	"00080_00644" : "00079",                                                        #Time Wizard of Tomorrow + Dark Magician = Dark Sage
	"00127_00128" : "00007",                                                        #Rhaimundos of the Red Sword + Fireyarou = Vermillion Sparrow
	"00011_00131" : "00154",                                                        #The Snake Hair + Dragon Zombie = Great Mammoth of Goldfine
	"00131_00132" : "00012",                                                        #The Snake Hair + Blackland Fire Dragon = Skelgon
	"00134_00135" : "00133",                                                        #Petit Angel + Mystical Sheep #2 = Fusionist
	"00137_00138" : "00025",                                                        #Water Magician + Behegon = Marine Beast
	"00139_00141" : "00027",                                                        #Tyhone + Wings of Wicked Flame = Mavelus
	"00147_00148" : "00045",                                                        #Ocubeam + Mega Thunderball = Kaminari Attack
	"00184_00185" : "00187",                                                        #X-Head Cannon + Y-Dragon Head = XY-Dragon Cannon
	"00184_00186" : "00189",                                                        #X-Head Cannon + Z-Metal Tank = XZ-Tank Cannon
	"00185_00186" : "00188",                                                        #Y-Dragon Head + Z-Metal Tank = YZ-Tank Dragon
	"00186_00187" : "00190",                                                        #Z-Metal Tank + XY-Dragon Cannon = XYZ-Dragon Cannon
	"00184_00188" : "00190",                                                        #X-Head Cannon + YZ-Tank Dragon = XYZ-Dragon Cannon
	"00185_00189" : "00190",                                                        #Y-Dragon Head + XZ-Tank Cannon = XYZ-Dragon Cannon
	"00191_00192" : "00193",                                                        #V-Tiger Jet + W-Wing Catapult = VW-Tiger Catapult
	"00190_00193" : "00194",                                                        #XYZ-Dragon Cannon + VW-Tiger Catapult = VWXYZ-Dragon Catapult Cannon
	"00165_00194" : "00195",                                                        #VWXYZ-Dragon Catapult Cannon + Armed Dragon LV7 = Armed Dragon Catapult Cannon
	"00166_00194" : "00195",                                                        #VWXYZ-Dragon Catapult Cannon + Armed Dragon LV10 = Armed Dragon Catapult Cannon
	"00217_00218" : "00080",                                                        #Magician's Rod + Magician's Robe = Dark Magician
	"00080_00231" : "00234",                                                        #Dark Magician + Dark Magician Girl = The Dark Magicians
	"00080_00235" : "00236",                                                        #Dark Magician + Buster Blader = Dark Paladin
	"00006_00080" : "00433",                                                        #Flame Swordsman + Dark Magician = Dark Flare Knight
	"00073_00080" : "00238",                                                        #Red-Eyes Black Dragon + Dark Magician = Red-Eyes Dark Dragoon
	"00080_00628" : "00238",                                                        #Red-Eyes Darkness Metal Dragon + Dark Magician = Red-Eyes Dark Dragoon
	"00080_00643" : "00238",                                                        #Red-Eyes Black Flare Dragon + Dark Magician = Red-Eyes Dark Dragoon
	"00080_00645" : "00238",                                                        #Red-Eyes Darkness Dragon + Dark Magician = Red-Eyes Dark Dragoon
	"00080_00646" : "00238",                                                        #Red-Eyes Zombie Dragon + Dark Magician = Red-Eyes Dark Dragoon
	"00240_00240" : "00241",                                                        #Blue-Eyes White Dragon + Blue-Eyes White Dragon = Blue-Eyes Twin Burst Dragon
	"00240_00241" : "00242",                                                        #Blue-Eyes White Dragon + Blue-Eyes Twin Burst Dragon = Blue-Eyes Ultimate Dragon
	"00242_00426" : "01051",                                                        #Blue-Eyes Ultimate Dragon + Black Luster Soldier = Dragon Master Knight
	"00077_00339" : "00340",                                                        #Baby Dragon + Alligator's Sword = Alligator's Sword Dragon
	"00088_00152" : "00381",                                                        #Two-Headed King Rex + Crawling Dragon #2 = Bracchio-raidus
	"00383_00383" : "00384",                                                        #Black Tyranno + Black Tyranno = Ultimate Tyranno
	"00379_00379" : "00380",                                                        #Cyber Dinosaur + Cyber Dinosaur = Super Conductor Tyranno
	"00386_00387" : "00363",                                                        #Oxygeddon + Hydrogeddon = Water Dragon
	"00078_00079" : "00425",                                                        #Time Wizard + Dark Sage = Sorcerer of Dark Magic
	"00080_00426" : "00427",                                                        #Dark Magician + Black Luster Soldier = Dark Master of Chaos
	"00442_00443" : "00434",                                                        #Gazelle the King of Mythical Beasts + Berfomet = Chimera the Flying Mythical Beast
	"00441_00441" : "00461",                                                        #Kuriboh + Kuriboh = Kuribandit
	"00441_00461" : "00460",                                                        #Kuriboh + Kuribandit = Kuribabylon
	"00463_00464" : "00426",                                                        #Beginning Knight + Evening Twilight Knight = Black Luster Soldier
	"00033_00034" : "00493",                                                        #Thunder Dragon + Twin-headed Thunder Dragon = Thunder Dragon Titan
	"00523_00523" : "00500",                                                        #Luster Dragon + Luster Dragon = Luster Dragon #2
	"00322_00337" : "00513",                                                        #Lord of the Lamp + Mystic Lamp = La Jinn the Mystical Genie of the Lamp
	"00556_00598" : "00558",                                                        #Relinquished + Thousand-Eyes Idol = Thousand-Eyes Restrict
	"00672_00673" : "00670",                                                        #M-Warrior #1 + M-Warrior #2 = Karbonala Warrior
	"00722_00724" : "00728",                                                        #Elemental HERO Wildheart + Elemental HERO Necroshade = Elemental HERO Necroid Shaman
	"00714_00722" : "00729",                                                        #Elemental HERO Avian + Elemental HERO Wildheart = Elemental HERO Wild Wingman
	"00714_00718" : "00730",                                                        #Elemental HERO Avian + Elemental HERO Bubbleman = Elemental HERO Mariner
	"00715_00718" : "00731",                                                        #Elemental HERO Burstinatrix + Elemental HERO Bubbleman = Elemental HERO Steam Healer
	"00717_00724" : "00745",                                                        #Elemental HERO Sparkman + Elemental HERO Necroshade = Elemental HERO Darkbright
	"00742_00743" : "00746",                                                        #Elemental HERO Heat + Elemental HERO Lady Heat = Elemental HERO Inferno
	"00715_00716" : "00747",                                                        #Elemental HERO Burstinatrix + Elemental HERO Clayman = Elemental HERO Rampart Blaster
	"00714_00715" : "00748",                                                        #Elemental HERO Avian + Elemental HERO Burstinatrix = Elemental HERO Flame Wingman
	"00739_00740" : "00696",                                                        #Elemental HERO Ocean + Elemental HERO Woodsman = Elemental HERO Terra Firma
	"00716_00717" : "00697",                                                        #Elemental HERO Clayman + Elemental HERO Sparkman = Elemental HERO Thunder Giant
	"00716_00718" : "00698",                                                        #Elemental HERO Clayman + Elemental HERO Bubbleman = Elemental HERO Mudballman
	"00717_00748" : "00699",                                                        #Elemental HERO Sparkman + Elemental HERO Flame Wingman = Elemental HERO Shining Flare Wingman
	"00700_00722" : "00701",                                                        #Elemental HERO Bladedge + Elemental HERO Wildheart = Elemental HERO Wildedge
	"00700_00717" : "00702",                                                        #Elemental HERO Bladedge + Elemental HERO Sparkman = Elemental HERO Plasma Vice
	"00703_00732" : "00704",                                                        #Elemental HERO Neos + Neo-Spacian Air Hummingbird = Elemental HERO Air Neos
	"00703_00733" : "00705",                                                        #Elemental HERO Neos + Neo-Spacian Flare Scarab = Elemental HERO Flare Neos
	"00703_00734" : "00706",                                                        #Elemental HERO Neos + Neo-Spacian Grand Mole = Elemental HERO Grand Neos
	"00703_00735" : "00707",                                                        #Elemental HERO Neos + Neo-Spacian Glow Moss = Elemental HERO Glow Neos
	"00703_00736" : "00708",                                                        #Elemental HERO Neos + Neo-Spacian Aqua Dolphin = Elemental HERO Aqua Neos
	"00703_00737" : "00709",                                                        #Elemental HERO Neos + Neo-Spacian Dark Panther = Elemental HERO Dark Neos
	"00698_00748" : "00687",                                                        #Elemental HERO Mudballman + Elemental HERO Flame Wingman = Elemental HERO Electrum
	"00707_00737" : "00686",                                                        #Elemental HERO Glow Neos + Neo-Spacian Dark Panther = Elemental HERO Chaos Neos
	"00709_00735" : "00686",                                                        #Elemental HERO Dark Neos + Neo-Spacian Glow Moss = Elemental HERO Chaos Neos
	"00709_00734" : "00685",                                                        #Elemental HERO Dark Neos + Neo-Spacian Grand Mole = Elemental HERO Nebula Neos
	"00706_00737" : "00685",                                                        #Elemental HERO Grand Neos + Neo-Spacian Dark Panther = Elemental HERO Nebula Neos
	"00705_00734" : "00684",                                                        #Elemental HERO Flare Neos + Neo-Spacian Grand Mole = Elemental HERO Magma Neos
	"00706_00733" : "00684",                                                        #Elemental HERO Grand Neos + Neo-Spacian Flare Scarab = Elemental HERO Magma Neos
	"00704_00736" : "00772",                                                        #Elemental HERO Air Neos + Neo-Spacian Aqua Dolphin = Elemental HERO Storm Neos
	"00708_00732" : "00772",                                                        #Elemental HERO Aqua Neos + Neo-Spacian Air Hummingbird = Elemental HERO Storm Neos
	"00733_00772" : "00683",                                                        #Elemental HERO Storm Neos + Neo-Spacian Flare Scarab = Elemental HERO Cosmo Neos
	"00734_00772" : "00683",                                                        #Elemental HERO Storm Neos + Neo-Spacian Grand Mole = Elemental HERO Cosmo Neos
	"00735_00772" : "00683",                                                        #Elemental HERO Storm Neos + Neo-Spacian Glow Moss = Elemental HERO Cosmo Neos
	"00737_00772" : "00683",                                                        #Elemental HERO Storm Neos + Neo-Spacian Dark Panther = Elemental HERO Cosmo Neos
	"00684_00732" : "00683",                                                        #Elemental HERO Magma Neos + Neo-Spacian Air Hummingbird = Elemental HERO Cosmo Neos
	"00684_00735" : "00683",                                                        #Elemental HERO Magma Neos + Neo-Spacian Glow Moss = Elemental HERO Cosmo Neos
	"00684_00736" : "00683",                                                        #Elemental HERO Magma Neos + Neo-Spacian Aqua Dolphin = Elemental HERO Cosmo Neos
	"00684_00737" : "00683",                                                        #Elemental HERO Magma Neos + Neo-Spacian Dark Panther = Elemental HERO Cosmo Neos
	"00685_00732" : "00683",                                                        #Elemental HERO Nebula Neos + Neo-Spacian Air Hummingbird = Elemental HERO Cosmo Neos
	"00685_00733" : "00683",                                                        #Elemental HERO Nebula Neos + Neo-Spacian Flare Scarab = Elemental HERO Cosmo Neos
	"00685_00735" : "00683",                                                        #Elemental HERO Nebula Neos + Neo-Spacian Glow Moss = Elemental HERO Cosmo Neos
	"00685_00736" : "00683",                                                        #Elemental HERO Nebula Neos + Neo-Spacian Aqua Dolphin = Elemental HERO Cosmo Neos
	"00686_00732" : "00683",                                                        #Elemental HERO Chaos Neos + Neo-Spacian Air Hummingbird = Elemental HERO Cosmo Neos
	"00686_00733" : "00683",                                                        #Elemental HERO Chaos Neos + Neo-Spacian Flare Scarab = Elemental HERO Cosmo Neos
	"00686_00734" : "00683",                                                        #Elemental HERO Chaos Neos + Neo-Spacian Grand Mole = Elemental HERO Cosmo Neos
	"00686_00736" : "00683",                                                        #Elemental HERO Chaos Neos + Neo-Spacian Aqua Dolphin = Elemental HERO Cosmo Neos
	"00827_00833" : "00819",                                                        #Steamroid + Drillroid = Super Vehicroid Jumbo Drill
	"00833_00846" : "00819",                                                        #Steamroid + Submarineroid = Super Vehicroid Jumbo Drill
	"00827_00846" : "00819",                                                        #Drillroid + Submarineroid = Super Vehicroid Jumbo Drill
	"00380_00384" : "00855",                                                        #Ultimate Tyranno + Super Conductor Tyranno = Ultimate Conductor Tyranno
	"00884_00893" : "00883",                                                        #Cyber End Dragon + Cyberdark Dragon = Cyberdark End Dragon
	"00823_00823" : "00886",                                                        #Cyber Dragon + Cyber Dragon = Cyber Twin Dragon
	"00823_00886" : "00884",                                                        #Cyber Dragon + Cyber Twin Dragon = Cyber End Dragon
	"00897_00897" : "00896",                                                        #Cyber Ogre + Cyber Ogre = Cyber Ogre 2
	"00078_00963" : "00949",                                                        #Time Wizard + Mystic Baby Dragon = Mystic Dragon
	"00644_00963" : "00949",                                                        #Time Wizard of Tomorrow + Mystic Baby Dragon = Mystic Dragon
	"00078_01003" : "00981",                                                        #Time Wizard + Snow Dragon = Snowdust Dragon
	"00644_01003" : "00981",                                                        #Time Wizard of Tomorrow + Snow Dragon = Snowdust Dragon
	"00992_00995" : "00985",                                                        #Etoile Cyber + Blade Skater = Cyber Blader
	"00699_00703" : "01054",                                                        #Elemental HERO Shining Flare Wingman + Elemental HERO Neos = Elemental HERO Shining Neos Wingman
	"00703_00748" : "01054",                                                        #Elemental HERO Flame Wingman + Elemental HERO Neos = Elemental HERO Shining Neos Wingman
	"01148_01149" : "01178",                                                        #Robolady + Roboyarou = Super Robolady
	"01149_01148" : "01177",                                                        #Roboyarou + Robolady = Super Roboyarou
	"01197_01197" : "01174",                                                        #Combo Fighter + Combo Fighter = Combo Master
	"01191_01192" : "01245",                                                        #Lava Battleguard + Swamp Battleguard = Battleguard King
	"01164_01165" : "01157",                                                        #The Earl of Demise + Headless Knight = The Duke of Demise
	"00641_01224" : "01206",                                                        #Maximum Six + Dicelops = Orgoth the Relentless
	"00078_01319" : "01311",                                                        #Time Wizard + Codarus = Levia Dragon Daedalus
	"00078_01311" : "01309",                                                        #Time Wizard + Levia Dragon Daedalus = Neo Daedalus
	"00078_01339" : "01310",                                                        #Time Wizard + Legendary Atlantean Tridon = Poseidra, the Atlantean Dragon
	"00058_00440" : "00982",                                                        #Dark Elf + Mystical Elf = Cosmo Queen
	"00129_00129" : "01380",                                                        #Skull Servant + Skull Servant = Wightbaking
	"00129_01380" : "01364",                                                        #Skull Servant + Wightbaking = King of the Skull Servants
	"01381_01381" : "01367",                                                        #Wightprincess + Wightprincess = The Lady in Wight
	"01399_01412" : "01398",                                                        #Beast King Barbaros + Machine Lord Ur = Beast Machine King Barbaros Ur
	"01045_01047" : "01418",                                                        #Sanga of the Thunder + Kazejin = Gate Guardian of Thunder and Wind
	"01045_01046" : "01419",                                                        #Sanga of the Thunder + Suijin = Gate Guardian of Water and Thunder
	"01046_01047" : "01420",                                                        #Suijin + Kazejin = Gate Guardian of Wind and Water
	"01045_01420" : "01042",                                                        #Sanga of the Thunder + Gate Guardian of Wind and Water = Gate Guardian
	"01046_01418" : "01042",                                                        #Suijin + Gate Guardian of Thunder and Wind = Gate Guardian
	"01047_01419" : "01042",                                                        #Kazejin + Gate Guardian of Water and Thunder = Gate Guardian
	"00190_01430" : "01429",                                                        #XYZ-Dragon Cannon + ABC-Dragon Buster = A-to-Z Dragon Buster Cannon
	"01439_01440" : "01441",                                                        #Soul Tiger + Decayed Commander = Zombie Tiger
	"00424_01447" : "01446",                                                        #Valkyrion the Magna Warrior + Berserkion the Electromagna Warrior = Imperion Magnum the Superconductive Battlebot
	"01462_01463" : "01447",                                                        #Delta the Magnet Warrior + Epsilon the Magnet Warrior = Berserkion the Electromagna Warrior
	"01458_01458" : "00498",                                                        #Carboneddon + Carboneddon = Hyozanryu
	"00498_01458" : "01450",                                                        #Hyozanryu + Carboneddon = Diamond Head Dragon
	"00498_00498" : "01450",                                                        #Hyozanryu + Hyozanryu = Diamond Head Dragon
	"01373_01467" : "01365",                                                        #Gozuki + Mezuki = Ushi Oni
	"00849_00849" : "00850",                                                        #Bokoichi the Freightening Car + Bokoichi the Freightening Car = Dekoichi the Battlechanted Locomotive
	"00643_01497" : "01490",                                                        #Red-Eyes Black Flare Dragon + Black Metal Dragon = Red-Eyes Flare Metal Dragon
	"00073_01497" : "01490",                                                        #Red-Eyes Black Dragon + Black Metal Dragon = Red-Eyes Flare Metal Dragon
	"01503_01509" : "01504",                                                        #Destiny HERO - Dogma + Destiny HERO - Plasma = Destiny End Dragoon
	"00703_00775" : "00681",                                                        #Elemental HERO Neos + Rainbow Dragon = Rainbow Neos
	
	#Fang of Critias
	"00240_00506" : "00483",                                                        #Fang of Critias + Blue-Eyes White Dragon = Blue-Eyes Tyrant Dragon
	"00244_00506" : "00483",                                                        #Fang of Critias + Dragon Spirit of White = Blue-Eyes Tyrant Dragon
	"00429_00506" : "00484",                                                        #Fang of Critias + Mirror Force = Mirror Force Dragon
	"00496_00506" : "00494",                                                        #Fang of Critias + Crush Card Virus = Doom Virus Dragon
	"00497_00506" : "00495",                                                        #Fang of Critias + Ring of Destruction = Destruction Dragon
	
	#Metalmorph
	"00143_00155" : "00142",                                                        #Metalmorph + Rock Ogre Grotto #1 = Steel Ogre Grotto #1
	"00145_00155" : "00144",                                                        #Metalmorph + Rock Ogre Grotto #2 = Steel Ogre Grotto #2
	"00155_00158" : "00157",                                                        #Metalmorph + Zoa = Metalzoa
	"00073_00155" : "00159",                                                        #Metalmorph + Red-Eyes Black Dragon = Red-Eyes Black Metal Dragon
	"00155_00643" : "00159",                                                        #Metalmorph + Red-Eyes Black Flare Dragon  = Red-Eyes Black Metal Dragon
	"00155_00646" : "00159",                                                        #Metalmorph + Red-Eyes Zombie Dragon  = Red-Eyes Black Metal Dragon
	"00155_00161" : "00160",                                                        #Metalmorph + Jirai Gumo = Launcher Spider
	"00000_00155" : "00156",                                                        #Metalmorph + Shiny Black "C" Squadder = Super Armored Robot Armed Black Iron "C"
	"00155_00339" : "00341",                                                        #Metalmorph + Alligator's Sword = Cyber-Tech Alligator
	"00155_00340" : "00341",                                                        #Metalmorph + Alligator's Sword Dragon = Cyber-Tech Alligator
	"00155_00577" : "00341",                                                        #Metalmorph + Toon Alligator = Cyber-Tech Alligator
	"00155_00379" : "00380",                                                        #Metalmorph + Cyber Dinosaur = Super Conductor Tyranno
	"00155_00574" : "00575",                                                        #Metalmorph + Cannon Soldier = Cannon Soldier MK-2
	"00155_00645" : "00628",                                                        #Metalmorph + Red-Eyes Darkness Dragon = Red-Eyes Darkness Metal Dragon
	"00155_00923" : "00925",                                                        #Metalmorph + Ojama King = Mecha Ojama King
	"00155_01190" : "01180",                                                        #Metalmorph + Gagagigo = Giga Gagagigo
	"00155_01180" : "01173",                                                        #Metalmorph + Giga Gagagigo = Gogiga Gagagigo
	"00155_00403" : "01248",                                                        #Metalmorph + Insect Queen = Metamorphosed Insect Queen
	"00096_00155" : "01266",                                                        #Metalmorph + Killer Needle = Armored Bee
	"00155_00634" : "01312",                                                        #Metalmorph + Fortress Whale = Mega Fortress Whale
	"00155_01314" : "01312",                                                        #Metalmorph + Orca Mega-Fortress of Darkness = Mega Fortress Whale

	#Level Up
	"00162_00383" : "00384",                                                        #Level Up + Black Tyranno = Ultimate Tyranno
	"00162_00073" : "00645",                                                        #Level Up + Red-Eyes Black Dragon = Red-Eyes Darkness Dragon
	"00162_00403" : "01248",                                                        #Level Up + Insect Queen = Metamorphosed Insect Queen
	"00017_00162" : "01321",                                                        #Level Up + Kairyu Shin = Ocean Dragon Lord - Kairyu-Shin
	
	#Toon World
	"00240_00582" : "00549",                                                        #Toon World + Blue-Eyes White Dragon = Blue-Eyes Toon Dragon
	"00072_00582" : "00550",                                                        #Toon World + Summoned Skull = Toon Summoned Skull
	"00426_00582" : "00553",                                                        #Toon World + Black Luster Soldier = Toon Black Luster Soldier
	"00235_00582" : "00554",                                                        #Toon World + Buster Blader = Toon Buster Blader
	"00080_00582" : "00555",                                                        #Toon World + Dark Magician = Toon Dark Magician
	"00559_00582" : "00560",                                                        #Toon World + Ryu-Ran = Manga Ryu-Ran
	"00570_00582" : "00561",                                                        #Toon World + Gemini Elf = Toon Gemini Elf
	"00231_00582" : "00562",                                                        #Toon World + Dark Magician Girl = Toon Dark Magician Girl
	"00073_00582" : "00563",                                                        #Toon World + Red-Eyes Black Dragon = Red-Eyes Toon Dragon
	"00333_00582" : "00564",                                                        #Toon World + Goblin Attack Force = Toon Goblin Attack Force
	"00568_00582" : "00569",                                                        #Toon World + Red Archery Girl = Toon Mermaid
	"00571_00582" : "00572",                                                        #Toon World + Masked Sorcerer = Toon Masked Sorcerer
	"00574_00582" : "00573",                                                        #Toon World + Cannon Soldier = Toon Cannon Soldier
	"00582_00593" : "00576",                                                        #Toon World + Harpie Lady = Toon Harpie Lady
	"00582_00823" : "00565",                                                        #Toon World + Cyber Dragon = Toon Cyber Dragon
	"00582_01201" : "00552",                                                        #Toon World + Barrel Dragon = Toon Barrel Dragon
	
}

#Fusions that consider a Keyworded card + correct attribute
var attribute_fusion_list = {
	"Elemental HERO" : {"wind" : ["00766"],                                                         # Elemental HERO + Wind = Elemental Hero Great Tornado
						"fire" : ["00767"],                                                         # Elemental HERO + Fire = Elemental Hero Nova Master
						"earth": ["00768"],                                                         # Elemental HERO + Earth = Elemental Hero Gaia
						"light": ["00769"],                                                         # Elemental HERO + Light = Elemental Hero The Shinig
						"water": ["00770"],                                                         # Elemental HERO + Water = Elemental Hero Absolute Zero
						"dark" : ["00771"]},                                                        # Elemental HERO + Dark = Elemental Hero Escuridao
	
	"Destiny HERO" : {"dark" : ["01514"]},                                                          #Destiny HERO + Dark = Destiny HERO - Dangerous
	
	"Mask Change" : {"wind": ["00710", "00690"],                                                    # Mask Change + Wind = Masked HERO Blast, Masked HERO Divine Wind
					"fire" : ["00711"],                                                             # Mask Change + Fire = Masked HERO Goka
					"earth": ["00691"],                                                             # Mask Change + Earth = Masked HERO Dian
					"light": ["00692"],                                                             # Mask Change + Earth = Masked HERO Koga
					"water": ["00712", "00693"],                                                    # Mask Change + Water = Masked HERO Vapor, Masked HERO Acid
					"dark" : ["00713", "00694"]},                                                   # Mask Change + Dark = Masked HERO Dark Law, Masked HERO Anki
	
	"Gem-Knight" : {"light": ["00787"]},                                                            # Gem-Knight + Light = Gem-Knight Seraphinite
	
	"Dharc" : {"dark"  : ["00250", "00252"]},                                                       # Dharc the Dark Charmer, Dharc - Familiar-Possessed
	"Lyna" : {"light"  : ["00247", "00249"]},                                                       # Lyna the Light Charmer, Lyna - Familiar-Possessed
	"Aussa" : {"earth" : ["00253", "00255", "00258", "00259"]},                                     # Aussa the Earth Charmer, Avalanching Aussa, Aussa - Familiar-Possessed, Cataclysmic Crusted Calcifida
	"Hiita" : {"fire"  : ["00260", "00262", "00265", "00266"]},                                     # Hiita the Fire Charmer, Blazing Hiita, Hiita - Familiar-Possessed, Cataclysmic Scorching Sunburner
	"Eria" : {"water"  : ["00267", "00269", "00272", "00273"]},                                     # Eria the Water Charmer, Raging Eria, Eria - Familiar-Possessed, Cataclysmic Circumpolar Chilblainia
	"Wynn" : {"wind"   : ["00274", "00276", "00279", "00280"]},                                     # Wynn the Wind Charmer, Storming Wynn, Wynn - Familiar-Possessed, Cataclysmic Cryonic Coldo
}

#Fusions that involve one specific card with specific fusion results
var special_fusion_list = {
	"00067" : {"dragon" : ["00066"] },                                            #Gaia The Fierce Knight + dragon = Gaia the Dragon Champion                          
	"00078" : {"dragon" : ["00076"],                                              #Time Wizard            + dragon = Thousand Dragon    
			  "spellcaster" : ["00644"],                                         #                      + spellcaster = Time Wizard of Tomorrow
			  "turtle" : ["01195"]},                                             #Time Wizard + Turtle = 30,000-Year White Turtle
	"00644" : {"dragon" : ["00076"]},                                             #Time Wizard of Tomorrow + dragon = Thousand Dragon 
	"00140" : {"dragon" : ["00073"] },                                            #Tyhone #2              + dragon = Red-Eyes Black Dragon                      
	"00155" : {"dragon" : ["00029", "00421"],                                     #Metalmorph             + dragon = Metal Dragon, Rare Metal Dragon 
			   "harpie" : ["01074"]},                                             #Metalmorph             + harpie = Cyber harpie Lady           
	"00217" : {"spellcaster" : ["00219", "00080"]},                               #Magician's Rod         + spellcaster = Magician of Dark Illusion, Dark Magician                        
	"00218" : {"spellcaster" : ["00219", "00080"]},                               #Magician's Robe        + spellcaster = Magician of Dark Illusion, Dark Magician                  
	"00231" : {"dragon" : ["00232"]},                                             #Dark Magician Girl     + dragon = Dark Magician Girl the Dragon Knight
	"00080" : {"dragon" : ["00233"],                                              #Dark Magician          + dragon = Dark Magician the Dragon Knight
			  "warrior": ["00239"]},                                              #                       + warrior = Dark Cavalry             
	"00237" : {"female" : ["00231"]},                                             #Magician's Valkyria    + female = Dark Magician Girl               
	"00244" : {"dragon" : ["00240"]},                                             #Dragon Spirit of White + dragon = Blue-Eyes White Dragon                                
	"00245" : {"dragon" : ["00240"]},                                             #Kaibaman               + dragon = Blue-Eyes White Dragon
	"00179" : {"insect" : ["00180", "00181", "00182", "00183"]},                  #Cocoon of Evolution    + insect = Petit Moth, Larvae Moth, Greath Moth, Perfectly Ultimate Great Moth
	"00162" : {"dragon" :      ["00163", "00164", "00165", "00166"],              #Level Up!              + dragon = Armed Dragon LV3, 5, 7, 10
			  "spellcaster" : ["00167", "00246", "00168"],                        #                       + spellcaster = Silent Magician LV4, 6 8
			  "warrior" :     ["00169" , "00170", "00171"],                       #                       + warrior = Silent Swordsman LV3, 5, 7
			  "fiend" :       ["00172", "00173", "00174"],                        #                       + fiend = Dark Lucius LV4, 6, 8
			  "insect" :      ["00175", "00176", "00177", "00178"]},              #                       + insect = Ultimate Insect LV1, 3, 5, 7
	"00254" : {"beast" : ["00256", "00257"]},                                     #Archfiend Marmot of Nefariousness + beast = Nefarious Archfiend Eater of Nefariousness, Nefariouser Archfiend - Awakening
	"00256" : {"beast" : ["00257"]},                                              #Nefarious Archfiend Eater of Nefariousness + beast = Nefariouser Archfiend - Awakening
	"00261" : {"pyro" : ["00263", "00264"]},                                      #Fox Fire                   + pyro = Inari Fire, Greater Inari Fire - Awakening
	"00263" : {"pyro" : ["00264"]},                                               #Inari Fire                 + pyro = Greater Inari Fire - Awakening                                      
	"00268" : {"aqua" : ["01190"],                                                #Gigobyte                   + aqua = Gagagigo
			   "reptile" : ["00270", "00271"]},                                   #Gigobyte                   + reptile = Jigabyte, Gagigobyte - Awakening
	"00270" : {"reptile" : ["00271"]},                                            #Jigabyte                   + reptile = Gagigobyte - Awakening
	"00275" : {"dragon" : ["00277", "00278"]},                                    #Petit Dragon               + dragon = Ranryu, Rasenryu - Awakening
	"00277" : {"dragon" : ["00278"]},                                             #Ranryu                     + dragon = Rasenryu - Awakening
	"00299" : {"thunder" : ["00300"]},                                            #Mithra the Thunder Vassal  + thunder = Zaborg the Thunder Monarch
	"00300" : {"thunder" : ["00301"]},                                            #Zaborg the Thunder Monarch + thunder = Zaborg the Mega Monarch
	"00302" : {"fiend" : ["00303"]},                                              #Lucius the Shadow Vassal   + fiend = Caius the Shadow Monarch
	"00303" : {"fiend" : ["00304"]},                                              #Caius the Shadow Monarch   + fiend = Caius the Mega Monarch
	"00305" : {"rock" : ["00306"]},                                               #Landrobe the Rock Vassal   + rock = Granmarg the Rock Monarch
	"00306" : {"rock" : ["00307"]},                                               #Granmarg the Rock Monarch  + rock = Granmarg the Mega Monarch
	"00308" : {"pyro" : ["00309"]},                                               #Berlineth the Firestorm Vassal  + pyro = Thestalos the Firestorm Monarch
	"00309" : {"pyro" : ["00310"]},                                               #Thestalos the Firestorm Monarch + pyro = Thestalos the Mega Monarch
	"00311" : {"aqua" : ["00312"]},                                               #Escher the Frost Vassal  + aqua = Mobius the Frost Monarch
	"00312" :  {"aqua" : ["00313"]},                                              #Mobius the Frost Monarch + aqua = Mobius the Mega Monarch
	"00314" : {"winged beast" : ["00315"]},                                       #Garum the Storm Vassal  + winged beast = Raiza the Storm Monarch
	"00315" : {"winged beast" : ["00316"]},                                       #Raiza the Storm Monarch + winged beast = Raiza the Mega Monarch
	"00428" : {"spellcaster" : ["00425"]},                                        #Magician of Black Chaos + spellcaster = Sorcerer of Dark Magic
	"00433" : {"fairy" : ["00431"]},                                              #Dark Flare Knight       + fairy = Mirage Knight
	"00512" : {"warrior" : ["00511"],                                             #The Judgement Hand + warrior = Judge Man
			  "female" : ["00510"]},                                              #                   + female = Empress Judge
	"00480" : {"fiend" : ["00514"]},                                              #Ryu-Kishin + Fiend = Ryu-Kishin Powered
	"00516" : {"dragon" : ["00519"],                                              #Lord of D + dragon = King Dragun
			  "female" : ["00518"]},                                              #          + female = Lady of D
	"00451" : {"warrior" : ["00532"]},                                            #Green Gadget + warrior = Gadget Soldier
	"00452" : {"warrior" : ["00532"]},                                            #Red Gadget + warrior = Gadget Soldier
	"00453" : {"warrior" : ["00532"]},                                            #Yellow Gadget + warrior = Gadget Soldier
	"00454" : {"warrior" : ["00532"]},                                            #Gold Gadget + warrior = Gadget Soldier
	"00455" : {"warrior" : ["00532"]},                                            #Silver Gadget + warrior = Gadget Soldier
	"00543" : {"dragon" : ["00544"]},                                             #Dark Blade + dragon = Dark Blade the Dragon Knight
	"00586" : {"aqua" : ["00567"]},                                               #Aqua Madoor + aqua = Neo Aqua Madoor
	"00611" : {"warrior": ["00605"]},                                             #Ghost Knight of Jackal + beast = Mystical Knight of Jackal
	"00073" : {"warrior": ["00629"]},                                             #Red-Eyes Black Dragon + warrior = Red-Eyes Slash Dragon
	"00409" : {"spellcaster" : ["00630"]},                                        #Gearfried the Iron Knight + spellcaster = Gilti-Gearfried the Magical Steel Knight
	"00652" : {"warrior" : ["00630"]},                                            #Giltia the D. Knight + warrior = = Gilti-Gearfried the Magical Steel Knight
	"00669" : {"machine" : ["00633", "00631"]},                                   #Jinzo - Returner + machine = Jinzo, Jinzo - Lord
	"00633" : {"machine" : ["00631"]},                                            #Jinzo + machine = Jinzo - Lord
	"00663" : {"dragon" : ["00664", "00073"]},                                    #Red-Eyes Baby Dragon + dragon = Red-Eyes Wyvern, Red-Eyes Black Dragon
	"00812" : {"gem" : ["00811"]},                                                #Gem-Knight Tourmaline + Gem = Gem-Knight Topaz
	"00809" : {"gem" : ["00804"]},                                                #Gem-Knight Sapphire + Gem = Gem-Knight Aquamarine
	"00806" : {"gem" : ["00786"]},                                                #Gem-Knight Garnet + Gem = Gem-Knight Ruby
	"00813" : {"gem" : ["00784", "00778"]},                                       #Gem-Knight Lapis + Gem = Gem-Knight Lady Lapis Lazuli, Gem-Knight Lady Brilliant Diamond
	"00814" : {"gem" : ["00784", "00778"]},                                       #Gem-Knight Lazuli + Gem = Gem-Knight Lady Lapis Lazuli, Gem-Knight Lady Brilliant Diamond
	"00784" : {"gem" : ["00778"]},                                                #Gem-Knight Lady Lapis Lazuli + Gem = Gem-Knight Lady Brilliant Diamond
	"00811" : {"gem" : ["00779"]},                                                #Gem-Knight Topaz + Gem = Gem-Knight Master Diamond
	"00804" : {"gem" : ["00779"]},                                                #Gem-Knight Aquamarine + Gem = Gem-Knight Master Diamond
	"00803" : {"gem" : ["00779"]},                                                #Gem-Knight Amethyst + Gem = Gem-Knight Master Diamond
	"00787" : {"gem" : ["00779"]},                                                #Gem-Knight Seraphinite + Gem = Gem-Knight Master Diamond
	"00786" : {"gem" : ["00779"]},                                                #Gem-Knight Ruby + Gem = Gem-Knight Master Diamond
	"00785" : {"gem" : ["00779"]},                                                #Gem-Knight Prismaura + Gem = Gem-Knight Master Diamond
	"00782" : {"gem" : ["00779"]},                                                #Gem-Knight Citrine + Gem = Gem-Knight Master Diamond
	"00780" : {"gem" : ["00779"]},                                                #Gem-Knight Zirconia + Gem = Gem-Knight Master Diamond
	"00839" : {"roid" : ["00822"]},                                               #Rescueroid + Roid = Ambulance Rescueroid
	"00844" : {"roid" : ["00822"]},                                               #Ambulanceroid + Roid = Ambulance Rescueroid
	"00924" : {"ojama" : ["00923"]},                                              #Ojama Knight + Ojama = Ojama King
	"00923" : {"machine" : ["00925"]},                                            #Ojama King + machine = Mecha Ojama King
	"00935" : {"dragon" : ["00927"]},                                             #Chthonian Soldier + dragon = Chthonian Emperor Dragon
	"00948" : {"fiend" : ["00920"]},                                              #Fear from the Dark + friend = Despair from the Dark
	"00971" : {"female" : ["00950"],                                              #Chamber Dragonmaid + female = House Dragonmaid
			   "dragon" : ["00951"]},                                             #Chamber Dragonmaid + dragon = Dragonmaid Sheou
	"00972" : {"dragon" : ["00954"]},                                             #Nurse Dragonmaid + dragon = Dragonmaid Ernus
	"00973" : {"dragon" : ["00955"]},                                             #Kitchen Dragonmaid + dragon = Dragonmaid Tinkhec
	"00974" : {"dragon" : ["00956"]},                                             #Laundry Dragonmaid + dragon = Dragonmaid Nudyarl
	"00975" : {"dragon" : ["00957"]},                                             #Parlor Dragonmaid + dragon = Dragonmaid Lorpar
	"00958" : {"fiend" : ["00960"],                                               #Outstanding Dog Marron + fiend = Mad Dog of Darkness
			   "machine" : ["00961"],                                             #Outstanding Dog Marron + machine = Mecha-Dog Marron
			   "zombie" : ["00962"]},                                             #Outstanding Dog Marron + zombie = Skull Dog Marron
	"00964" : {"spellcaster" : ["00965"]},                                        #Ebon Magician Curran + spellcaster = Princess Curran
	"00966" : {"spellcaster" : ["00967"]},                                        #White Magician Pikeru + spellcaster = Princess Pikeru
	"01003" : {"dragon" : ["00981"]},                                             #Snow Dragon + dragon = Snowdust Dragon
	"01002" : {"female" : ["01000", "00988", "00979"]},                           #Crystal Girl + female = Cold Enchanter, Ice Master, Ice Queen
	"01000" : {"female" : ["00988", "00979"]},                                    #Cold Enchanter + female = Ice Master, Ice Queen
	"00988" : {"female" : ["00979"]},                                             #Ice Master + female = Ice Queen
	"01029" : {"warrior" : ["01024", "01023"],                                    #Ancient Gear + warrior = Ancient Gear Frame, Ancient Gear Knight
			   "winged beast" : ["01025"],                                        #Ancient Gear + winged beast = Ancient Gear Wyvern
			   "beast" : ["01028", "01020"]},                                     #Ancient Gear + beast = Ancient Gear Hunting Hound, Ancient Gear Beast
	"01024" : {"winged beast" : ["01025"],                                        #Ancient Gear Frame + winged beast = Ancient Gear Wyvern
			   "beast" : ["01020"],},                                             #Ancient Gear Frame + beast = Ancient Gear Beast
	"01025" : {"winged beast" : ["01018"],                                        #Ancient Gear Wyvern + winged beast = Ancient Gear Hydra
			   "beast" : ["01017"],                                               #Ancient Gear Wyvern + beast = Ancient Gear Gadjiltron Chimera
			   "gear" : ["01018"]},                                               #Ancient Gear Wyvern + gear = Ancient Gear Hydra
	"01020" : {"winged beast" : ["01018"],                                        #Ancient Gear Beast + winged beast = Ancient Gear Hydra
			   "beast" : ["01017"],                                               #Ancient Gear Beast + beast = Ancient Gear Gadjiltron Chimera
			   "gear" : ["01017"]},                                               #Ancient Gear Beast + gear = Ancient Gear Gadjiltron Chimera
	"01028" : {"winged beast" : ["01018"],                                        #Ancient Gear Hunting Hound +  winged beast = Ancient Gear Hydra
			   "beast" : ["01020", "01017"],                                      #Ancient Gear Hunting Hound + beast = Ancient Gear Beast, Ancient Gear Gadjiltron Chimera
			   "gear" : ["01020", "01017"]},                                      #Ancient Gear Hunting Hound + gear = Ancient Gear Beast, Ancient Gear Gadjiltron Chimera
	"01018" : {"gear" : ["01015"]},                                               #Ancient Gear Hydra + gear = Ancient Gear Gadjiltron Dragon
	"01023" : {"gear" : ["1013"]},                                                #Ancient Gear Knight + gear = Ancient Gear Golem
	"01013" : {"gear" : ["01012"]},                                               #Ancient Gear Golem + gear = Ancient Gear Megaton Golem
	"01012" : {"gear" : ["01011"]},                                               #Ancient Gear Megaton Golem + gear = Ultimate Ancient Gear Golem
	"01011" : {"gear" : ["01010"]},                                               #Ultimate Ancient Gear Golem + gear = Chaos Ancient Gear Giant
	"00235" : {"dragon" : ["01053"]},                                             #Buster Blader + dragon = Buster Blader, the Dragon Destroyer Swordsman
	"01066" : {"dragon" : ["01067"]},                                             #Crimson Ninja + dragon = Red Dragon Ninja
	"01068" : {"dragon" : ["01069"]},                                             #White Ninja + dragon = White Dragon Ninja
	"01070" : {"dragon" : ["01071"]},                                             #Yellow Ninja + dragon = Yellow Dragon Ninja
	"01190" : {"machine" : ["01180", "01173"]},                                   #Gagagigo + machine = Giga Gagagigo, Gogiga Gagagigo
	"01180" : {"machine" : ["01173"]},                                            #Giga Gagagigo + machine = Gogiga Gagagigo
	"01146" : {"female" : ["00510"]},                                             #Queen's Double + Female = Empress Judge
	"01209" : {"machine" : ["01205", "01204", "01200"]},                          #Flint Lock + Machine = B.E.S. Big Core, MK2 and MK3
	"01205" : {"machine" : ["01204", "01200"]},                                   #B.E.S. Big Core + Machine = MK2 and MK3
	"01204" : {"machine" : ["01200"]},                                            #B.E.S. Big Core MK2 + Machine = MK3
	#"00182" : {"insect" : ["01247"]},                                             #Great Moth + insect = Ultimate Great Insect
	"01255" : {"insect" : ["01249"]},                                             #Flying Kamakiri #2 + Insect = Grasschopper
	"00096" : {"machine" : ["01266"]},                                            #Killer Needle + Machine = Armored Bee
	"01261" : {"insect" : ["01260"]},                                             #Kuwagata A + insect = Kuwagar Hercules
	"00095" : {"insect" : ["01260"]},                                             #Hercules Beetle + insect = Kuwagar Hercules
	"01272" : {"dinosaur" : ["01270"]},                                           #Kaitoptera + dinosaur = Horned Saurus
	"01271" : {"pyro" : ["01273"]},                                               #Trakodon + pyro = Pragtical
	"01319" : {"dragon" : ["01311", "01309"]},                                    #Codarus + Dragon = Dedalus, Neo-dedalus
	"01311" : {"dragon" : ["01309"]},                                             #Dedalus + Dragon = Neo-Dedalus
	"01339" : {"dragon" : ["01310"]},                                             #Tridon + Dragon = Poseidra
	"00634" : {"machine" : ["01312"]},                                            #Fortress Whale + Machine = Mega Fortress Whale
	"01314" : {"machine" : ["01312"]},                                            #Orca Mega-Fortress of Darkness + Machine = Mega Fortress Whale
	"01280" : {"amazon" : ["01278", "01276"]},                                    #Amazoness Queen + Amazon = Amazoness Empress, Amazoness Augusta
	"01278" : {"amazon" : ["01276"]},                                             #Amazoness Empress + Amazon = Amazoness Augusta
	"01279" : {"amazon" : ["01277"]},                                             #Pet Liger + Amazon = Pet Liger King
	"01350" : {"female" : ["00982"]},                                             #Mutant Mindmaster + Female = Cosmo Queen
	"00459" : {"machine" : ["01347"],                                             #Zombyra + Machine = Last Warrior from Another Planet
			   "thunder" : ["01347"]},                                            #Zombyra + Thunder = Last Warrior from Another Planet
	"00129" : {"female" : ["01381"]},                                             #Skull Servante + Female = Wightprincess
	"01375" : {"fiend": ["00353"],                                                #Immortal Ruler + Fiend = Dark Ruler Ha Des
			   "spellcaster" : ["00353"],                                         #Immortal Ruler + Spellcaster = Dark Ruler Ha Des
			   "zombie" : ["00353"]},                                             #Immortal Ruler + Zombie = Dark Ruler Ha Des
	"01112" : {"fairy" : ["01113"]},                                              #Warrior of Zera + Fairy = Zeradias
	"01113" : {"fairy" : ["01114"],                                               #Zeradias + Fairy = Archlord Zerato
			   "fiend" : ["01115"],                                               #Zeradias + Fiend = Mazera DeVille
			   "zombie": ["01116"]},                                              #Zeradias + Zombie = Alghoul Mazera
	"01409" : {"fairy" : ["01405"]},                                              #Angel O1 + Fairy = Angel O7
	"00642" : {"fairy" : ["01405"]},                                              #Divine Knight Ishzark + Fairy = Angel O7
	"01437" : {"warrior" : ["00926"]},                                            #Armed Dragon, the Armored Dragon + Warrior = Dragonic Knight
	"01473" : {"zombie" : ["01449"]},                                             #Abaki + Zombie = Red Ogre
	"00999" : {"dragon" : ["00978"]},                                             #White Night Queen + Dragon = White Night Dragon
	"01478" : {"female" : ["00982"]},                                             #Cosmo Brain + Female = Cosmo Queen
	"01482" : {"crystal" : ["00775"],                                             #Crystal Beast Rainbow Dragon + Crystal = Rainbow Dragon
			   "gem" : ["00775"]},                                                #Crystal Beast Rainbow Dragon + Gem = Rainbow Dragon
	"01498" : {"winged beast" : ["01495"],                                        #Transforming Sphere + Winged Beast = The Atmosphere
			   "dragon" : ["01495"]},                                             #Transforming Sphere + Dragon = The Atmosphere
	"00646" : {"zombie" : ["01491"]},                                             #Red-Eyes Zombie Dragon + Zombie = Red-Eyes Zombie Dragon Lord
	"01492" : {"zombie" : ["01491"]},                                             #Red-Eyes Zombie Necro Dragon + Zombie = Red-Eyes Zombie Dragon Lord
	"01507" : {"d-hero" : ["01506"]},                                             #Destiny HERO - Dystopia + D-Hero = Destiny HERO - Dominance
	"01514" : {"d-hero" : ["01506"]},                                             #Destiny HERO - Dangerous + D-Hero = Destiny HERO - Dominance
	"01508" : {"d-hero" : ["01506"]},                                             #Destiny HERO - Destroyer Phoenix Enforcer + D-Hero = Destiny HERO - Dominance
	"01506" : {"d-hero" : ["01505"]},                                             #Destiny HERO - Dominance + D-Hero = Destiny HERO - Dusktopia
	"01513" : {"d-hero" : ["01510"],                                              #Vision HERO Trinity + D-Hero = Vision HERO Adoration
			   "v-hero" : ["01510"]},                                             #Vision HERO Trinity + V-Hero = Vision HERO Adoration
	"00757" : {"warrior" : ["00736"]},                                            #Chrysalis Dolphin + Warrior = Neo-Spacian Aqua Dolphin
	"00758" : {"warrior" : ["00732"]},                                            #Chrysalis Chicky + Warrior = Neo-Spacian Air Hummingbird
	"00759" : {"warrior" : ["00733"]},                                            #Chrysalis Larva + Warrior = Neo-Spacian Flare Scarab
	"00760" : {"warrior" : ["00734"]},                                            #Chrysalis Mole + Warrior = Neo-Spacian Grand Mole
	"00761" : {"warrior" : ["00737"]},                                            #Chrysalis Pantail + Warrior = Neo-Spacian Dark Panther
	"00762" : {"warrior" : ["00735"]},                                            #Chrysalis Pinny + Warrior = Neo-Spacian Glow Moss
}


#Classic Forbidden Memories fusions, based on monster types (and secret additional monster types!)
var generic_fusion_list = {
	"amazon_amazon":     ["01303", "01281", "01280"],                              #Princess, Paladin, Queen
	"amazon_beast" :     ["01294", "01288", "01279"],                              #Baby, Tiger, Pet Liger
	
	"aqua_dinosaur":     ["00387", "00388"],                                       #Hydrogeddon, Duoterion
	"aqua_dragon":       ["00016", "00017", "00362", "00363"],                       #Spike Seadra, Kairyu-Shin, Aqua Dragon, Water Dragon
	"aqua_fish":         ["00419"],                                               #High Tide Gyojin
	"aqua_pyro":         ["00420"],                                               #Fire Kraken
	"aqua_gem":          ["00803"],                                               #Gem-Knight Amethyst
	"aqua_reptile":      ["00343", "00344"],                                       #Oshaleon, Majioshaleon
	"aqua_sea serpent":  ["00360", "00361"],                                       #Divine Dragon Aquabizarre, Spiral Serpent
	"aqua_thunder":      ["00047", "00368"],                                       #Bolt Escargot, Thunder Sea Horse
	"aqua_winged beast": ["00386"],                                               #Oxygeddon
	
	"beast-warrior_fairy":        ["00377"],                                      #Woodland Archer
	"beast-warrior_fiend":        ["00354", "00355"],                              #Des Feral Imp, Archfiend Giant
	"beast-warrior_machine":      ["00378"],                                      #Cybernetic Cyclopean
	"beast-warrior_reptile":      ["00376"],                                      #Garoozis
	"beast-warrior_winged beast": ["00374", "00375"],                              #Hunter of Black Feathers, Manticore of Darkness
	
	"beast_female":       ["00063"],                                              #Nekogal #2
	"beast_fish":         ["00023", "00024", "00025"],                              #Tatsunootoshigo, Rare Fish, Marine Beast
	"beast_machine":      ["00030", "00031"],                                      #Giga-Tech Wolf, Dice Armadillo
	"beast_ninja":        ["01065"],                                              #Nin-Ken Dog
	"beast_plant":        ["00051"],                                              #Flower Wolf
	"beast_psychic":      ["01382", "01383"],                                     #Psi-Beast, Pandaborg
	"beast_pyro":         ["00054"],                                              #Flame Cerebrus
	"beast_reptile":      ["00346"],                                              #Lion Alligator
	"beast_thunder":      ["00046", "01188", "00369"],                            #Tripwire Beast, Voltic Kong, Thunderclap Skywolf
	"beast_vampire":      ["01056"],                                              #Vampire Retainer
	"beast_warrior":      ["00015", "00405", "00406"],                              #Tiger Axe, Boar Soldier, Garnecia Elefantis
	"beast_winged beast": ["00050"],                                              #Garvas
	
	"clown_fiend" : ["00566"],                                                    #Bickuribox
	"clown_dragon" : ["00587"],                                                   #Soul Hunter
	"clown_reptile": ["00587"],                                                   #Soul Hunter
	"clown_zombie" : ["01368"],                                                   #Clown Zombie
	
	"cyber_dragon" : ["00899", "00823"],                                          #Proto-Cyber Dragon, Cyber Dragon
	"cyber_cyber" : ["00894"],                                                    #Chimeratech Rampage Dragon
	"cyberdark_cyberdark" : ["00895"],                                            #Cyberdarkness Dragon
	
	"crystal_crystal" : ["01482"],                                                #Crystal Beast Rainbow Dragon
	"crystal_gem" : ["01482"],                                                    #Crystal Beast Rainbow Dragon

	"dinosaur_fiend":       ["00382", "00383"],                                    #Destroyersaurus, Black Tyranno
	"dinosaur_machine":     ["00052", "00379"],                                    #Cyber Saurus, Cyber Dinosaur
	"dinosaur_sea serpent": ["00385"],                                             #Megalosmasher X
	"dinosaur_rock" : ["01273"],                                                   #Pragtical
	
	"dragon_egg":         ["00559"],                                              #Ryu-ran
	"dragon_fairy":       ["00624", "01123"],                                     #Fairy Dragon, Seiyaryu
	"dragon_fiend":       ["00535", "01269"],                                     #Fiend Skull Dragon, Serpent Night Dragon
	"dragon_harpie":      ["01080", "01081"],                                     #Harpie's Baby Dragon, Harpie's Pet Dragon
	"dragon_machine":     ["00029", "00421"],                                      #Metal Dragon, Rare Metal Dragon
	"dragon_plant":       ["00059"],                                              #B. Dragon Jungle King
	"dragon_pyro":        ["00417", "00418"],                                      #Darkfire Dragon, Twin-Headed Fire Dragon
	"dragon_rock":        ["00035"],                                              #Stone Dragon
	"dragon_sea serpent": ["00364"],                                              #The Dragon Dwelling in the Deep
	"dragon_thunder":     ["00033", "00034"],                                      #Thunder Dragon, Twin-Headed Thunder Dragon
	"dragon_vampire":     ["01057"],                                              #Vampire Dragon
	"dragon_warrior":     ["00001", "00002", "00003", "00004", "01179"],          #Dragon Statue, Dragoness the Wicked Knight, D. Human, Sword Arm of Dragon, Mikazukinoyaiba
	"dragon_zombie":      ["00011", "00012", "00013"],                              #Dragon Zombie, Skelgon, Curse of Dragon
	
	"d-hero_d-hero" :     ["01507"],                                                #Dystopia
	"d-hero_v-hero" :     ["01513"],                                                #Vision HERO Trinity
	
	"fairy_female":       ["00060", "00212", "00216"],                              #Dark Witch, St. Joan, Amaterasu
	"fairy_insect":       ["00400", "00401"],                                      #Millennium Scorpion, Mystical Beast of Serket
	"fairy_plant":        ["00389", "00390"],                                      #Spirit of the Fall Wind, Iris the Earth Mother
	"fairy_spellcaster":  ["00058"],                                              #Dark Elf
	"fairy_warrior":      ["00014"],                                              #Celtic Guardian
	"fairy_winged beast": ["00391", "00392", "00393"],                              #Hysteric Fairy, Soul of Purity and Light, Wingweaver
	
	"female_fiend":   ["00213", "00214"],                                          #Darklord Marie, Oracle King d'Arc
	"female_fish":    ["00036", "00037", "00038"],                                  #Ice Water, Enchanting Mermaid, Amazon of the Seas
	"female_insect":  ["00402", "00403"],                                          #Insect Princess, Insect Queen
	"female_ninja":   ["01062", "01064"],                                         #Lady Ninja Yae, Kunoichi
	"female_plant":   ["00064", "00390"],                                          #Queen of Autumn Leaves, Iris the Earth Mother
	"female_psychic" : ["01391"],                                                  #Hypnosister
	"female_rock":    ["00055"],                                                  #Mystical Sand
	"female_thunder": ["00366"],                                                  #Denko Sekka
	"female_vampire": ["01058", "01061"],                                         #vampire lady, vampire vamp
	"female_warrior": ["00211", "00212"],                                          #Noble Knight Joan, St. Joan
	
	"fiend_machine":      ["00359"],                                              #Gil Garth
	"fiend_reptile":      ["00345"],                                              #Granadora
	"fiend_spellcaster":  ["00352", "00353"],                                      #Dark Balter the Terrible, Dark Ruler Ha Des
	"fiend_warrior":      ["00347", "00348", "00349"],                              #Archfiend Soldier, Beast of Talwar, Belial - Marquis of Darkness
	"fiend_winged beast": ["00356", "00357"],                                      #Element Doom, Archfiend of Gilfer
	
	"fish_insect":  ["00394"],                                                    #Deep Sweeper
	"fish_machine": ["00039", "00040", "00395", "00396"],                            #Misairuzame, Metal Fish, Cyber Shark, Hyper-Ancient Shark Megalodon
	"fish_warrior": ["00057", "00407", "00408"],                                    #Wow Warrior, Takriminos, Amphibian Beast
	"fish_zombie":  ["00056"],                                                    #Corroding Shark
	
	"gear_gear": ["01024", "01022",	"01021", "01023"],                             #Ancient Gear Frame, Ancient Gear Soldier, Ancient Gear Engineer, Ancient Gear Knight

	"gem_thunder": ["00785"],                                                     #Gem-Knight Prismaura
	"gem_pyro":    ["00782"],                                                     #Gem-Knight Citrine
	"gem_rock":    ["00780"],                                                     #Gem-Knight Zirconia
	
	"harpie_harpie": ["00593", "01079"],                                          #Lady, Harpie Lady Sisters
	"harpie_machine" : ["01074"],                                                 #Cyber Harpie lady
	
	"insect_machine" : ["01263", "01250"],                                         #Beetron, Chainsaw Insect
	"insect_pyro":    ["00422"],                                                  #Blazewing Butterfly
	"insect_rock":    ["00397", "00398", "00399"],                                  #Aztekipede the Worm Warrior, Hundred-Footed Horror, Doom Dozer
	"insect_warrior": ["00049", "00000"],                                          #Cockroach Knight, Shiny Black "C" Squadder
	
	"machine_psychic" : ["01387"],                                                 #Psychic Ace
	"machine_spellcaster": ["00065", "00404"],                                     #Disk Magician, Cybernetic Magician
	"machine_thunder":     ["00371", "00372", "00373"],                             #Batteryman 9-Volt, Batteryman Charger, Batteryman Industrial Strength
	"machine_turtle" :     ["01354"],                                              #UFO Turtle
	"machine_warrior":     ["00032", "00409"],                                     #Cyber Soldier, Gearfried the Iron Knight

	"masked_masked": ["00689"],                                                   #Contrast HERO Chaos
	
	"ninja_ninja": ["00482", "01072", "01073"],                                    #Ansatsu, Senior Silver Ninja, War Ninja Meisen

	"ojama_ojama" : ["00924", "00923"],                                            #Ojama Knight, Ojama King

	"plant_warrior": ["00053", "00410"],                                           #Bean Soldier, Jerry Beans Man
	"plant_zombie":  ["00018", "00019"],                                           #Wood Remains, Pumpking the King of Ghosts
	
	"psychic_psychic" : ["01392", "01393", "01394"],                              #Power Injector, Overdrive Teleporter, Psychic Emperor
	"psychic_spellcaster" : ["01386", "01355"],                                   #Risebell the Star Adjuster, Illusory gentleman
	"psychic_thunder" : ["01388", "01389", "01390"],                              #Wattsychic Fighter, Telekinetic Shocker, Psychic Snail
	"psychic_warrior" : ["01384", "01385"],                                       #Grapple Blocker, Space-Time Police
	
	"pyro_warrior":      ["00005", "00006", "00007"],                               #Charubin the Fire Knight, Flame Swordsman, Vermillion Sparrow
	"pyro_winged beast": ["00027", "00028"],                                       #Mavelus, Crimson Sunbird
	"pyro_zombie":       ["00020", "00021", "00412", "00413"],                       #Fire Reaper, Flame Ghost, Heavy Knight of the Flame, Skull Flame
	
	"reptile_warrior": ["00339", "00342"],                                         #Alligator's Sword, Spawn Alligator
	
	"rock_warrior": ["00153", "00319", "00318"],                                    #Giant Soldier of Stone, Destroyer Golem, Millennium Golem
	"rock_zombie":  ["00043", "00416"],                                            #Stone Ghost, Skelesaurus
	
	"roid_roid": ["00836", "00842", "00818", "00817"],                               #Pair Cycroid, Steam Gyroid, Stealth Union - Super Vehicroid, Barbaroid, the Ultimate Battle Machine

	"sea serpent_winged beast": ["00365"],                                        #Airorca
	
	"spellcaster_thunder": ["00044", "00045"],                                     #The Immortal of Thunder, Kaminari Attack
	"spellcaster_vampire": ["01060"],                                             #vampire sorcerer
	"spellcaster_zombie":  ["00048", "00414", "00415"],                             #Magical Ghost, Great Dezard, Fushioh Richie
	
	"thunder_zombie": ["00367"],                                                  #Lightning Rod Lord
	
	"turtle_zombie" : ["00615"],                                                  #Pyramid Turtle
	
	"vampire_vampire" : ["01055", "00501", "01059"],                               #Vampire Baby, Vampire Lord, Vampire Genesis
	
	"v-hero_v-hero" :   ["01513"],                                                #Vision HERO Trinity
	
	"warrior_zombie": ["00008", "00009", "00411", "01049"]                        #Zombie Warrior, Armored Zombie, Master Kyonshee, Skull Knight
}
