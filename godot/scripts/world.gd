extends Node3D
class_name WorldStreamer

const SEG := 36.0
const AHEAD := 10
const BEHIND := 2

var segments: Dictionary = {}
var last_index := -999

func biome_at(dist: float) -> String:
	if dist < 400.0:
		return "ПОЛЕ"
	if dist < 800.0:
		return "ПОСАДКА"
	if dist < 1200.0:
		return "СЕЛО"
	if dist < 1700.0:
		return "ПУСТОШЬ"
	return "СУМЕРКИ"

func colors(biome: String) -> Dictionary:
	match biome:
		"ПОСАДКА":
			return {road=Color(0.28, 0.2, 0.12), side=Color(0.12, 0.2, 0.08), prop=Color(0.1, 0.18, 0.07)}
		"СЕЛО":
			return {road=Color(0.32, 0.24, 0.16), side=Color(0.35, 0.28, 0.16), prop=Color(0.55, 0.42, 0.3)}
		"ПУСТОШЬ":
			return {road=Color(0.22, 0.18, 0.14), side=Color(0.18, 0.15, 0.12), prop=Color(0.14, 0.13, 0.12)}
		"СУМЕРКИ":
			return {road=Color(0.16, 0.12, 0.1), side=Color(0.2, 0.1, 0.06), prop=Color(0.35, 0.12, 0.05)}
		_:
			return {road=Color(0.42, 0.3, 0.16), side=Color(0.45, 0.52, 0.18), prop=Color(0.72, 0.62, 0.12)}

func sync(player_z: float, dist: float) -> void:
	var idx := int(floor(-player_z / SEG))
	if idx == last_index:
		_cull(idx)
		return
	last_index = idx
	for i in range(idx - BEHIND, idx + AHEAD):
		if not segments.has(i):
			segments[i] = _make(i, dist + float(i - idx) * SEG)
	_cull(idx)

func _cull(idx: int) -> void:
	var drop: Array = []
	for k in segments.keys():
		if k < idx - BEHIND or k > idx + AHEAD:
			drop.append(k)
	for k in drop:
		(segments[k] as Node).queue_free()
		segments.erase(k)

func reset() -> void:
	for k in segments.keys():
		(segments[k] as Node).queue_free()
	segments.clear()
	last_index = -999

func _make(i: int, dist: float) -> Node3D:
	var biome := biome_at(max(0.0, dist))
	var c := colors(biome)
	var root := Node3D.new()
	root.position = Vector3(0, 0, -float(i) * SEG)
	var side := CSGBox3D.new()
	side.size = Vector3(28, 0.2, SEG)
	side.position.y = -0.05
	var sm := StandardMaterial3D.new()
	sm.albedo_color = c.side
	side.material = sm
	root.add_child(side)
	var road := CSGBox3D.new()
	road.size = Vector3(7.2, 0.12, SEG)
	road.position.y = 0.04
	var rm := StandardMaterial3D.new()
	rm.albedo_color = c.road
	road.material = rm
	root.add_child(road)
	for s in [-1, 1]:
		var p := CSGBox3D.new()
		p.size = Vector3(0.7, _prop_h(biome), 1.1)
		p.position = Vector3(s * (5.2 + randf() * 3.0), p.size.y * 0.5, randf_range(-SEG * 0.35, SEG * 0.35))
		var pm := StandardMaterial3D.new()
		pm.albedo_color = c.prop
		p.material = pm
		root.add_child(p)
	add_child(root)
	return root

func _prop_h(biome: String) -> float:
	match biome:
		"ПОСАДКА":
			return 3.4
		"СЕЛО":
			return 2.2
		"ПУСТОШЬ":
			return 1.6
		"СУМЕРКИ":
			return 2.8
		_:
			return 1.1
