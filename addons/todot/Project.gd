tool
extends VBoxContainer
var data_file = "res://addons/todot/data/project.data"
var icons = {
	"add": preload("res://addons/todot/assets/Add.svg"),
	"tools": preload("res://addons/todot/assets/Tools.svg"),
	"save": preload("res://addons/todot/assets/Save.svg"),
	"load": preload("res://addons/todot/assets/Load.svg"),
	"visible": preload("res://addons/todot/assets/GuiVisibilityVisible.svg"),
	"hidden": preload("res://addons/todot/assets/GuiVisibilityHidden.svg"),
	"reload": preload("res://addons/todot/assets/Reload.svg")
}

onready var Dialog = get_parent().get_node("Dialog")
onready var CurList = $Controls/List

var model := Model.new()

func _enter_tree():
	#save_project()
	load_project()
	$NewList.visible = false
	$Controls/Add.connect("pressed", self, "add_new_task")
	$Controls/Clear.connect("pressed", self, "clear_completed_tasks")
	$Controls/More.get_popup().clear()
	$Controls/More.get_popup().add_icon_item(icons["add"], "New List")
	$Controls/More.get_popup().add_icon_item(show_hidden_icon(), "Show Hidden")
	#$Controls/More.get_popup().add_icon_item(icons["tools"], "Menu")
	$Controls/More.get_popup().add_icon_item(icons["save"], "Save")
	$Controls/More.get_popup().add_icon_item(icons["load"], "Load")
	$Controls/More.get_popup().add_icon_item(icons["tools"], "Settings")
	$Controls/More.get_popup().connect("id_pressed", self, "more_option_pressed")

func more_option_pressed(id):
	match id:
		0:
			open_new_list_panel()
		1:
			model.show_hidden = !model.show_hidden
			$Controls/More.get_popup().set_item_icon(3, show_hidden_icon())
			update_current_list()
		2:
			save_project()
		3:
			load_project()
		4:
			get_parent().get_node("Settings").popup_centered()

func show_hidden_icon():
	if model.show_hidden:
		return icons["visible"]
	else:
		return icons["hidden"]

func add_new_task():
	if model.cur_list > -1:
		var task = Task.new()
		model.lists[model.cur_list].tasks.append(task)
		$TaskList.add_task(task)
	elif model.lists.size() == 0:
		open_new_list_panel()
		
func move_task(task, distance):
	var index = model.lists[model.cur_list].tasks.find(task)
	model.lists[model.cur_list].tasks.remove(index)
	model.lists[model.cur_list].tasks.insert(
		clamp(index + distance, 0, model.lists[model.cur_list].tasks.size()), task)
	update_current_list()

func delete_task(task):
	var index = model.lists[model.cur_list].tasks.find(task)
	model.lists[model.cur_list].tasks.remove(index)
	update_current_list()

func add_new_list(list_name):
	$NewList.visible = false
	var new_list = List.new()
	new_list.init(list_name)
	model.lists.append(new_list)
	CurList.add_item(list_name)
	CurList.select(CurList.get_item_count() - 1)
	model.cur_list = CurList.get_item_count() - 1
	update_current_list()

func open_new_list_panel():
	$NewList/ListName.text = ""
	$NewList.visible = true
	$NewList/ListName.grab_focus()

func new_list_done_pressed():
	add_new_list($NewList/ListName.text)
	
func close_new_list_panel():
	$NewList.visible = false
			
func update_lists():
	$Controls/List.clear()
	for list in model.lists:
		$Controls/List.add_item(list.list_name)

func show_list(index):
	if index == -1:
		$TaskList.clear()
	elif index < model.lists.size():
		model.cur_list = index
		$TaskList.show_list(model.lists[index], model.show_hidden)
	else:
		$TaskList.clear()

func update_current_list():
	show_list(CurList.selected)

func clear_completed_tasks():
	model.clear_completed_tasks_in_list(CurList.selected)
	update_current_list()

func save_project():
	var file = File.new()
	if file.open(data_file, file.WRITE) == OK:
		var data = model.serialize()
		file.store_var(data)
		file.close()
		print("tasks_saved")
	else:
		print("error_saving_tasks")

func load_project():
	var file = File.new()
	if file.open(data_file, file.READ) == OK:
		model.deserialize(file.get_var())
		update_lists()
		$Controls/List.select(model.cur_list)
		show_list(model.cur_list)
		file.close()
	else:
		update_lists()
		update_current_list()
		
func reset_project():
	model = Model.new()
	save_project()
	load_project()


