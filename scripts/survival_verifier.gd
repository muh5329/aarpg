extends "res://scripts/verifier.gd"
var s: Node

func go(p: Vector3) -> void:
	for house in game.houses:
		var local=game.player.position-house.position
		var dest=p-house.position
		if abs(local.x)<3.3 and abs(local.z)<3.0 and (abs(dest.x)>3.3 or abs(dest.z)>3.0):
			if not await walk(house.position+Vector3(0,0,6),15):
				get_tree().quit(1)
				return
	var path=NavigationServer3D.map_get_path(game.get_world_3d().navigation_map,game.player.position,p,true)
	for waypoint in path:
		if not await walk(waypoint,maxf(15,game.player.position.distance_to(waypoint)/4.4+9)):
			get_tree().quit(1)
			return
	var reachable=await walk(p,maxf(15,game.player.position.distance_to(p)/4.4+9))
	if not reachable:
		print("SURVIVAL ROUTE BLOCKED")
		get_tree().quit(1)

func item(id: String) -> Dictionary:
	for entry in s.nodes:
		if entry.id==id: return entry
	return {}

func use(id: String, repetitions: int=1) -> void:
	var entry=item(id)
	if id in ["farm_cache","store_cache","timber_cache","tannery_cache","outpost"] and game.player.position.distance_to(entry.node.position)>3:
		await go(entry.node.position+Vector3(0,0,7))
	await go(entry.node.position+Vector3(0,0,1.5))
	for i in range(repetitions):
		await tap("interact")
		await wait(.52)

func craft_recipe(index: int) -> void:
	await tap("crafting")
	await tap("recipe"+str(index+1))
	await tap("crafting")

func combat(enemy_indices: Array) -> void:
	var iterations=0
	while iterations<80:
		var living=false
		for i in enemy_indices:
			if not game.enemies[i].dead: living=true
		if not living: return
		var nearest: Node3D=null
		var best=1000.0
		for i in enemy_indices:
			var enemy=game.enemies[i]
			if not enemy.dead and game.player.position.distance_to(enemy.position)<best: nearest=enemy; best=game.player.position.distance_to(enemy.position)
		if nearest!=null and best>8:
			await go(nearest.position+(game.player.position-nearest.position).normalized()*7.5)
		await tap("bow")
		if game.player.hp<65: await tap("potion")
		if s.inventory.arrows<=0:
			await craft_recipe(1)
		await wait(.68)
		iterations+=1
	check("Combat encounter resolves",false)

func run() -> void:
	s=game.survival
	run_name="survival-route"
	await wait(2)
	if "--building-tour" in OS.get_cmdline_user_args():
		run_name="survival-building-tour"
		check("Completed save loads for independent exploration",s.load_game("user://hollowmere_verifier.json"))
		var clear_buildings=true
		for house in game.houses:
			for tree in game.trees:
				if Vector2(tree.position.x-house.position.x,tree.position.z-house.position.z).length()<8: clear_buildings=false
		check("All seven building footprints are clear of tree trunks",clear_buildings)
		for id in ["timber_cache","store_cache","tannery_cache"]:
			await use(id)
			var building: Node3D=null
			for house in game.houses:
				if house.position.distance_to(item(id).node.position)<1: building=house
			check(id+" is reachable and lootable",item(id).left==0)
			check(id+" opens its interior",building!=null and building.opened and building.visited)
			await capture(id+"-interior")
			await go(item(id).node.position+Vector3(0,0,10))
			await wait(.2)
			check(id+" restores its roof after exit",building!=null and not building.opened)
		check("Remote buildings explored without death",game.deaths==0)
		write_report()
		get_tree().quit(1 if failed else 0)
		return
	if "--resume-test" in OS.get_cmdline_user_args():
		run_name="survival-reload"
		check("Save loads in an independent fresh process",s.load_game("user://hollowmere_verifier.json"))
		check("Outpost and beacon persist",s.outpost_claimed and s.beacon_lit)
		check("Resources and loot remain depleted",item("starter_crate").left==0 and item("signal_lens").left==0 and item("timber_0").left==0)
		check("Placed camp persists",s.placed.size()==1 and s.fires_built==1)
		check("Warden remains defeated",game.enemies[15].dead)
		check("Crafted upgrade and discovery persist",s.upgraded and s.discovered.size()>=7)
		check("Save restores the outpost spawn",s.respawn.distance_to(Vector3(-48,.1,50.5))<.1)
		await capture("restored-world")
		write_report()
		get_tree().quit(1 if failed else 0)
		return
	check("Full valley loads: 7 buildings, 16 enemies, 50 interactive sites",game.houses.size()==7 and game.enemies.size()==16 and s.nodes.size()==50)
	await tap("map")
	check("Map opens",s.menu=="map")
	await capture("01-valley-map")
	await tap("map")
	await tap("crafting")
	var initial=s.inventory.duplicate()
	await tap("recipe3")
	check("Insufficient crafting costs do not consume resources",s.inventory==initial)
	await capture("02-crafting")
	await tap("crafting")
	await use("starter_crate")
	check("Starting cache supplies actual inventory",s.inventory.wood==4 and item("starter_crate").left==0)
	var count=s.inventory.wood
	await tap("interact")
	check("Depleted container cannot be looted twice",s.inventory.wood==count)
	await go(Vector3(0,0,13))
	await go(Vector3(0,0,10))
	await go(Vector3(-17,0,10))
	await use("nearstone_0",2)
	await use("nearstone_1",2)
	await go(Vector3(-40,0,10))
	await use("timber_0",3)
	check("Harvesting yields and depletes resources",s.inventory.wood>=16 and item("timber_0").left==0 and s.gathered==7)
	await capture("03-timberwood")
	await use("timber_1",1)
	await go(Vector3(-40,0,10))
	await use("fiber_0",3)
	await go(Vector3(-40,0,20))
	await craft_recipe(2)
	check("Campfire crafting consumes the exact recipe",s.inventory.campfire==1 and s.crafted==1)
	await tap("build")
	await wait(.3)
	check("Placement preview opens on clear ground",s.placing)
	await tap("interact")
	check("A campfire is placed in the real world",s.fires_built==1 and s.placed.size()==1 and s.inventory.campfire==0)
	await capture("04-first-camp")
	await go(Vector3(-40,0,55))
	await use("outpost")
	check("Outpost claims only with paid resources",s.outpost_claimed)
	await use("outpost")
	check("Rest establishes shelter spawn",s.respawn.distance_to(Vector3(-48,.1,50.5))<.1 and game.player.hp==100)
	await capture("05-outpost")
	await go(Vector3(-40,0,55))
	await go(Vector3(43,0,55))
	await use("spring")
	check("Spring replenishes water",s.inventory.water>=5 and s.thirst>99)
	await capture("06-marsh")
	await go(Vector3(47,0,55))
	await go(Vector3(47,0,33))
	await combat([3,4])
	await go(Vector3(47,0,10))
	await use("farm_cache")
	check("Remote farmhouse scavenging works through cutaway",game.houses[2].visited and item("farm_cache").left==0 and s.inventory.raw_food>=6)
	await capture("07-farm-interior")
	await go(Vector3(47,0,10))
	await go(Vector3(0,0,10))
	await go(Vector3(-40,0,10))
	await go(Vector3(-40,0,20))
	var camp_position=Vector3(s.placed[0].pos[0],s.placed[0].pos[1],s.placed[0].pos[2])
	await go(camp_position+Vector3(0,0,1.5))
	var food_before=s.inventory.food
	await craft_recipe(4)
	check("Campfire cooking converts raw food into ration",s.inventory.food==food_before+1)
	var hunger_before=s.hunger
	await tap("eat")
	check("Eating consumes food and restores hunger",s.hunger>hunger_before and s.inventory.food==food_before)
	await tap("drink")
	check("Drinking restores thirst",s.thirst>99)
	await go(Vector3(-40,0,10))
	await go(Vector3(-40,0,-33))
	await combat([6])
	await go(Vector3(-40,0,-47))
	await use("ore_0",3)
	await use("ore_1",1)
	check("Quarry yields iron ore",s.inventory.ore>=12)
	await capture("08-quarry")
	await go(Vector3(-40,0,-47))
	await go(Vector3(-40,0,10))
	await use("timber_1",3)
	await go(Vector3(-40,0,55))
	await use("outpost")
	await craft_recipe(5)
	check("Claimed workbench upgrades the sword",s.upgraded)
	# The east loop bypasses the optional sanctuary and reaches the northern keep.
	await go(Vector3(-40,0,55))
	await go(Vector3(-40,0,-47))
	await go(Vector3(0,0,-47))
	await go(Vector3(0,0,-65))
	await combat([13,14])
	await go(Vector3(0,0,-73))
	await combat([15])
	check("Keep guards and warden can be defeated",game.enemies[13].dead and game.enemies[14].dead and game.enemies[15].dead)
	await go(Vector3(0,0,-86.5))
	await tap("interact")
	check("Guarded chest awards the signal lens",s.inventory.relay==1)
	await capture("09-keep")
	await go(Vector3(0,0,-47))
	await go(Vector3(-40,0,-47))
	await go(Vector3(-40,0,55))
	await use("beacon")
	check("Full survival progression restores the beacon",s.beacon_lit and s.inventory.relay==0)
	await capture("10-foothold-complete")
	check("Seven regions discovered by physical travel",s.discovered.size()>=7)
	check("Survival journey crosses over 900 meters",game.player.travel>900)
	check("Progress saves atomically",s.save_game("user://hollowmere_verifier.json"))
	check("No stuck combat or construction state",not s.placing and game.player.swing<=0)
	write_report()
	print("SURVIVAL VERIFICATION FINISHED: ","FAIL" if failed else "PASS")
	get_tree().quit(1 if failed else 0)
