extends Node3D
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
var survival: Node
var sun: DirectionalLight3D
var player: CharacterBody3D
var camera: Camera3D
const CAMERA_BASE_OFFSET = Vector3(10.8, 12.6, 14.4)
const CAMERA_LOOK_OFFSET = Vector3(0, .4, -1.5)
const CAMERA_KEY_SPEED = 2.2 # radians per second while Z/X held
const CAMERA_DRAG_SENSITIVITY = .006 # radians per pixel of right-drag
var camera_offset = CAMERA_BASE_OFFSET
var camera_zoom = 1.0
var camera_yaw = 0.0
var camera_yaw_target = 0.0
var camera_focus = Vector3.ZERO
var camera_dragging = false
var houses: Array = []
var trees: Array = []
var arches: Array = []
var nav_region: NavigationRegion3D
var enemies: Array = []
var npcs: Array = []
var arrows: Array = []
var coins: Array = []
var relic: MeshInstance3D
var hud: Control
var quest = 0 # 0 unaccepted, 1 underway, 2 seed retrieved, 3 completed
var kills = 0
var sword_hits = 0
var bow_hits = 0
var deaths = 0
var dialogue_open = false
var dialogue_title = ""
var dialogue_text = ""
var dialogue_action = ""
var speaking = ""
var paused = false
var message = "Search the supply crate nearby [E]. Map [M] · Inventory [TAB] · Craft [C]."
var message_time = 7.0
var flash = 0.0
var shake = 0.0
var time = 0.0
var location = "HOLLOWMERE"
var prompt = ""
var target = ""
var verify_mode = false
var audio: AudioStreamPlayer

func _ready() -> void:
	_setup_input()
	survival=Node.new()
	survival.set_script(preload("res://scripts/survival.gd"))
	survival.game=self
	add_child(survival)
	WorldBuilder.new().build(self)
	player=Player.new()
	player.game=self
	add_child(player)
	player.position=Vector3(0,.1,13)
	camera=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	camera.fov=45
	camera.far=140
	add_child(camera)
	snap_camera()
	camera.current=true
	add_npc(Vector3(-8,0,1),"Mara","Keeper of the hearth",Color("927353"))
	add_npc(Vector3(8,0,1),"Iven","Wayfarer & bowyer",Color("687b60"))
	add_npc(Vector3(2.0,0,9),"Orrin","Lantern watch",Color("75828a"))
	for pos in [Vector3(-2,0,-14),Vector3(2,0,-19),Vector3(-1,0,-23)]:
		var enemy=Enemy.new()
		enemy.game=self
		enemy.position=pos
		add_child(enemy)
		enemies.append(enemy)
	FrontierBuilder.new().build(self)
	build_navigation()
	var layer=CanvasLayer.new()
	add_child(layer)
	hud=Control.new()
	hud.set_script(preload("res://scripts/hud.gd"))
	hud.game=self
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	audio=AudioStreamPlayer.new()
	add_child(audio)
	verify_mode="--verify" in OS.get_cmdline_user_args()
	if verify_mode:
		var verifier=Node.new()
		verifier.set_script(preload("res://scripts/survival_edges.gd") if "--edge-test" in OS.get_cmdline_user_args() else preload("res://scripts/survival_verifier.gd") if "--survival-test" in OS.get_cmdline_user_args() else preload("res://scripts/verifier.gd"))
		verifier.game=self
		add_child(verifier)
	elif not "--new" in OS.get_cmdline_user_args(): survival.load_game()
	get_tree().auto_accept_quit=false

func _setup_input() -> void:
	var keys={"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"interact":[KEY_E,KEY_ENTER],"sword":[KEY_J],"bow":[KEY_K],"swap":[KEY_Q],"cam_left":[KEY_Z],"cam_right":[KEY_X],"dodge":[KEY_SPACE],"potion":[KEY_R],"pause":[KEY_ESCAPE],"journal":[KEY_TAB],"inventory":[KEY_TAB,KEY_I],"crafting":[KEY_C],"map":[KEY_M],"build":[KEY_B],"eat":[KEY_F],"drink":[KEY_G],"sprint":[KEY_SHIFT],"save":[KEY_F5],"recipe1":[KEY_1],"recipe2":[KEY_2],"recipe3":[KEY_3],"recipe4":[KEY_4],"recipe5":[KEY_5],"recipe6":[KEY_6]}
	for action in keys:
		InputMap.add_action(action)
		for key in keys[action]:
			var ev=InputEventKey.new()
			ev.physical_keycode=key
			InputMap.action_add_event(action,ev)
	InputMap.add_action("attack")
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",click)

func _unhandled_input(event: InputEvent) -> void:
	if survival.input(event): return
	if event.is_action_pressed("pause"):
		if dialogue_open: dialogue_open=false
		else: paused=not paused
	if event.is_action_pressed("interact") and not paused: interact()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera_zoom=maxf(.8,camera_zoom-.055)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera_zoom=minf(1.55,camera_zoom+.055)
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
		camera_dragging=event.pressed
	if event is InputEventMouseMotion and camera_dragging and not paused and not dialogue_open:
		camera_yaw_target-=event.relative.x*CAMERA_DRAG_SENSITIVITY

func snap_camera() -> void:
	camera_yaw=camera_yaw_target
	camera_focus=player.position
	update_camera()

func update_camera() -> void:
	camera_offset=CAMERA_BASE_OFFSET.rotated(Vector3.UP,camera_yaw)*camera_zoom
	camera.position=camera_focus+camera_offset
	camera.look_at(camera_focus+CAMERA_LOOK_OFFSET.rotated(Vector3.UP,camera_yaw))

func _process(dt: float) -> void:
	time+=dt
	message_time=maxf(0,message_time-dt)
	flash=maxf(0,flash-dt)
	shake=maxf(0,shake-dt)
	for flame in get_tree().get_nodes_in_group("flames"):
		flame.scale.y=.28*(1+sin(time*13+flame.position.x*4)*.13)
	camera_focus=camera_focus.lerp(player.position,1-exp(-dt*7))
	if not paused and not dialogue_open:
		camera_yaw_target+=Input.get_axis("cam_left","cam_right")*CAMERA_KEY_SPEED*dt
	camera_yaw=lerpf(camera_yaw,camera_yaw_target,1-exp(-dt*10))
	update_camera()
	if shake>0: camera.position+=Vector3(sin(time*115),cos(time*103),sin(time*97))*shake*.14
	for house in houses: house.update_cutaway(player.position)
	for arch in arches:
		arch.visible=Vector2(arch.position.x-player.position.x,arch.position.z-player.position.z).length()>7
	for tree in trees:
		var delta=tree.position-player.position
		delta.y=0
		var occludes=delta.length()<7 and delta.dot(Vector3(camera_offset.x,0,camera_offset.z).normalized())>0
		for child in tree.get_children():
			if child.position.y>2: child.visible=not occludes
	for npc in npcs:
		var near=player.position.distance_to(npc.node.position)<6
		for child in npc.node.get_children():
			if child is Label3D: child.visible=near
	location="THE WILDS"
	var best_distance=24.0
	for poi in survival.pois:
		var distance=Vector2(player.position.x,player.position.z).distance_to(poi.pos)
		if distance<best_distance: location=poi.name.to_upper(); best_distance=distance
	for house in houses:
		var p=player.position-house.position
		if abs(p.x)<3.4 and abs(p.z)<3: location=house.title
	update_prompt()
	if is_instance_valid(relic) and relic.visible:
		relic.rotation.y+=dt
		relic.position.y=1.35+sin(time*2)*.12
	if not paused and not dialogue_open and survival.menu=="":
		update_arrows(dt)
		for coin in coins.duplicate():
			if player.position.distance_to(coin.position)<1.3:
				player.gold+=5
				coin.queue_free()
				coins.erase(coin)
				sound(880,.06)
	hud.queue_redraw()

func add_npc(pos: Vector3, npc_name: String, role: String, color: Color) -> void:
	var npc=Node3D.new()
	add_child(npc)
	npc.position=pos
	Art.humanoid(npc,color,false,true)
	Art.label(npc,Vector3(0,2.3,0),npc_name+"\n"+role,Color("e2d7b3"),20)
	if npc_name=="Mara": Art.label(npc,Vector3(0,2.95,0),"◆",Color("efc279"),32)
	npcs.append({"node":npc,"name":npc_name})

func update_prompt() -> void:
	prompt=""
	if survival.placing:
		prompt="E  Place camp  ·  ESC  Cancel"
		return
	target=""
	for npc in npcs:
		if player.position.distance_to(npc.node.position)<2.15:
			target=npc.name
			prompt="E  ·  Talk to "+target
			return
	var item=survival.nearest()
	if not item.is_empty():
		target="survival"
		prompt=survival.prompt_for(item)
		return
	if player.position.distance_to(Vector3(0,0,-26.7))<2.4 and quest<2:
		target="relic"
		prompt="E  ·  Recover the ember seed" if quest==1 and sanctuary_clear() else "E  ·  Inspect the warded altar"

func interact() -> void:
	if dialogue_open:
		if speaking=="Mara" and quest==0:
			quest=1
			toast("Quest accepted · The Last Lantern")
		elif speaking=="Mara" and quest==2:
			quest=3
			var ember=Art.sphere(self,Vector3(-8,1.45,-.4),.22,Color("e7bc72"))
			ember.material_override=Art.material(Color("ffc77a"),2)
			var hearth_light=OmniLight3D.new()
			add_child(hearth_light)
			hearth_light.position=Vector3(-8,2,0)
			hearth_light.light_color=Color("ffc77a")
			hearth_light.light_energy=2
			hearth_light.omni_range=7
			player.gold+=50
			player.potions+=2
			toast("Quest complete · +50 silver · +2 tonics")
			sound(784,.3)
		dialogue_open=false
		return
	update_prompt()
	if target=="": return
	if target=="survival":
		var item=survival.nearest()
		if not item.is_empty(): survival.interact(item)
		return
	if target=="relic":
		if quest==1 and sanctuary_clear():
			quest=2
			relic.visible=false
			toast("Ember seed recovered. Return to Mara's hearth.")
			sound(990,.25)
		else:
			toast("Three ashbound sustain the ward. Speak with Mara, then clear the sanctuary.")
		return
	speaking=target
	dialogue_title=target.to_upper()
	dialogue_open=true
	dialogue_action="E / ENTER   Continue"
	if target=="Mara":
		if quest==0:
			dialogue_text="Our last lantern is fading. Follow the north road to the old sanctuary.\nDefeat its three ashbound guardians and bring me the ember seed.\nYour sword will keep them close; your bow can strike from a distance."
			dialogue_action="E / ENTER   Accept the quest     ·     ESC   Leave"
		elif quest==1:
			dialogue_text="The sanctuary lies beyond the northern gate. Clear the three guardians,\nthen take the ember seed from the altar. I will keep the hearth warm."
		elif quest==2:
			dialogue_text="You brought it home. Look — the lantern burns bright again.\nHollowmere will remember this kindness, wayfarer.\nTake 50 silver and two healing tonics for the road ahead."
			dialogue_action="E / ENTER   Complete quest"
		else:
			dialogue_text="There is light in our windows again. You will always have a home here.\nRest a while, or visit Iven across the square."
	elif target=="Iven":
		dialogue_text="A steady hand is better than a hurried shot. K fires at a nearby foe;\nor equip the bow with Q and aim with the mouse. Craft more arrows with C: two wood and one stone.\nThe old road runs north. Space lets you dodge an ashbound's strike."
	else:
		dialogue_text="Welcome to Hollowmere. Mara is in the western house.\nWalk through the open doorway — there is no loading screen.\nIven keeps the eastern hearth, if you need advice on your bow."

func nearest_enemy(pos: Vector3, distance: float) -> Node3D:
	var nearest: Node3D=null
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead: continue
		var d=pos.distance_to(enemy.position)
		if d<distance:
			distance=d
			nearest=enemy
	return nearest

func shoot(pos: Vector3, direction: Vector3) -> void:
	var node=Node3D.new()
	add_child(node)
	node.position=pos
	node.rotation.y=atan2(-direction.x,-direction.z)
	Art.box(node,Vector3.ZERO,Vector3(.045,.045,.9),Color("e2d4a0"))
	Art.box(node,Vector3(0,0,-.48),Vector3(.12,.08,.2),Color("c4e0d7"))
	arrows.append({"node":node,"dir":direction,"life":1.7})

func update_arrows(dt: float) -> void:
	for arrow in arrows.duplicate():
		var start: Vector3=arrow.node.position
		var end: Vector3=start+arrow.dir*22*dt
		var query=PhysicsRayQueryParameters3D.create(start,end,1|4)
		query.exclude=[player.get_rid()]
		query.hit_from_inside=true
		var result=get_world_3d().direct_space_state.intersect_ray(query)
		var hit=not result.is_empty()
		if hit and result.collider.has_method("hurt"): result.collider.hurt(22,1,arrow.dir)
		arrow.node.position=end
		arrow.life-=dt
		if hit or arrow.life<=0:
			arrow.node.queue_free()
			arrows.erase(arrow)

func slash(pos: Vector3, direction: Vector3) -> void:
	var root=Node3D.new()
	add_child(root)
	root.position=pos
	root.rotation.y=atan2(-direction.x,-direction.z)
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(16):
		var a=-1.1+i*.14
		var b=a+.14
		for v in [Vector2(a,1.15),Vector2(a,1.9),Vector2(b,1.9),Vector2(a,1.15),Vector2(b,1.9),Vector2(b,1.15)]:
			st.add_vertex(Vector3(sin(v.x)*v.y,0,-cos(v.x)*v.y))
	st.generate_normals()
	var arc=Art.shape(root,Vector3.ZERO,st.commit(),Color("cbbd98"))
	arc.material_override=Art.material(Color("d0b986"),1.5)
	arc.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	arc.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override.albedo_color.a=.55
	var t=create_tween()
	t.tween_property(arc.material_override,"albedo_color:a",0.0,.16)
	t.parallel().tween_property(root,"scale",Vector3.ONE*1.15,.16)
	t.tween_callback(root.queue_free)

func impact(pos: Vector3, direction: Vector3) -> void:
	shake=.22
	sound(95,.12)
	var particles=GPUParticles3D.new()
	add_child(particles)
	particles.position=pos+Vector3(0,1,0)
	particles.amount=17
	particles.one_shot=true
	particles.explosiveness=1
	particles.lifetime=.45
	var pm=ParticleProcessMaterial.new()
	pm.direction=direction+Vector3(0,.4,0)
	pm.spread=50
	pm.initial_velocity_min=2
	pm.initial_velocity_max=4
	pm.gravity=Vector3(0,-8,0)
	pm.scale_min=.025
	pm.scale_max=.07
	particles.process_material=pm
	var mesh=SphereMesh.new()
	mesh.radius=1
	mesh.height=2
	mesh.material=Art.material(Color("872b20"))
	particles.draw_pass_1=mesh
	particles.emitting=true
	get_tree().create_timer(.7).timeout.connect(particles.queue_free)

func damage_number(pos: Vector3, value: String) -> void:
	var label=Art.label(self,pos,value,Color("ffe1a3"),34)
	var t=create_tween()
	t.tween_property(label,"position:y",pos.y+1,.65)
	t.parallel().tween_property(label,"modulate:a",0.0,.65)
	t.tween_callback(label.queue_free)

func drop_coin(pos: Vector3) -> void:
	var coin=Art.sphere(self,Vector3(pos.x,.35,pos.z),.17,Color("f3cc76"))
	coin.material_override=Art.material(Color("e8bf62"),.7)
	coins.append(coin)

func toast(text: String) -> void:
	message=text
	message_time=5

func sound(frequency: float, duration: float) -> void:
	var wave=AudioStreamWAV.new()
	wave.format=AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate=22050
	var data=PackedByteArray()
	data.resize(int(22050*duration)*2)
	for i in range(data.size()/2):
		var v=int(sin(i*TAU*frequency/22050)*6000*(1.0-float(i)/(data.size()/2)))
		data.encode_s16(i*2,v)
	wave.data=data
	audio.stream=wave
	audio.volume_db=-12
	audio.play()

func sanctuary_clear() -> bool:
	return enemies.size()>=3 and enemies[0].dead and enemies[1].dead and enemies[2].dead

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(survival) and not verify_mode: survival.save_game()
		get_tree().quit()

func build_navigation() -> void:
	var mesh=NavigationMesh.new()
	mesh.geometry_parsed_geometry_type=NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.geometry_collision_mask=1
	mesh.cell_size=.3
	mesh.cell_height=.1
	mesh.agent_radius=.3
	mesh.agent_height=1.6
	mesh.agent_max_climb=.3
	mesh.filter_walkable_low_height_spans=true
	var source=NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(mesh,source,self)
	NavigationServer3D.bake_from_source_geometry_data(mesh,source)
	nav_region=NavigationRegion3D.new()
	add_child(nav_region)
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map,.3)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map,.1)
	nav_region.navigation_mesh=mesh

func clear_line(a: Vector3, b: Vector3) -> bool:
	var q=PhysicsRayQueryParameters3D.create(a+Vector3(0,1,0),b+Vector3(0,1,0),1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()
