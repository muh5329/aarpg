extends CharacterBody3D
var game: Node3D
var art: Dictionary
var home: Vector3
var hp = 60
var archetype="ashbound"
var move_speed=2.1
var damage=13
var display_name="ASHBOUND"
var dead = false
var timer = 0.0
var windup = 0.0
var hit_flash = 0.0
var gait = 0.0
var health_label: Label3D
var navigator: NavigationAgent3D
var nav_timer=0.0

func _ready() -> void:
	match archetype:
		"shambler": hp=44; move_speed=1.6; damage=10; display_name="HOLLOWED"
		"prowler": hp=65; move_speed=2.9; damage=12; display_name="PROWLER"
		"brute": hp=125; move_speed=1.6; damage=22; display_name="QUARRY BRUTE"
		"warden": hp=190; move_speed=1.85; damage=25; display_name="BLACKTHORN WARDEN"
	collision_layer = 4
	collision_mask = 1
	var c = CollisionShape3D.new()
	var s = CapsuleShape3D.new()
	s.radius=.32
	s.height=1.5
	c.shape=s
	c.position.y=.75
	add_child(c)
	art=Art.humanoid(self,Color("5c6650"),true)
	health_label=Art.label(self,Vector3(0,2.05,0),display_name,Color("d6a689"),18)
	home=position
	navigator=NavigationAgent3D.new()
	add_child(navigator)
	navigator.path_desired_distance=.4
	navigator.target_desired_distance=.8
	navigator.radius=.3

func _physics_process(dt: float) -> void:
	if dead: return
	if position.distance_to(game.player.position)>38:
		visible=false
		return
	visible=true
	health_label.visible=position.distance_to(game.player.position)<9
	if game.paused or game.dialogue_open or game.survival.menu!="": return
	timer=maxf(0,timer-dt)
	hit_flash=maxf(0,hit_flash-dt)
	art.rig.scale=Vector3.ONE*(1.08 if hit_flash>0 else 1.0)
	var delta=game.player.position-position
	delta.y=0
	var dir=delta.normalized()
	var dist=delta.length()
	velocity=Vector3(0,-8,0)
	if windup>0:
		windup-=dt
		art.hand.rotation.x=-windup*2
		if windup<=0:
			if dist<1.9 and game.clear_line(position,game.player.position): game.player.hurt(damage)
			timer=1.3
			health_label.modulate=Color("d6a689")
	elif dist<1.55 and timer<=0:
		windup=.65
		health_label.modulate=Color("ff7149")
	elif dist<(12 if game.survival.is_night() else 9) and dist>1.3 and position.distance_to(home)<18:
		velocity+=path_direction(game.player.position,dt)*move_speed
	elif position.distance_to(home)>.5:
		velocity+=path_direction(home,dt)*1.5
	if dist<9: art.rig.rotation.y=atan2(-dir.x,-dir.z)
	var horizontal_speed=Vector2(velocity.x,velocity.z).length()
	gait+=dt*horizontal_speed*5
	art.left.rotation.x=sin(gait)*.45*minf(1,horizontal_speed)
	art.right.rotation.x=-sin(gait)*.45*minf(1,horizontal_speed)
	move_and_slide()

func hurt(damage: int, kind: int, direction: Vector3) -> void:
	if dead: return
	hp-=damage
	game.impact(position,direction)
	hit_flash=.18
	velocity=direction*5
	move_and_slide()
	game.damage_number(position+Vector3(0,1.8,0),str(damage))
	health_label.text=display_name+"  ·  %d" % maxi(0,hp)
	if kind==0: game.sword_hits+=1
	else: game.bow_hits+=1
	if hp<=0:
		dead=true
		game.kills+=1
		health_label.queue_free()
		collision_layer=0
		var tween=create_tween()
		tween.tween_property(art.rig,"rotation:z",PI/2,.28)
		tween.parallel().tween_property(art.rig,"position:y",-.25,.28)
		game.drop_coin(position)
		game.survival.add_items({"hide":1,"raw_food":1})
		game.toast(display_name+" defeated · hide + raw food")

func path_direction(goal: Vector3, dt: float) -> Vector3:
	if NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map)==0: return Vector3.ZERO
	nav_timer-=dt
	if nav_timer<=0:
		navigator.target_position=goal
		nav_timer=.3
	var next=navigator.get_next_path_position()
	var heading=next-position
	heading.y=0
	return heading.normalized()
