extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")

var player: Node3D
var health := 100.0
var stamina := 100.0
var hunger := 100.0
var selected_slot := 0

@onready var compass_label: Label = $Compass/CompassLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var temp_label: Label = $TopRight/TempLabel
@onready var health_bar: ProgressBar = $StatusPanel/HealthBar
@onready var stamina_bar: ProgressBar = $StatusPanel/StaminaBar
@onready var hunger_bar: ProgressBar = $StatusPanel/HungerBar
@onready var hotbar_slots := [
	$Hotbar/Slot1,
	$Hotbar/Slot2,
	$Hotbar/Slot3,
	$Hotbar/Slot4,
	$Hotbar/Slot5,
	$Hotbar/Slot6,
	$Hotbar/Slot7,
	$Hotbar/Slot8
]

func _ready() -> void:
	player = get_node_or_null(player_path)
	_update_hotbar()

func _process(delta: float) -> void:
	_update_compass()
	_update_survival(delta)
	_update_bars()
	_update_clock()
	_handle_hotbar_input()

func _update_compass() -> void:
	if player == null:
		return
	var yaw := fposmod(rad_to_deg(player.rotation.y), 360.0)
	var heading := int(round(yaw))
	var direction := "N"
	if yaw >= 22.5 and yaw < 67.5:
		direction = "NW"
	elif yaw >= 67.5 and yaw < 112.5:
		direction = "W"
	elif yaw >= 112.5 and yaw < 157.5:
		direction = "SW"
	elif yaw >= 157.5 and yaw < 202.5:
		direction = "S"
	elif yaw >= 202.5 and yaw < 247.5:
		direction = "SE"
	elif yaw >= 247.5 and yaw < 292.5:
		direction = "E"
	elif yaw >= 292.5 and yaw < 337.5:
		direction = "NE"
	compass_label.text = "|  N  |  NE  |  E  |  SE  |  S  |  SW  |  W  |  NW  |    %s  %03d°" % [direction, heading]

func _update_survival(delta: float) -> void:
	var sprinting := Input.is_action_pressed("sprint")
	if sprinting:
		stamina = max(0.0, stamina - delta * 16.0)
	else:
		stamina = min(100.0, stamina + delta * 8.5)
	hunger = max(0.0, hunger - delta * 0.35)
	if hunger <= 0.0:
		health = max(0.0, health - delta * 2.0)

func _update_bars() -> void:
	health_bar.value = health
	stamina_bar.value = stamina
	hunger_bar.value = hunger

func _update_clock() -> void:
	var seconds := int(Time.get_ticks_msec() / 1000.0)
	var hour := 8 + int(seconds / 60) % 12
	var minute := int(seconds) % 60
	time_label.text = "%02d:%02d AM" % [hour, minute]
	temp_label.text = "21.6 °C"

func _handle_hotbar_input() -> void:
	for i in range(8):
		if Input.is_key_pressed(KEY_1 + i):
			selected_slot = i
			_update_hotbar()

func _update_hotbar() -> void:
	var items := ["1\nTool", "2\nKnife", "3\nMed", "4\nWater", "5", "6", "7", "8"]
	for i in range(hotbar_slots.size()):
		var slot: PanelContainer = hotbar_slots[i]
		var label: Label = slot.get_node("Label")
		label.text = items[i]
		if i == selected_slot:
			slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			slot.modulate = Color(0.55, 0.55, 0.55, 0.75)
