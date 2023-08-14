extends Node3D

@onready var player = $Player;
@onready var enemies : Node3D = $Enemies;
@onready var spawn_timer: Timer = $SpawnTimer;
# @onready var main_music: AudioStreamPlayer = $ThemeMusic;
@onready var wave_timer: Timer = $WaveTimer
@onready var music_nodes: Node3D = $Music
@onready var starting_wave_sound: AudioStreamPlayer = $WaveStart;
@onready var rat_gods: Node3D = $"Rat Gods";

var Enemy = preload ("res://scenes/enemies/enemy.tscn");

var total_rats = 1;
var total_burning = 0;

var wave_start = false;
var current_wave = 0;
var wave_enemies = 1;
var enemies_spawned = 0;
var current_track = 0;
var spawn_timer_min = 0.5;


func get_burning():
	var temp_burning = 0
	for e in enemies.get_children():
		if e.on_fire:
			temp_burning += 1 
	total_burning = temp_burning;
	player.set_combo(total_burning+1)
	
func new_wave():
	starting_wave_sound.play()
	enemies_spawned = 0;
	current_wave += 1;
	wave_enemies = (current_wave+1) * 10;
	wave_start = true;
	spawn_timer.wait_time = max(0.01, 2 - current_wave*0.25);
	player.set_wave(current_wave+1);
	get_node("Music/Music"+str(current_track)).stop();
	current_track += 1;
	if current_track >= len(music_nodes.get_children()):
		current_track = 0
	get_node("Music/Music"+str(current_track)).play();
	
	for rat_god in rat_gods.get_children():
		rat_god.wiggle();
	
func _ready():
	randomize()
	if wave_start == false:
		wave_timer.start();
		wave_start = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_tree().call_group('enemy', "update_target_location", player.global_transform.origin);
	get_tree().call_group('enemy', "update_rotation", player.global_transform.origin);
	get_burning()

	
	if enemies_spawned >= wave_enemies and enemies.get_children().size() == 0:
		wave_start = false;
		new_wave();
		
	if wave_start and enemies_spawned < wave_enemies:
		if spawn_timer.is_stopped():
			spawn_timer.start();
			var x = randf_range(-30,30);
			var z = randf_range(-30,30);
			var new_rato: CharacterBody3D = Enemy.instantiate();
			enemies.add_child(new_rato);
			new_rato.set_position(Vector3(x,1.544,z));
			new_rato.connect("death",player._on_enemy_death);
			new_rato.connect("burned",player._on_enemy_burned);
			total_rats += 1;
			enemies_spawned += 1;
			print(total_rats);



func _on_player_death():
	get_node("Music/Music"+str(current_track)).stop();
	
