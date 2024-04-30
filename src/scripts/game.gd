extends Node2D

var board_node = preload("res://scenes/board.tscn")
var board_instance
var stage
var player_label
var play_again

# Called when the node enters the scene tree for the first time.
func _ready():
	stage = $MarginContainer/VBoxContainer/Stage
	player_label = $MarginContainer/VBoxContainer/CurrentPlayer
	play_again = $MarginContainer/VBoxContainer/CenterContainer/PlayAgain
	board_instance = board_node.instantiate()
	add_child(board_instance)
	board_instance.state_changed.connect(_on_state_changed)
	board_instance.player_changed.connect(_on_player_changed)
	board_instance.winner_declared.connect(_on_winner_declared)
	
func _on_state_changed(state):
	if state == board_instance.State.WAITING_FOR_ORBIT:
		stage.text = "Stage: Orbiting\nHit the red button in the middle of the board to orbit the pieces"
	elif state == board_instance.State.LAYING:
		stage.text = "Stage: Laying\nChoose an empty square to lay your piece"
	elif state == board_instance.State.CHOOSE_MOVING:
		stage.text = "Stage: Moving\nChoose a piece from your opponent to move to one of its neighboring squares"
	elif state == board_instance.State.MOVING:
		stage.text = "Stage: Moving\nNow choose one of the highlighted square to move the selected piece to or pick another one"

func _on_player_changed(player):
	if player == board_instance.BLACK:
		player_label.text = "Current player: BLACK"
	elif player == board_instance.WHITE:
		player_label.text = "Current player: WHITE"

func _on_winner_declared(winner):
	player_label.text = "WINNER FOUND"
	if winner == board_instance.BLACK:
		stage.text = "BLACK has won the game\nHit the button below for another round"
	elif winner == board_instance.WHITE:
		stage.text = "WHITE has won the game\nHit the button below for another round"
	play_again.show()
		
func _on_play_again_pressed():
	play_again.hide()
	remove_child(board_instance)
	board_instance.queue_free()
	
	board_instance = board_node.instantiate()
	add_child(board_instance)
	board_instance.state_changed.connect(_on_state_changed)
	board_instance.player_changed.connect(_on_player_changed)
	board_instance.winner_declared.connect(_on_winner_declared)
	stage.text = "Stage: Laying\nChoose an empty square to lay your piece"
	player_label.text = "Current player: BLACK"
