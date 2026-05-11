extends Node3D

@export var terrain_size: int = 320
@export var terrain_resolution: int = 130
@export var mountain_height: float = 42.0
@export var tree_count: int = 420
@export var rock_count: int = 120
@export var grass_count: int = 1800
@export var flower_count: int = 180

var height_noise: FastNoiseLite = FastNoiseLite.new()
var detail_noise: FastNoiseLite = FastNoiseLite.new()
var biome_noise: FastNoiseLite = FastNoiseLite.new()
var path_noise: FastNoiseLite = FastNoiseLite.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	print("Generating playable open world...")
	rng.seed = 777
	_setup_noise()
	generate_terrain()
	generate_lake()
	generate_paths()
	generate_grass()
	generate_flowers()
	generate_forest()
	generate_rocks()
	generate_landmarks()
	print("Open world ready.")

func _setup_noise() -> void:
	height_noise.seed = 1201
	height_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	height_noise.frequency = 0.012
	height_noise.fractal_octaves = 4
	height_noise.fractal_gain = 0.48

	detail_noise.seed = 3307
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail_noise.frequency = 0.045
	detail_noise.fractal_octaves = 3

	biome_noise.seed = 4412
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	biome_noise.frequency = 0.018

	path_noise.seed = 991
	path_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	path_noise.frequency = 0.02

func get_height_at(x: float, z: float) -> float:
	var distance: float = Vector2(x, z).length() / (terrain_size * 0.5)
	var mountain_mask: float = smoothstep(0.18, 0.92, distance)
	var rolling_hills: float = height_noise.get_noise_2d(x, z) * 13.0
	var mountain_detail: float = abs(height_noise.get_noise_2d(x * 0.55 + 500.0, z * 0.55 - 200.0)) * mountain_height * mountain_mask
	var small_detail: float = detail_noise.get_noise_2d(x, z) * 2.2
	var valley: float = -pow(max(0.0, 1.0 - abs(x + z * 0.25) / 70.0), 2.0) * 6.0
	return rolling_hills + mountain_detail + small_detail + valley

func is_path(x: float, z: float) -> bool:
	var main_trail: float = abs(z - sin(x * 0.03) * 18.0)
	var side_trail: float = abs(x * 0.45 + z - 18.0 + path_noise.get_noise_2d(x, z) * 14.0)
	return main_trail < 4.0 or side_trail < 5.0

func is_lake(x: float, z: float) -> bool:
	var p: Vector2 = Vector2(x + 34.0, z + 38.0)
	return p.x * p.x / 2600.0 + p.y * p.y / 1300.0 < 1.0

func generate_terrain() -> void:
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_depth = terrain_resolution
	plane.subdivide_width = terrain_resolution

	var arrays: Array = plane.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(verts.size())

	for i in range(verts.size()):
		var v: Vector3 = verts[i]
		var h: float = get_height_at(v.x, v.z)
		if is_lake(v.x, v.z):
			h = min(h, -1.6)
		v.y = h
		verts[i] = v

		var steep: float = abs(detail_noise.get_noise_2d(v.x * 1.8, v.z * 1.8))
		if is_path(v.x, v.z):
			colors[i] = Color(0.36, 0.29, 0.18, 1.0)
		elif h > 31.0 or steep > 0.76:
			colors[i] = Color(0.38, 0.38, 0.34, 1.0)
		elif h > 18.0:
			colors[i] = Color(0.20, 0.42, 0.16, 1.0)
		else:
			colors[i] = Color(0.12, 0.34, 0.12, 1.0)

	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors

	var arr_mesh: ArrayMesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var terrain: MeshInstance3D = MeshInstance3D.new()
	terrain.name = "Terrain_Mountains_Valleys"
	terrain.mesh = arr_mesh
	terrain.material_override = _terrain_material()
	add_child(terrain)

	var body: StaticBody3D = StaticBody3D.new()
	body.name = "TerrainCollision"
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.shape = arr_mesh.create_trimesh_shape()
	body.add_child(collision)
	add_child(body)

func _terrain_material() -> ShaderMaterial:
	var shader: Shader = Shader.new()
	shader.code = "shader_type spatial;\nvoid fragment(){\n vec3 base = COLOR.rgb;\n float slope = abs(NORMAL.y);\n vec3 rock = vec3(0.34,0.34,0.31);\n ALBEDO = mix(rock, base, smoothstep(0.35,0.78,slope));\n ROUGHNESS = 0.92;\n}\n"
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	return mat

func generate_lake() -> void:
	var lake: MeshInstance3D = MeshInstance3D.new()
	lake.name = "Lake"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(72, 46)
	lake.mesh = mesh
	lake.position = Vector3(-34, 0.15, -38)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.28, 0.45, 0.68)
	mat.roughness = 0.18
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lake.material_override = mat
	add_child(lake)

func generate_paths() -> void:
	for i in range(70):
		var path_marker: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(4.0, 0.04, 2.0)
		path_marker.mesh = mesh
		var x: float = -terrain_size * 0.45 + i * (terrain_size * 0.9 / 70.0)
		var z: float = sin(x * 0.03) * 18.0
		path_marker.position = Vector3(x, get_height_at(x, z) + 0.08, z)
		path_marker.rotation.y = -cos(x * 0.03) * 0.45
		path_marker.material_override = _mat(Color(0.31, 0.24, 0.14))
		add_child(path_marker)

func generate_grass() -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = grass_count
	var blade: QuadMesh = QuadMesh.new()
	blade.size = Vector2(0.18, 0.75)
	multimesh.mesh = blade
	var used: int = 0
	var attempts: int = 0
	while used < grass_count and attempts < grass_count * 8:
		attempts += 1
		var x: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		var z: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		var h: float = get_height_at(x, z)
		if h > 26.0 or is_lake(x, z) or is_path(x, z):
			continue
		var t: Transform3D = Transform3D.IDENTITY
		t.origin = Vector3(x, h + 0.38, z)
		t.basis = Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(rng.randf_range(0.6, 1.2), rng.randf_range(0.5, 1.3), 1.0))
		multimesh.set_instance_transform(used, t)
		used += 1
	multimesh.visible_instance_count = used
	var grass: MultiMeshInstance3D = MultiMeshInstance3D.new()
	grass.name = "Grass_Field"
	grass.multimesh = multimesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.48, 0.16, 1.0)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.material_override = mat
	add_child(grass)

func generate_flowers() -> void:
	for i in range(flower_count):
		var x: float = rng.randf_range(-terrain_size * 0.42, terrain_size * 0.42)
		var z: float = rng.randf_range(-terrain_size * 0.42, terrain_size * 0.42)
		var h: float = get_height_at(x, z)
		if h > 24.0 or is_lake(x, z) or is_path(x, z):
			continue
		var flower: MeshInstance3D = MeshInstance3D.new()
		var mesh: SphereMesh = SphereMesh.new()
		mesh.radius = 0.08
		mesh.height = 0.12
		flower.mesh = mesh
		flower.position = Vector3(x, h + 0.48, z)
		var palette: Array[Color] = [Color(1, 1, 0.65), Color(0.9, 0.8, 1), Color(1, 0.75, 0.7)]
		flower.material_override = _mat(palette[rng.randi_range(0, 2)])
		add_child(flower)

func generate_forest() -> void:
	for i in range(tree_count):
		var x: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		var z: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		var h: float = get_height_at(x, z)
		var biome: float = biome_noise.get_noise_2d(x, z)
		if h > 34.0 or is_lake(x, z) or is_path(x, z) or biome < -0.25:
			continue
		add_tree(Vector3(x, h, z), rng.randf_range(0.8, 1.55), biome > 0.15)

func add_tree(pos: Vector3, scale_factor: float, pine: bool) -> void:
	var tree: Node3D = Node3D.new()
	tree.name = "Pine" if pine else "Broadleaf"
	tree.position = pos
	tree.rotation.y = rng.randf_range(0, TAU)

	var trunk: MeshInstance3D = MeshInstance3D.new()
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.16 * scale_factor
	trunk_mesh.bottom_radius = 0.32 * scale_factor
	trunk_mesh.height = 3.8 * scale_factor
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.9 * scale_factor
	trunk.material_override = _mat(Color(0.25, 0.14, 0.07))
	tree.add_child(trunk)

	if pine:
		for layer in range(3):
			var leaves: MeshInstance3D = MeshInstance3D.new()
			var cone: CylinderMesh = CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = (1.9 - layer * 0.35) * scale_factor
			cone.height = 2.4 * scale_factor
			leaves.mesh = cone
			leaves.position.y = (2.8 + layer * 1.0) * scale_factor
			leaves.material_override = _mat(Color(0.05, 0.26 + layer * 0.03, 0.08))
			tree.add_child(leaves)
	else:
		var leaves: MeshInstance3D = MeshInstance3D.new()
		leaves.mesh = SphereMesh.new()
		leaves.scale = Vector3(1.9, 1.45, 1.9) * scale_factor
		leaves.position.y = 4.1 * scale_factor
		leaves.material_override = _mat(Color(0.08, 0.34, 0.08))
		tree.add_child(leaves)

	add_child(tree)

func generate_rocks() -> void:
	for i in range(rock_count):
		var x: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		var z: float = rng.randf_range(-terrain_size * 0.48, terrain_size * 0.48)
		if is_lake(x, z):
			continue
		var h: float = get_height_at(x, z)
		var rock: MeshInstance3D = MeshInstance3D.new()
		rock.name = "Rock"
		rock.mesh = SphereMesh.new()
		rock.scale = Vector3(rng.randf_range(0.7, 2.6), rng.randf_range(0.35, 1.4), rng.randf_range(0.7, 2.4))
		rock.position = Vector3(x, h + rock.scale.y * 0.25, z)
		rock.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
		rock.material_override = _mat(Color(0.34, 0.34, 0.32))
		add_child(rock)

func generate_landmarks() -> void:
	var spawn_pad: MeshInstance3D = MeshInstance3D.new()
	spawn_pad.name = "Spawn_Camp_Clearance"
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 5.0
	mesh.bottom_radius = 5.0
	mesh.height = 0.12
	spawn_pad.mesh = mesh
	spawn_pad.position = Vector3(0, get_height_at(0, 8) + 0.08, 8)
	spawn_pad.material_override = _mat(Color(0.28, 0.21, 0.12))
	add_child(spawn_pad)

	for i in range(6):
		var angle: float = i * TAU / 6.0
		var log: MeshInstance3D = MeshInstance3D.new()
		var log_mesh: CylinderMesh = CylinderMesh.new()
		log_mesh.height = 3.2
		log_mesh.top_radius = 0.18
		log_mesh.bottom_radius = 0.18
		log.mesh = log_mesh
		log.position = Vector3(cos(angle) * 3.4, get_height_at(cos(angle) * 3.4, 8 + sin(angle) * 3.4) + 0.35, 8 + sin(angle) * 3.4)
		log.rotation_degrees.z = 90
		log.rotation.y = angle
		log.material_override = _mat(Color(0.25, 0.13, 0.06))
		add_child(log)

func _mat(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat
