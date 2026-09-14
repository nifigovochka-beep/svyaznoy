extends Control

@onready var fuel_fill: ColorRect = $FuelFill
@onready var speed_label: Label = $Speed
@onready var zone_label: Label = $Zone

func set_values(speed: float, fuel: float, fuel_max: float, zone: String) -> void:
	speed_label.text = "%d км/ч" % int(speed * 3.4)
	zone_label.text = zone
	var w := 180.0 * clampf(fuel / max(fuel_max, 0.01), 0.0, 1.0)
	fuel_fill.size.x = w
	if fuel < 25.0:
		fuel_fill.color = Color(0.75, 0.2, 0.12)
	else:
		fuel_fill.color = Color(0.92, 0.58, 0.12)
