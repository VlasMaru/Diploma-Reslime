extends Node2D

# --- ПЕРЕМЕННЫЕ НАСТРОЙКИ ---
@export var width: int = 64
@export var height: int = 64

@export_group("Генерация")
@export var is_cave: bool = true # True - пещеры, False - комнаты (BSP)
@export var min_room_size: int = 6 
@export var fill_percent: int = 45 

# Ссылка на узел TileMapLayer
@export var tile_layer: TileMapLayer 

var rng = RandomNumberGenerator.new()
@export var current_player: CharacterBody2D

func _ready():
	rng.randomize() 
	
	# Автоматический поиск игрока, если он не назначен в инспекторе
	if current_player == null:
		current_player = get_tree().get_first_node_in_group("player")
		
	create_terrain()

# Главная функция генерации
func create_terrain():
	if tile_layer != null:
		tile_layer.clear()
	
	var map_data = []
	
	# Выбираем алгоритм генерации
	if is_cave:
		map_data = generate_cave()
		#map_data = expand_caves_softer(map_data)

	else:
		map_data = generate_bsp()
		
	# Соединяем разрозненные куски
	ensure_connectivity(map_data)
	
	# Отрисовываем карту в TileMapLayer
	draw_map(map_data)
	
	# Используем call_deferred, чтобы спавн произошел в следующем кадре,
	# когда физика уже готова
	call_deferred("spawn_player", map_data)

# --- АЛГОРИТМЫ ГЕНЕРАЦИИ (БЕЗ ИЗМЕНЕНИЙ) ---

func generate_bsp() -> Array:
	var map = []
	for y in range(height):
		var row = []
		for x in range(width): row.append(1)
		map.append(row)
	_split_rect(Rect2(0, 0, width, height), map, 4)
	return map

func _split_rect(rect: Rect2, map: Array, depth: int):
	if depth <= 0 or rect.size.x < min_room_size * 2 or rect.size.y < min_room_size * 2:
		_create_room(rect, map)
		return
	var split_vertical = rect.size.x > rect.size.y
	var split_size = rect.size.x if split_vertical else rect.size.y
	
	var min_bound = min_room_size
	var max_bound = int(split_size) - min_room_size
	if min_bound >= max_bound:
		_create_room(rect, map)
		return
		
	var split_pos = rng.randi_range(min_bound, max_bound)
	if split_vertical:
		_split_rect(Rect2(rect.position.x, rect.position.y, split_pos, rect.size.y), map, depth - 1)
		_split_rect(Rect2(rect.position.x + split_pos, rect.position.y, rect.size.x - split_pos, rect.size.y), map, depth - 1)
	else:
		_split_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, split_pos), map, depth - 1)
		_split_rect(Rect2(rect.position.x, rect.position.y + split_pos, rect.size.x, rect.size.y - split_pos), map, depth - 1)

func _create_room(rect: Rect2, map: Array):
	for y in range(int(rect.position.y) + 1, int(rect.end.y) - 1):
		for x in range(int(rect.position.x) + 1, int(rect.end.x) - 1):
			if y > 0 and y < height - 1 and x > 0 and x < width - 1:
				map[y][x] = 0

func generate_cave() -> Array:
	var map = []
	for y in range(height):
		var row = []
		for x in range(width):
			var is_edge = (x == 0 or x == width-1 or y == 0 or y == height-1)
			row.append(1 if is_edge or rng.randi_range(0, 100) < fill_percent else 0)
		map.append(row)
	for i in range(4): map = _smooth_cave(map)
	return map

func _smooth_cave(old_map: Array) -> Array:
	var new_map = old_map.duplicate(true)
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var walls = 0
			for i in range(-1, 2):
				for j in range(-1, 2): walls += old_map[y+i][x+j]
			if walls > 4: new_map[y][x] = 1
			elif walls < 4: new_map[y][x] = 0
	return new_map

# --- СВЯЗНОСТЬ И ОТРИСОВКА ---

func ensure_connectivity(map: Array):
	var regions = _get_all_regions(map, 0)
	if regions.size() <= 1: return
	for i in range(regions.size() - 1):
		_create_tunnel(map, regions[i][0], regions[i+1][0])

func _get_all_regions(map: Array, tile_type: int) -> Array:
	var regions = []
	var visited = []
	for y in range(height):
		var row = []
		for x in range(width): row.append(false)
		visited.append(row)
	for y in range(height):
		for x in range(width):
			if map[y][x] == tile_type and not visited[y][x]:
				regions.append(_flood_fill(map, x, y, visited))
	return regions

func _flood_fill(map: Array, start_x: int, start_y: int, visited: Array) -> Array:
	var region = []
	var stack = [Vector2i(start_x, start_y)]
	visited[start_y][start_x] = true
	while stack.size() > 0:
		var curr = stack.pop_back()
		region.append(curr)
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next = curr + dir
			if next.x >= 0 and next.x < width and next.y >= 0 and next.y < height:
				if map[next.y][next.x] == 0 and not visited[next.y][next.x]:
					visited[next.y][next.x] = true
					stack.append(next)
	return region

func _create_tunnel(map: Array, start: Vector2i, end: Vector2i):
	var x = start.x
	var y = start.y
	while x != end.x:
		map[y][x] = 0
		x += 1 if end.x > x else -1
	while y != end.y:
		map[y][x] = 0
		y += 1 if end.y > y else -1

# Вместо set_cell используйте set_cells_terrain_connect
func draw_map(map_data: Array):
	tile_layer.clear()
	
	# Собираем список координат для каждой группы
	var walls = []
	var floors = []
	
	for y in range(height):
		for x in range(width):
			if map_data[y][x] == 1:
				walls.append(Vector2i(x, y))
			else:
				floors.append(Vector2i(x, y))
	
	# Рисуем пол (ID 0 - это ваш Terrain Set, ID 1 - это сам Floor в Terrain)
	tile_layer.set_cells_terrain_connect(floors, 0, 1)
	
	# Рисуем стены (ID 0 - это ваш Terrain Set, ID 0 - это сам Wall в Terrain)
	tile_layer.set_cells_terrain_connect(walls, 0, 0)
				
func spawn_player(map_data: Array):
	if current_player == null:
		print("Игрок не найден!")
		return

	var empty_cells = []
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if map_data[y][x] == 0 and map_data[y + 1][x] == 1:
				empty_cells.append(Vector2i(x, y))

	if empty_cells.is_empty():
		print("Нет подходящей точки спавна")
		return

	var random_tile = empty_cells.pick_random()
	var tile_size = tile_layer.tile_set.tile_size
	current_player.global_position = tile_layer.map_to_local(random_tile) + Vector2(tile_size.x / 2, tile_size.y / 2)
	_setup_camera()
	
func _setup_camera():
	await get_tree().process_frame
	if not is_instance_valid(current_player): return
	
	var cam = current_player.get_node_or_null("Camera2D")
	if cam:
		cam.make_current() 
		cam.zoom = Vector2(2.5, 2.5)
		var tile_size = tile_layer.tile_set.tile_size
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = width * tile_size.x
		cam.limit_bottom = height * tile_size.y
		cam.position_smoothing_enabled = true
		cam.reset_smoothing()

# Добавьте эту функцию в конец вашего скрипта
func expand_caves_softer(map: Array) -> Array:
	var new_map = map.duplicate(true)
	
	# Используем RNG для случайности (если rng уже инициализирован в скрипте)
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			# Если это стена
			if map[y][x] == 1:
				# Проверяем соседей
				if map[y-1][x] == 0 or map[y+1][x] == 0 or map[y][x-1] == 0 or map[y][x+1] == 0:
					# Вместо того чтобы ВСЕГДА превращать в пол, 
					# делаем это с определенной вероятностью (например, 60%)
					if rng.randf() < 0.6: 
						new_map[y][x] = 0
	return new_map
