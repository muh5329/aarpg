extends CharacterBody3D
var game: Node3D
var art: Dictionary
var speed = 5.2
var hp = 100.0
var facing = Vector3.FORWARD
var cooldown = 0.0
var swing = 0.0
var dodge = 0.0
var dodge_cd = 0.0
var invulnerable = 0.0
var gait = 0.0
var weapon = 0
var potions = 3
var gold = 0
var travel = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = .3
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = .8
	add_child(shape)
	art = Art.humanoid(self,Color("65352e"))

func _physics_process(dt: float) -> void:
	cooldown = maxf(0,cooldown-dt)
	dodge_cd = maxf(0,dodge_cd-dt)
	invulnerable = maxf(0,invulnerable-dt)
	swing = maxf(0,swing-dt)
	dodge = maxf(0,dodge-dt)
	var input = Input.get_vector("left","right","up","down") if not game.dialogue_open and not game.paused and game.survival.menu=="" else Vector2.ZERO
	var right = game.camera.global_basis.x
	right.y = 0
	right = right.normalized()
	var back = Vector3(-right.z,0,right.x)
	var direction = right * input.x + back * input.y
	if direction.length() > .1 and swing <= 0: facing = direction.normalized()
	if Input.is_action_just_pressed("dodge") and dodge_cd <= 0 and direction.length()>.1 and not game.dialogue_open and game.survival.stamina>=22:
		game.survival.stamina-=22
		dodge = .22
		dodge_cd = .9
		invulnerable = .35
	if game.paused: direction = Vector3.ZERO
	velocity.x = direction.x * (15.0 if dodge>0 else speed*1.55 if Input.is_action_pressed("sprint") and game.survival.stamina>1 else speed)
	velocity.z = direction.z * (15.0 if dodge>0 else speed*1.55 if Input.is_action_pressed("sprint") and game.survival.stamina>1 else speed)
	velocity.y = -8
	var before = position
	move_and_slide()
	travel += Vector2(position.x-before.x,position.z-before.z).length()
	position.x = clampf(position.x,-85,85)
	position.z = clampf(position.z,-98,86)
	gait += dt * direction.length()*11
	art.rig.rotation.y = lerp_angle(art.rig.rotation.y,atan2(-facing.x,-facing.z),dt*18)
	art.left.rotation.x = sin(gait)*.55*direction.length()
	art.right.rotation.x = -sin(gait)*.55*direction.length()
	art.rig.position.y = abs(sin(gait))*.045*direction.length()
	art.rig.rotation.z = -.2 if dodge>0 else 0.0
	art.hand.rotation.y = sin((1.0-swing/.32)*PI)*-2.2 if swing>0 else 0.0
	art.sword.visible = weapon == 0
	art.bow.visible = weapon == 1
	if game.paused or game.dialogue_open or game.survival.menu!="" or game.survival.placing: return
	if Input.is_action_just_pressed("swap"): weapon = 1-weapon
	if Input.is_action_just_pressed("sword"): attack(0,false)
	if Input.is_action_just_pressed("bow"): attack(1,false)
	if Input.is_action_just_pressed("attack"): attack(weapon,true)

func attack(kind: int, mouse: bool) -> void:
	if cooldown>0: return
	if game.survival.stamina<9: game.toast("Exhausted · recover stamina"); return
	if kind==1 and game.survival.inventory.arrows<=0: game.toast("No arrows · craft more with C"); return
	game.survival.stamina-=9
	if kind==1: game.survival.inventory.arrows-=1
	weapon = kind
	if mouse:
		var cursor = get_viewport().get_mouse_position()
		var origin = game.camera.project_ray_origin(cursor)
		var dir = game.camera.project_ray_normal(cursor)
		var point = Plane(Vector3.UP,.8).intersects_ray(origin,dir)
		if point != null: facing = (point-global_position).normalized(); facing.y = 0; facing = facing.normalized()
	else:
		var nearest = game.nearest_enemy(position,11 if kind==1 else 3.2)
		if nearest != null: facing = (nearest.position-position).normalized(); facing.y=0
	cooldown = .42 if kind==0 else .58
	swing = .32
	if kind==0:
		game.sound(220,.08)
		game.slash(position+Vector3(0,.85,0),facing)
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var delta = enemy.position-position
			if delta.length()<2.5 and facing.dot(delta.normalized())>0.1 and game.clear_line(position,enemy.position):
				enemy.hurt(40 if game.survival.upgraded else 26,0,facing)
	else:
		game.sound(660,.06)
		game.shoot(position+Vector3(0,.85,0)+facing*.1,facing)

func hurt(amount: float) -> void:
	if invulnerable>0: return
	hp -= amount
	game.shake=.3
	invulnerable = .65
	game.flash = .22
	if hp<=0:
		hp=100
		position=game.survival.respawn
		game.survival.hunger=maxf(45,game.survival.hunger)
		game.survival.thirst=maxf(45,game.survival.thirst)
		game.survival.stamina=100
		potions=maxi(1,potions)
		game.toast("The lantern calls you home. Your quest is preserved.")
		game.deaths += 1

func heal() -> void:
	if hp>=100: return
	if game.survival.inventory.bandage>0: game.survival.inventory.bandage-=1
	elif potions>0: potions-=1
	else: game.toast("No bandages or tonics. Craft a bandage with C."); return
	hp=minf(100,hp+55)
	game.toast("Bandaged wounds · +55 vitality")
