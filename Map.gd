extends Node

var player_spawn = preload("res://Scenes/Player/PlayerTemplate.tscn")
var last_world_state = 0

var world_state_buffer = []
var interpolation_offset = 100

func spawn_new_player(player_id, spawn_position):
	if get_tree().get_network_unique_id() == player_id:
		pass
	else:
		if not get_node("Instances/OtherPlayers").has_node(str(player_id)):
			var new_player = player_spawn.instance()
			new_player.translation = spawn_position
			new_player.name = str(player_id)
			get_node("Instances/OtherPlayers").add_child(new_player)

func despawn_player(player_id):
	yield(get_tree().create_timer(0.2), "timeout")
	print("removing player: " + str(player_id))
	get_node("Instances/OtherPlayers/" + str(player_id)).queue_free()

func _physics_process(delta):
	var render_time = OS.get_system_time_msecs() - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[2].T:
			world_state_buffer.remove(0)
		if world_state_buffer.size() > 2:
			var interpolation_factor = float(render_time - world_state_buffer[1]["T"]) / float(world_state_buffer[2]["T"] - world_state_buffer[1]["T"])
			for player in world_state_buffer[2].keys():
				if str(player) == "T" or player == get_tree().get_network_unique_id() or not world_state_buffer[1].has(player):
					continue
				if get_node("Instances/OtherPlayers").has_node(str(player)):
					var player_instance = get_node("Instances/OtherPlayers/" + str(player))
					var new_position = lerp(world_state_buffer[1][player]["P"], world_state_buffer[2][player]["P"], interpolation_factor)
					var new_rotation_x = lerp(world_state_buffer[1][player]["Rx"], world_state_buffer[2][player]["Rx"], interpolation_factor)
					var new_rotation_z = lerp(world_state_buffer[1][player]["Rz"], world_state_buffer[2][player]["Rz"], interpolation_factor)
					var movement_animation = lerp(world_state_buffer[1][player]["Am"], world_state_buffer[2][player]["Am"], interpolation_factor)
					var new_rotation = [new_rotation_x, new_rotation_z]
					player_instance.move_player(new_position, new_rotation, movement_animation)
				else:
					print("spawning player")
					spawn_new_player(player, world_state_buffer[2][player]["P"])
		elif render_time > world_state_buffer[1].T:
			var extrarpolation_factor = float(render_time - world_state_buffer[0]["T"]) / float(world_state_buffer[1]["T"] - world_state_buffer[0]["T"]) - 1.00
			for player in world_state_buffer[2].keys():
				if str(player) == "T" or player == get_tree().get_network_unique_id() or not world_state_buffer[1].has(player):
					continue
				if get_node("Instances/OtherPlayers").has_node(str(player)):
					var position_delta = (world_state_buffer[1][player]["P"] - world_state_buffer[0][player]["P"])
					var rotation_x_delta = (world_state_buffer[1][player]["Rx"] - world_state_buffer[0][player]["Rx"])
					var rotation_z_delta = (world_state_buffer[1][player]["Rz"] - world_state_buffer[0][player]["Rz"])
					var movement_animation = (world_state_buffer[1][player]["Am"] - world_state_buffer[0][player]["Am"])
					var new_position = world_state_buffer[1][player]["P"] + (position_delta * extrarpolation_factor)
					var new_rotation = [rotation_x_delta, rotation_z_delta]
					get_node("Instances/OtherPlayers/" + str(player)).move_player(new_position, new_rotation, movement_animation)
				else:
					print("spawning player")
					spawn_new_player(player, world_state_buffer[2][player]["P"])
		
		

func update_world_state(world_state):
	if world_state["T"] > last_world_state:
		last_world_state = world_state["T"]
		world_state_buffer.append(world_state)

