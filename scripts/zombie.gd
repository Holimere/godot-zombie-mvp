extends CharacterBody3D

var speed: float = 3.2
var health: int = 80
var attack_range: float = 1.4
var attack_damage: int = 10
var attack_cooldown: float = 1.0
var _can_attack: bool = true

@onready var player: Node = get_tree().current_scene.get_node("Player")

func _physics_process(delta: float) -> void:
    if not player:
        return
    var to_player := (player.global_transform.origin - global_transform.origin)
    var flat := Vector3(to_player.x, 0, to_player.z)
    if flat.length() > attack_range:
        var dir := flat.normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
        look_at(player.global_transform.origin, Vector3.UP)
        move_and_slide()
    else:
        velocity = Vector3.ZERO
        move_and_slide()
        _try_attack()

func _try_attack() -> void:
    if not _can_attack:
        return
    _can_attack = false
    if player and player.has_method("apply_damage"):
        player.apply_damage(attack_damage)
    await get_tree().create_timer(attack_cooldown).timeout
    _can_attack = true

func apply_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        queue_free()
