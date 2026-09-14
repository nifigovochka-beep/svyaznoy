extends Node3D

enum Biome { FIELD, FOREST, RUIN }

@export var length := 32.0
@export var biome: Biome = Biome.FIELD

func setup(p_biome: Biome, p_length: float) -> void:
	biome = p_biome
	length = p_length
	_paint()

func _paint() -> void:
	var road_c := Color(0.4, 0.3, 0.18)
	var side_c := Color(0.46, 0.52, 0.2)
	var prop_c := Color(0.7, 0.62, 0.15)
	var prop_h := 1.0
	match biome:
		Biome.FOREST:
			road_c = Color(0.28, 0.2, 0.12)
			side_c = Color(0.12, 0.22, 0.09)
			prop_c = Color(0.1, 0.2, 0.08)
			prop_h = 3.2
		Biome.RUIN:
			road_c = Color(0.2, 0.17, 0.14)
			side_c = Color(0.18, 0.15, 0.12)
			prop_c = Color(0.16, 0.15, 0.14)
			prop_h = 1.8
	_box(Vector3(0, -0.04, 0), Vector3(24, 0.16, length), side_c)
	_box(Vector3(0, 0.04, 0), Vector3(6.8, 0.1, length), road_c)
	_box(Vector3(-6.2, prop_h * 0.5, -length * 0.2), Vector3(0.7, prop_h, 1.0), prop_c)
	_box(Vector3(6.2, prop_h * 0.5, length * 0.15), Vector3(0.7, prop_h, 1.0), prop_c)

func _box(pos: Vector3, size: Vector3, color: Color, ) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	b.material = mat
	m.mesh = b
	m.position = pos
	add_child(m)
