extends Control

@onready var panel: Panel = $CanvasLayer/Panel
@onready var quest_list: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestList
@onready var quest_title: Label = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestTitle
@onready var quest_description: Label = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestDescription
@onready var quest_objectives: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestObjectives
@onready var quest_rewards: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails/QuestRewards
@onready var quest_details: VBoxContainer = $CanvasLayer/Panel/Contents/Details/QuestDetails

var selected_quest : Quest = null
var quest_manager
var select_quest_button: Button

func _ready() -> void:
	panel.visible = false
	clear_quest_details()
	Global.global_quest_ui = self
	quest_manager = get_parent()
	
func show_hide_quest_log():
	panel.visible = !panel.visible
	update_quest_list()

func update_quest_list():
	#print("Updating quest list in UI...")
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()

	print("from update_quest_list")
	var active_quests = get_parent().get_active_quests()
	#print("Found", active_quests.size(), "active quests")
	
	if active_quests.size() == 0:
		print("No active quests to display")
		clear_quest_details()
		Global.player.selected_quest = null
	else:
		#print("Displaying", active_quests.size(), "quests in UI")
		for quest in active_quests:
			#print("Adding quest to UI:", quest.quest_name)
			var quest_button = Button.new()
			quest_button.add_theme_font_size_override("font_size",20)
			quest_button.text = quest.quest_name
			quest_button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list.add_child(quest_button)
			
			
func _on_quest_selected(quest : Quest):
	selected_quest = quest
	print(",selected_quest------------_on_quest_selected",selected_quest.quest_id)
	# Don't automatically set Global.player.selected_quest here
	quest_title.text = quest.quest_name
	quest_description.text = quest.quest_description
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		
	for objective in quest.objectives:
		var label = Label.new()
		label.add_theme_font_size_override("font_size",20)
		if objective.objective_type == "collection":
			label.text = objective.description + "(" + str(objective.collected_quantity) + "/" + str(objective.required_quantity) + ")"
		else:
			label.text = objective.description
			
		if objective.is_completed:
			label.add_theme_color_override("font_color",Color(0,1,0))
		else:
			label.add_theme_color_override("font_color",Color(1,0,0))
			
		quest_objectives.add_child(label)
		
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
		
	for reward in quest.rewards: # or quest_rewards
		var label = Label.new()
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color(0,0.84,0))
		label.text = "Rewards: " + reward.reward_type.capitalize() + ": " + str(reward.reward_amount)
		quest_rewards.add_child(label)
	
	# Add the Select Quest button
	add_select_quest_button()
	
func add_select_quest_button():
	# Remove existing button if it exists
	if select_quest_button:
		select_quest_button.queue_free()
	
	# Create new Select Quest button
	select_quest_button = Button.new()
	select_quest_button.add_theme_font_size_override("font_size", 18)
	select_quest_button.custom_minimum_size = Vector2(10, 50)  # Width x Height
	select_quest_button.text = "Select Quest"
	select_quest_button.pressed.connect(_on_select_quest_pressed)
	quest_details.add_child(select_quest_button)
	
func _on_select_quest_pressed():
	if selected_quest:
		Global.player.selected_quest = selected_quest
		Global.player.update_quest_tracker()
		print("Quest selected for tracking:", selected_quest.quest_name)
		# Optionally change button text to show it's selected
		select_quest_button.text = "Selected ✓"
		select_quest_button.disabled = true
	
func clear_quest_details():
	print("========clear_quest_details===========")
	quest_title.text = ""
	quest_description.text = ""
	
	# Remove select quest button
	if select_quest_button:
		select_quest_button.queue_free()
		select_quest_button = null
	
	for child in quest_objectives.get_children():
		quest_objectives.remove_child(child)
		child.queue_free()
		
	for child in quest_rewards.get_children():
		quest_rewards.remove_child(child)
		child.queue_free()

func _on_close_button_pressed() -> void:
	show_hide_quest_log()
