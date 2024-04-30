extends Node2D

enum {EMPTY, BLACK, WHITE}
enum State {WAITING_FOR_ORBIT, CHOOSE_MOVING, MOVING, LAYING, GAME_OVER}
var board
var current_player
var state

var chosen_node
var nodes_to_move = []
var outerchain = [
	[0, 0], [1, 0], [2, 0], [3, 0],
	[3, 1], [3, 2], [3, 3],
	[2, 3], [1, 3], [0, 3],
	[0, 2], [0, 1], [0, 0]
]
var innerchain = [[1, 1], [2, 1], [2, 2], [1, 2], [1, 1]]
signal winner_declared(winner)
signal state_changed(state)
signal player_changed(player)

# Called when the node enters the scene tree for the first time.
func _ready():
	board = [
		[EMPTY, EMPTY, EMPTY, EMPTY],
		[EMPTY, EMPTY, EMPTY, EMPTY],
		[EMPTY, EMPTY, EMPTY, EMPTY],
		[EMPTY, EMPTY, EMPTY, EMPTY]
		]
	current_player = BLACK
	state = State.LAYING

func switch_player():
	if current_player == BLACK:
		current_player = WHITE
	else:
		current_player = BLACK
	player_changed.emit(current_player)
		
func check_winner():	
	var rows = check_rows()
	if rows != EMPTY:
		return rows
		
	var cols = check_columns()
	if cols != EMPTY:
		return cols
		
	var diagonals = check_diagonals()
	if diagonals != EMPTY:
		return diagonals
	
	return EMPTY
	
func check_rows():
	var winner = EMPTY
	for i in range(0, 4):
		if winner != EMPTY:
			return winner
		else:
			for j in range(1, 4):
				if board[i][j] == EMPTY or board[i][j] != board[i][j - 1]:
					winner = EMPTY
					break
				else:
					winner = board[i][j]
	return winner

func check_columns():
	var winner = EMPTY
	for i in range(0, 4):
		if winner != EMPTY:
			return winner
		else:
			for j in range(1, 4):
				if board[j][i] == EMPTY or board[j][i] != board[j - 1][i]:
					winner = EMPTY
					break
				else:
					winner = board[j][i]
	return winner
	
func check_diagonals():
	if board[0][0] == board[1][1] and board[1][1] == board[2][2] and board[2][2] == board[3][3]:
		return board[0][0]
		
	if board[0][3] == board[1][2] and board[1][2] == board[2][1] and board[2][1] == board[3][0]:
		return board[0][3]
		
	return EMPTY

func orbit():
	var new_board = board.duplicate(true)
	
	for i in range(1, outerchain.size()):
		var row = outerchain[i][0]
		var col = outerchain[i][1]
		
		var prev_row = outerchain[i - 1][0]
		var prev_col = outerchain[i - 1][1]
		
		new_board[row][col] = board[prev_row][prev_col]
		
		var node = set_node_string(outerchain[i])
		set_square_visible(node, new_board[row][col])
	
	for i in range(1, innerchain.size()):
		var row = innerchain[i][0]
		var col = innerchain[i][1]
		
		var prev_row = innerchain[i - 1][0]
		var prev_col = innerchain[i - 1][1]
		
		new_board[row][col] = board[prev_row][prev_col]
		
		var node = set_node_string(innerchain[i])
		set_square_visible(node, new_board[row][col])
		
	board = new_board

func _on_orbit_pressed():
	if state == State.WAITING_FOR_ORBIT:
		orbit()
		var winner = check_winner()
		if winner != EMPTY:
			state = State.GAME_OVER
			winner_declared.emit(winner)
		else:
			switch_player()
			state = State.CHOOSE_MOVING
			state_changed.emit(state)

func _on_square_input_event(viewport, event, shape_idx, square_pos):
	if event.is_action_pressed("mouse_left"):
		handle_square_clicked(square_pos)

func handle_square_clicked(square_pos):
	if state == State.LAYING:
		if board[square_pos[0]][square_pos[1]] == EMPTY:
			board[square_pos[0]][square_pos[1]] = current_player
			var node = set_node_string(square_pos)
			set_square_visible(node, current_player)
			state = State.WAITING_FOR_ORBIT
			state_changed.emit(state)
	elif state == State.CHOOSE_MOVING: # mandatory in case user forgets to choose a piece of the opponent
		if board[square_pos[0]][square_pos[1]] != EMPTY and board[square_pos[0]][square_pos[1]] != current_player:
			set_movable_nodes(square_pos)
			chosen_node = square_pos
			state = State.MOVING
			state_changed.emit(state)
	elif state == State.MOVING: 
		# in case user changes opponent's piece to move
		if board[square_pos[0]][square_pos[1]] != EMPTY and board[square_pos[0]][square_pos[1]] != current_player:
			for square in nodes_to_move:
				set_square_modulate(set_node_string(square), false)
			chosen_node = square_pos
			set_movable_nodes(square_pos)
		else:
			if [square_pos[0], square_pos[1]] in nodes_to_move:
				board[square_pos[0]][square_pos[1]] = board[chosen_node[0]][chosen_node[1]]
				set_square_visible(set_node_string(square_pos), board[chosen_node[0]][chosen_node[1]])
				
				board[chosen_node[0]][chosen_node[1]] = EMPTY
				set_square_visible(set_node_string(chosen_node), EMPTY)
				
				for square in nodes_to_move:
					set_square_modulate(set_node_string(square), false)
				state = State.LAYING
				state_changed.emit(state)

func set_movable_nodes(square_pos):
	nodes_to_move = []
	
	if square_pos[0] > 0 and board[square_pos[0] - 1][square_pos[1]] == EMPTY:
		nodes_to_move.append([square_pos[0] - 1, square_pos[1]])
		set_square_modulate(set_node_string([square_pos[0] - 1, square_pos[1]]), true)
	
	if square_pos[0] < board.size() - 1 and board[square_pos[0] + 1][square_pos[1]] == EMPTY:
		nodes_to_move.append([square_pos[0] + 1, square_pos[1]])
		set_square_modulate(set_node_string([square_pos[0] + 1, square_pos[1]]), true)
	
	if square_pos[1] > 0 and board[square_pos[0]][square_pos[1] - 1] == EMPTY:
		nodes_to_move.append([square_pos[0], square_pos[1] - 1])
		set_square_modulate(set_node_string([square_pos[0], square_pos[1] - 1]), true)
		
	if square_pos[1] < board.size() - 1 and board[square_pos[0]][square_pos[1] + 1] == EMPTY:
		nodes_to_move.append([square_pos[0], square_pos[1] + 1])
		set_square_modulate(set_node_string([square_pos[0], square_pos[1] + 1]), true)

func set_square_visible(node, color):
	if color == BLACK:
		get_node(node + "/Players/Black").visible = true
		get_node(node + "/Players/White").visible = false
	elif color == WHITE:
		get_node(node + "/Players/Black").visible = false
		get_node(node + "/Players/White").visible = true
	else:
		get_node(node + "/Players/Black").visible = false
		get_node(node + "/Players/White").visible = false

func set_square_modulate(node, to):
	if to:
		get_node(node + "/Square").set_modulate(Color(0, 1, 1))
	else:
		get_node(node + "/Square").set_modulate(Color(1, 1, 1))

func set_node_string(pos):
	return "Row" + str(pos[0]) + "/Square" + str(pos[1])
