extends Node
var game: Node3D
var results: Array = []
var run_name = "verification"
var failed = false
var output_dir="res://evidence"

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): output_dir=arg.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	if "--review" in OS.get_cmdline_user_args(): run_name="independent-review"
	call_deferred("run")

func check(label: String, condition: bool) -> void:
	results.append({"check":label,"passed":condition})
	print("VERIFY ","PASS " if condition else "FAIL ",label)
	if not condition: failed=true
	write_report()

func write_report() -> void:
	var file=FileAccess.open(output_dir+"/"+run_name+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":results,"passed":not failed,"sword_hits":game.sword_hits,"bow_hits":game.bow_hits,"kills":game.kills,"quest":game.quest,"travel":game.player.travel,"deaths":game.deaths},"  "))

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output_dir+"/"+run_name+"-"+label+".png")

func tap(action: String) -> void:
	var press=InputEventAction.new()
	press.action=action
	press.pressed=true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var release=InputEventAction.new()
	release.action=action
	release.pressed=false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await get_tree().physics_frame

func release_motion() -> void:
	for action in ["left","right","up","down"]: Input.action_release(action)

func walk(point: Vector3, timeout: float = 15) -> bool:
	var elapsed=0.0
	while elapsed<timeout:
		var delta=point-game.player.position
		delta.y=0
		if delta.length()<.23:
			release_motion()
			await wait(.12)
			return true
		release_motion()
		var world_direction=delta.normalized()
		var right=game.camera.global_basis.x
		right.y=0
		right=right.normalized()
		var back=Vector3(-right.z,0,right.x)
		var direction=Vector3(world_direction.dot(right),0,world_direction.dot(back))
		if abs(direction.x)>.06: Input.action_press("right" if direction.x>0 else "left",abs(direction.x))
		if abs(direction.z)>.06: Input.action_press("down" if direction.z>0 else "up",abs(direction.z))
		await get_tree().physics_frame
		elapsed+=get_physics_process_delta_time()
	release_motion()
	check("Route accessible: "+str(point),false)
	await capture("blocked-route")
	return false

func run() -> void:
	if "--preview" in OS.get_cmdline_user_args():
		run_name="visual-review"
		await wait(2)
		await capture("village")
		await walk(Vector3(-8,0,10))
		await walk(Vector3(-8,0,2.5))
		check("Final western cutaway is accessible",game.houses[0].opened and game.houses[0].visited)
		await capture("interior")
		await walk(Vector3(-8,0,10))
		check("Final roof and gables restore",not game.houses[0].opened)
		await walk(Vector3(8,0,10))
		await walk(Vector3(8,0,2.5))
		check("Final eastern cutaway is accessible",game.houses[1].opened and game.houses[1].visited)
		await capture("eastern-interior")
		await walk(Vector3(8,0,10))
		check("Final eastern roof restores",not game.houses[1].opened)
		get_tree().quit(1 if failed else 0)
		return
	if "--bow-probe" in OS.get_cmdline_user_args():
		await wait(1)
		game.player.position=Vector3(0,.2,-14)
		for i in range(12):
			await tap("bow")
			await wait(.65)
			print("PROBE arrows ",game.arrows.size()," hits ",game.bow_hits)
		await capture("bow-probe")
		get_tree().quit()
		return
	await wait(1.5)
	check("Fresh launch starts with full health and no quest",game.player.hp==100 and game.quest==0)
	await capture("01-village")
	if run_name=="independent-review": await review_controls()
	await walk(Vector3(-8,0,10))
	await walk(Vector3(-8,0,2.5))
	check("Western house entered through physical doorway",game.houses[0].visited)
	check("Roof and front walls disappear indoors",game.houses[0].opened and not game.houses[0].cut_parts[0].visible)
	await capture("02-interior")
	await tap("interact")
	check("NPC dialogue opens through E action",game.dialogue_open and game.speaking=="Mara")
	await capture("03-quest-offer")
	await tap("interact")
	check("Quest accepted through dialogue",game.quest==1 and not game.dialogue_open)
	await walk(Vector3(-8,0,10))
	check("Western roof restores after leaving",not game.houses[0].opened and game.houses[0].cut_parts[0].visible)
	await walk(Vector3(8,0,10))
	await walk(Vector3(8,0,2.5))
	check("Second house is accessible and cuts away",game.houses[1].visited and game.houses[1].opened)
	await tap("interact")
	check("Second NPC has working dialogue",game.dialogue_open and game.speaking=="Iven")
	await tap("interact")
	await capture("04-second-house")
	await walk(Vector3(8,0,10))
	check("Second roof restores on exit",not game.houses[1].opened)
	await walk(Vector3(0,0,10))
	await walk(Vector3(0,0,-8))
	check("Town gate connects seamlessly to overworld",game.player.position.z<-7)
	# Freeze via the actual pause input and verify movement is suppressed.
	await tap("pause")
	var before=game.player.position
	Input.action_press("up")
	await wait(.3)
	Input.action_release("up")
	check("Pause blocks movement",game.player.position.distance_to(before)<.1)
	await tap("pause")
	await walk(Vector3(0,0,-11))
	# Fight first guardian with physical sword attacks, no direct health edits.
	var first=game.enemies[0]
	var guard=0
	while not first.dead and guard<30:
		if first.position.distance_to(game.player.position)>2.1:
			await walk(first.position+Vector3(0,0,1.4),3)
		await tap("sword")
		await wait(.48)
		guard+=1
	check("Sword defeats a live enemy",first.dead and game.sword_hits>0)
	await capture("05-sword-combat")
	await walk(Vector3(0,0,-15))
	guard=0
	while game.kills<3 and guard<55:
		await tap("bow")
		await wait(.64)
		if game.player.hp<60: await tap("potion")
		guard+=1
	check("Bow projectiles damage and defeat enemies",game.bow_hits>=3 and game.kills==3)
	await capture("06-sanctuary")
	for coin in game.coins.duplicate():
		await walk(coin.position)
	check("Enemy loot can be collected",game.player.gold>0)
	await walk(Vector3(0,0,-25.5))
	await tap("interact")
	check("Quest object is collected after clearing guardians",game.quest==2 and not game.relic.visible)
	await capture("07-ember-seed")
	await walk(Vector3(0,0,10))
	await walk(Vector3(-8,0,10))
	await walk(Vector3(-8,0,2.5))
	await tap("interact")
	await tap("interact")
	check("Quest completes and grants reward",game.quest==3 and game.player.gold>=50)
	await capture("08-completed")
	await walk(Vector3(-8,0,10))
	check("Repeated entry and exit restores all cutaway parts",game.houses[0].transitions>=4 and not game.houses[0].opened)
	check("No stuck attack state",game.player.cooldown<=0 and game.player.swing<=0)
	check("Entire quest completed without death",game.deaths==0)
	check("Physical route traversed over 120 meters",game.player.travel>120)
	await capture("09-final-village")
	write_report()
	print("VERIFICATION FINISHED: ","FAIL" if failed else "PASS")
	get_tree().quit(1 if failed else 0)

func review_controls() -> void:
	var initial=game.player.position
	Input.action_press("right")
	await wait(.4)
	release_motion()
	var movement=game.player.position-initial
	check("D moves screen-right with diagonal camera",movement.dot(game.camera.global_basis.x)>1.6)
	await walk(Vector3(0,0,13))
	Input.action_press("up")
	await tap("dodge")
	check("Space initiates dodge and invulnerability",game.player.dodge>0 and game.player.invulnerable>0)
	await wait(.35)
	release_motion()
	await walk(Vector3(0,0,13))
	await tap("swap")
	check("Q equips bow",game.player.weapon==1)
	# A real mouse event uses camera ray projection and creates a physical arrow.
	var cursor=InputEventMouseMotion.new()
	cursor.position=get_viewport().get_visible_rect().size/2+Vector2(180,-70)
	Input.parse_input_event(cursor)
	await get_tree().process_frame
	var click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.position=cursor.position
	click.pressed=true
	Input.parse_input_event(click)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check("Mouse aim fires equipped bow",game.arrows.size()>0 and game.player.cooldown>0)
	click=InputEventMouseButton.new()
	click.button_index=MOUSE_BUTTON_LEFT
	click.pressed=false
	Input.parse_input_event(click)
	await wait(.7)
	await tap("swap")
	check("Q returns to sword",game.player.weapon==0)
	# Enter Iven's home first, without a quest, then leave and follow the normal route.
	await walk(Vector3(8,0,10))
	await walk(Vector3(8,0,2.5))
	await tap("interact")
	var before=game.player.position
	Input.action_press("up")
	await tap("sword")
	await wait(.25)
	release_motion()
	check("Dialogue blocks movement and combat input",game.player.position.distance_to(before)<.1 and game.player.cooldown<=0)
	await tap("pause")
	check("Escape closes dialogue without accepting a quest",not game.dialogue_open and game.quest==0)
	# A solid side wall still collides while its renderer is cut away.
	await walk(Vector3(10.8,0,2.5))
	Input.action_press("right",.8)
	Input.action_press("up",.6)
	await wait(.7)
	release_motion()
	check("Hidden near wall retains physical collision",game.player.position.x<11.1)
	await walk(Vector3(8,0,2.5))
	await walk(Vector3(8,0,10))
	await walk(Vector3(0,0,13))
