extends CharacterBody3D

@onready var cam: Camera3D = $Camera3D
@onready var hud: Node = null

var speed := 6.0
var sprint_speed := 10.0
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity")
var jump_velocity := 4.5
var mouse_sensitivity := 0.002

var health := 100
var stamina := 100.0
var stamina_recover_rate := 20.0
var stamina_drain_rate := 25.0

var ammo_in_mag := 12
var mag_size := 12
var reserve_ammo := 36
var fire_cooldown := 0.2
var _can_fire := true
var damage := 34

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    var root = get_tree().current_scene
    if root:
        hud = root.get_node_or_null("HUD")
    _update_hud()

func _input(event):
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        cam.rotate_x(-event.relative.y * mouse_sensitivity)
        cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -89, 89)
    if Input.is_action_just_pressed("pause"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
    if Input.is_action_just_pressed("reload"):
        _reload()

func _physics_process(delta):
    var input_dir = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    ).normalized()
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var current_speed = speed

    if Input.is_action_pressed("sprint") and stamina > 0.0 and input_dir.length() > 0.0:
        current_speed = sprint_speed
        stamina = max(0.0, stamina - stamina_drain_rate * delta)
    else:
        stamina = min(100.0, stamina + stamina_recover_rate * delta)

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity

    velocity.x = direction.x * current_speed
    velocity.z = direction.z * current_speed
    move_and_slide()

    if Input.is_action_pressed("fire"):
        _try_fire()

    _update_hud()

func _try_fire():
    if not _can_fire:
        return
    if ammo_in_mag <= 0:
        return
    ammo_in_mag -= 1
    _can_fire = false
    _shoot_ray()
    await get_tree().create_timer(fire_cooldown).timeout
    _can_fire = true

func _shoot_ray():
    var from = cam.global_transform.origin
    var to = from + cam.global_transform.basis.z * -1 * 100.0
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var result = space_state.intersect_ray(query)
    if result and result.has("collider"):
        var col = result.collider
        if col.is_in_group("Zombie") or (col.get_parent() and col.get_parent().is_in_group("Zombie")):
            var zombie = col if col.is_in_group("Zombie") else col.get_parent()
            if "apply_damage" in zombie:
                zombie.apply_damage(damage)

func _reload():
    var needed = mag_size - ammo_in_mag
    var to_load = min(needed, reserve_ammo)
    ammo_in_mag += to_load
    reserve_ammo -= to_load
    _update_hud()

func apply_damage(amount:int):
    health -= amount
    if health <= 0:
        health = 0
        get_tree().reload_current_scene()
    _update_hud()

func _update_hud():
    if hud:
        var label = hud.get_node_or_null("Stats")
        if label:
            label.text = "HP: %d | Stam: %d | Ammo: %d/%d" % [health, int(stamina), ammo_in_mag, reserve_ammo]
