extends Node3D

@export var zombie_scene: PackedScene
@export var spawn_interval := 5.0
@export var max_alive := 10
@export var spawn_radius := 15.0

var _timer := 0.0

func _ready():
    if zombie_scene == null:
        zombie_scene = load("res://scenes/Zombie.tscn")

func _process(delta):
    _timer += delta
    if _timer >= spawn_interval:
        _timer = 0.0
        _try_spawn()

func _try_spawn():
    var alive = 0
    for c in get_tree().get_nodes_in_group("Zombie"):
        alive += 1
    if alive >= max_alive:
        return
    var angle = randf() * TAU
    var pos = Vector3(cos(angle), 0, sin(angle)) * spawn_radius
    var z = zombie_scene.instantiate()
    z.global_transform.origin = global_transform.origin + pos
    get_tree().current_scene.add_child(z)
