extends Node3D

@export var terrain_size: int = 180
@export var terrain_resolution: int = 180
@export var height_scale: float = 18.0
@export var tree_count: int = 450
@export var rock_count: int = 120

func _ready() -> void:
	generate_terrain()
	generate_forest()
	generate_rocks()
	generate_water()

func generate_terrain() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = terrain_resolution
	plane.subdivide_width = terrain_resolution

	var terrain := MeshInstance3D.new()
	terrain.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.32, 0.16)
	terrain.material_override = mat

	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02

	var arrays := plane.get_mesh_arrays()
	var verts = arrays[Mesh.ARRAY_VERTEX]

	for i in range(verts.size()):
		var v = verts[i]
		var h = noise.get_noise_2d(v.x, v.z) * height_scale
		v.y = h
		verts[i] = v

	arrays[Mesh.ARRAY_VERTEX] = verts

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	terrain.mesh = arr_mesh

	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	collision.shape = arr_mesh.create_trimesh_shape()
	body.add_child(collision)

	add_child(terrain)
	add_child(body)

func generate_forest() -> void:
	var rng := RandomNumberGenerator.new()
	for i in tree_count:
		var tree := Node3D.new()

		var trunk := MeshInstance3D.new()
		trunk.mesh = CylinderMesh.new()
		trunk.scale = Vector3(0.35, 2.5, 0.35)

		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.3, 0.2, 0.1)
		trunk.material_override = trunk_mat

		var leaves := MeshInstance3D.new()
		leaves.mesh = SphereMesh.new()
		leaves.position.y = 3.5
		leaves.scale = Vector3(2.2, 2.4, 2.2)

		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.1, 0.4, 0.1)
		leaves.material_override = leaf_mat

		tree.add_child(trunk)
		tree.add_child(leaves)

		tree.position = Vector3(
			rng.randf_range(-terrain_size / 2, terrain_size / 2),
			0,
			rng.randf_range(-terrain_size / 2, terrain_size / 2)
		)

		add_child(tree)

func generate_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	for i in rock_count:
		var rock := MeshInstance3D.new()
		rock.mesh = SphereMesh.new()
		rock.scale = Vector3(
			rng.randf_range(0.6, 2.5),
			rng.randf_range(0.4, 1.6),
			rng.randf_range(0.6, 2.5)
		)

		var rock_mat := StandardMaterial3D.new()
		rock_mat.albedo_color = Color(0.35, 0.35, 0.35)
		rock.material_override = rock_mat

		rock.position = Vector3(
			rng.randf_range(-terrain_size / 2, terrain_size / 2),
			0.3,
			rng.randf_range(-terrain_size / 2, terrain_size / 2)
		)

		add_child(rock)

func generate_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(terrain_size * 0.4, terrain_size * 0.25)
	water.mesh = plane

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.3, 0.5, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.material_override = mat

	water.rotation_degrees.x = -90
	water.position = Vector3(15, 1.5, -20)

	add_child(water)
