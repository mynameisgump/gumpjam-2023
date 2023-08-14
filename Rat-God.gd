extends Node3D

@onready var animation: AnimationPlayer = $AnimationPlayer;

# Called when the node enters the scene tree for the first time.
var cur_state = "Noddin";

func wiggle():
	cur_state = "ElderCall";
	animation.play("CallToTheElderGods");

func _ready():
	animation.play("Noddin");


func _process(delta):
	if cur_state == "ElderCall" and not animation.is_playing():
		cur_state = "Noddin"
		animation.play("Noddin")
