extends "res://scripts/verifier.gd"
# Isolated edge-case fixtures deliberately set boundary values and positions.
# They supplement, and do not replace, the physical end-to-end route.
func run() -> void:
	run_name="survival-edges"
	var s=game.survival
	await wait(2)
	s.inventory.arrows=0
	await tap("bow")
	check("Empty quiver prevents projectile creation",game.arrows.is_empty() and game.player.cooldown==0)
	s.stamina=0
	await tap("sword")
	check("Exhaustion prevents attacks",game.player.cooldown==0)
	Input.action_press("up")
	await tap("dodge")
	release_motion()
	check("Exhaustion prevents dodge",game.player.dodge==0)
	await tap("inventory")
	s.inventory.bandage=2
	game.player.hp=20
	await tap("potion")
	check("One heal key uses one bandage inside inventory",s.inventory.bandage==1 and game.player.hp==75)
	s.hunger=40; s.thirst=35; s.inventory.food=1; s.inventory.water=1
	await tap("eat")
	await tap("drink")
	check("Food and water can be used from the pack",s.hunger==78 and s.thirst==80 and s.inventory.food==0 and s.inventory.water==0)
	await tap("inventory")
	s.inventory.raw_food=1; s.inventory.wood=1
	await tap("crafting")
	await tap("recipe5")
	check("Cooking requires a nearby fire",s.inventory.raw_food==1 and s.inventory.wood==1)
	s.inventory.fiber=3
	await tap("recipe1")
	check("Bandage recipe consumes exactly three fiber",s.inventory.fiber==0 and s.inventory.bandage==2)
	game.player.position=Vector3(-8,.1,1)
	s.inventory.campfire=1
	await tap("build")
	await wait(.2)
	check("Build key exits crafting and opens preview",s.menu=="" and s.placing)
	check("Interior placement is rejected",not s.build_valid)
	await tap("interact")
	check("Invalid placement preserves the kit",s.inventory.campfire==1 and s.placed.is_empty())
	await tap("pause")
	check("Escape cancels construction",not s.placing)
	check("Solid wall blocks melee sight line",not game.clear_line(Vector3(-8,0,1),Vector3(-3,0,1)))
	check("Open doorway permits sight line",game.clear_line(Vector3(-8,0,1),Vector3(-8,0,6)))
	var path=NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,Vector3(-12,0,1),Vector3(-8,0,1),true)
	var via_door=false
	for p in path:
		if p.z>4: via_door=true
	check("Navigation routes around walls to the doorway",path.size()>2 and via_door)
	game.player.position=Vector3(-8,.1,1)
	game.player.hp=100
	var enemy=game.enemies[0]
	enemy.position=Vector3(-12,.1,1)
	enemy.home=enemy.position
	await wait(10)
	check("A live enemy physically pursues through the doorway",abs(enemy.position.x+8)<3.2 and abs(enemy.position.z-2)<3)
	await capture("enemy-indoor-pursuit")
	# Clear space and a safe distance from that fixture enemy for building/rest.
	game.player.position=Vector3(0,.1,23)
	game.player.facing=Vector3.FORWARD
	s.inventory.campfire=0; s.inventory.fiber=6; s.inventory.hide=2
	await tap("crafting")
	await tap("recipe4")
	check("Bedroll recipe uses fiber and hide",s.inventory.bedroll==1 and s.inventory.fiber==0 and s.inventory.hide==0)
	await tap("build")
	await wait(.3)
	await tap("interact")
	check("Bedroll placement consumes its item",s.placed.size()==1 and s.inventory.bedroll==0 and s.nodes.back().kind=="bedroll")
	game.player.position=s.nodes.back().node.position+Vector3(0,.1,1)
	await wait(.5)
	await tap("interact")
	check("Bedroll establishes a new respawn point",s.respawn.distance_to(s.nodes.back().node.position+Vector3(0,.1,1.5))<.1)
	s.clock_minutes=1320
	await wait(.3)
	check("Night changes world lighting and detection mode",s.is_night() and game.sun.light_energy<.5)
	await capture("night-camp")
	var bad=FileAccess.open("user://hollowmere_invalid_verifier.json",FileAccess.WRITE)
	bad.store_string('{"version":1}')
	bad.close()
	check("Incomplete save is rejected without crashing",not s.load_game("user://hollowmere_invalid_verifier.json"))
	write_report()
	print("EDGE VERIFICATION FINISHED: ","FAIL" if failed else "PASS")
	get_tree().quit(1 if failed else 0)
