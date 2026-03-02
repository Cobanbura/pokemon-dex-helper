extends Control

# Data Storage
var all_pokemon = {} 
var filtered_names = [] 

# Configuration
var base_url = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/"

# Node References
@onready var search_input = $VBoxContainer/SearchInput
@onready var item_list = $PokemonList
@onready var slot_spin_box = $VBoxContainer/SlotSettings/SlotSpinBox
@onready var result_label = $VBoxContainer/ResultsPanel/ResultsLabel
@onready var pokemon_image = $VBoxContainer/PokemonImage

func _ready():
	load_pokemon_data()
	item_list.visible = false 
	
	# Connect Signals
	search_input.text_changed.connect(_on_search_text_changed)
	item_list.item_selected.connect(_on_item_selected)
	slot_spin_box.value_changed.connect(_on_slot_count_changed)

func load_pokemon_data():
	if FileAccess.file_exists("res://pokemon_list.json"):
		var file = FileAccess.open("res://pokemon_list.json", FileAccess.READ)
		var content = file.get_as_text()
		all_pokemon = JSON.parse_string(content)
		if all_pokemon == null:
			print("Error: JSON format is invalid!")
	else:
		print("Error: pokemon_list.json not found!")

func _on_search_text_changed(new_text: String):
	item_list.clear()
	filtered_names.clear()
	
	if new_text.strip_edges() == "":
		item_list.visible = false
		return
	
	var search_term = new_text.to_lower()
	
	for p_name in all_pokemon.keys():
		if search_term in p_name.to_lower():
			filtered_names.append(p_name)
	
	if filtered_names.size() > 0:
		item_list.visible = true
		filtered_names.sort() 
		for p_name in filtered_names:
			item_list.add_item(p_name)
	else:
		item_list.visible = false

func _on_item_selected(index: int):
	var selected_name = item_list.get_item_text(index)
	var p_id = all_pokemon[selected_name]
	
	search_input.text = selected_name
	item_list.visible = false
	
	calculate_and_display(selected_name, p_id)
	load_pokemon_image(p_id)

func _on_slot_count_changed(_value):
	if search_input.text in all_pokemon:
		calculate_and_display(search_input.text, all_pokemon[search_input.text])

func calculate_and_display(p_name: String, p_id: int):
	var slots_per_page = int(slot_spin_box.value)
	var index = p_id - 1
	
	var page = floor(index / slots_per_page) + 1
	var leaf = floor((page - 1) / 2) + 1
	var slot_in_page = (index % slots_per_page) + 1
	var side = "Front" if int(page) % 2 != 0 else "Back"
	
	var info = "[b]%s[/b] (#%d)\n" % [p_name, p_id]
	info += "Sheet: %d, Page: %s, Slot: %d" % [leaf, side, slot_in_page]
	
	result_label.text = info

func load_pokemon_image(id: int):
	var final_url = base_url + str(id) + ".png"
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result, response_code, headers, body):
			if response_code == 200:
				var image = Image.new()
				var error = image.load_png_from_buffer(body)
				if error == OK:
					pokemon_image.texture = ImageTexture.create_from_image(image)
			http_request.queue_free()
	)
	
	var err = http_request.request(final_url)
	if err != OK:
		print("HTTP Request Error")
