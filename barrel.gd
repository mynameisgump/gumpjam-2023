extends RigidBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer;
@onready var burning_timer: Timer = $BurningTimer;
@onready var burn_tick_timer: Timer = $BurnTickTimer

var health = 100

func damage_flamer(DAMAGE: int):
	health -= DAMAGE
	animation_player.stop();
	animation_player.play("Hurt");
	burning_timer.start();

func damage_afterburn(DAMAGE: int):
	health -= DAMAGE
	animation_player.stop();
	animation_player.play("Afterburn");

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if burning_timer.is_stopped() == false:
		print("IM BURNING FUCK")
		if burn_tick_timer.is_stopped():
			damage_afterburn(5)
			burn_tick_timer.start()
			
		
	if health <= 0:
		queue_free();

	
