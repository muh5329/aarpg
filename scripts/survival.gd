extends Node
var game: Node3D
var inventory={"wood":0,"stone":0,"fiber":0,"ore":0,"hide":0,"raw_food":0,"food":2,"water":3,"arrows":32,"bandage":1,"campfire":0,"bedroll":0,"relay":0}
var hunger=100.0
var thirst=100.0
var stamina=100.0
var clock_minutes=8.0*60
var day=1
var menu=""
var selected=0
var nodes: Array=[]
var placed: Array=[]
var discovered: Array=[]
var gathered=0
var crafted=0
var fires_built=0
var outpost_claimed=false
var beacon_lit=false
var upgraded=false
var respawn=Vector3(0,.1,12)
var placing=false
var ghost: Node3D
var build_position=Vector3.ZERO
var build_valid=false
var busy=0.0
var auto_timer=0.0
var starvation_timer=0.0
var save_path="user://hollowmere_survival_v1.json"
var pois=[
	{"name":"Hollowmere","pos":Vector2(0,10),"detail":"Settlement · well · supplies"},
	{"name":"Timberwood","pos":Vector2(-47,8),"detail":"Wood · fiber · berries"},
	{"name":"Briar Farm","pos":Vector2(47,10),"detail":"Food · scavenging · two homes"},
	{"name":"Iron Quarry","pos":Vector2(-46,-47),"detail":"Stone · iron · prowlers"},
	{"name":"Drowned Marsh","pos":Vector2(45,58),"detail":"Water · reeds · abandoned camp"},
	{"name":"Ranger Outpost","pos":Vector2(-40,55),"detail":"Claimable shelter · workbench · beacon"},
	{"name":"Blackthorn Keep","pos":Vector2(3,-77),"detail":"Warden · signal lens · high danger"},
	{"name":"Ashen Sanctuary","pos":Vector2(0,-24),"detail":"Mara's optional ember quest"}]
var recipes=[
	{"name":"Bandage","cost":{"fiber":3},"item":"bandage","amount":1,"need":""},
	{"name":"8 arrows","cost":{"wood":2,"stone":1},"item":"arrows","amount":8,"need":""},
	{"name":"Campfire kit","cost":{"wood":6,"stone":4},"item":"campfire","amount":1,"need":""},
	{"name":"Bedroll","cost":{"fiber":6,"hide":2},"item":"bedroll","amount":1,"need":""},
	{"name":"Cooked ration","cost":{"raw_food":1,"wood":1},"item":"food","amount":1,"need":"fire"},
	{"name":"Tempered sword","cost":{"ore":6,"wood":4},"item":"upgrade","amount":1,"need":"bench"}]

func _process(dt: float) -> void:
	if not is_instance_valid(game.player): return
	if not game.paused and not game.dialogue_open and menu=="":
		busy=maxf(0,busy-dt)
		clock_minutes+=dt*1.3
		if clock_minutes>=1440: clock_minutes-=1440; day+=1
		hunger=maxf(0,hunger-dt*.033)
		thirst=maxf(0,thirst-dt*.055)
		var running=Input.is_action_pressed("sprint") and game.player.velocity.length()>1
		if running: stamina=maxf(0,stamina-dt*9)
		elif game.player.cooldown<=0 and game.player.dodge<=0: stamina=minf(100,stamina+dt*(17 if hunger>15 and thirst>15 else 8))
		if hunger<=0 or thirst<=0:
			starvation_timer+=dt
			if starvation_timer>=1: game.player.hurt(1); starvation_timer=0
		else: starvation_timer=0
		auto_timer+=dt
		if auto_timer>=60 and not game.verify_mode: save_game(); auto_timer=0
	for poi in pois:
		if Vector2(game.player.position.x,game.player.position.z).distance_to(poi.pos)<17 and not poi.name in discovered:
			discovered.append(poi.name)
			game.toast("Discovered · "+poi.name)
	if placing: update_placement()
	var daylight=clampf(sin((clock_minutes/1440-.25)*TAU)*.6+.45,.10,1)
	if is_instance_valid(game.sun):
		game.sun.light_energy=.2+daylight*.9
		game.sun.light_color=Color("a5b7d3").lerp(Color("d1c7ad"),daylight)

func is_night() -> bool:
	return clock_minutes<360 or clock_minutes>1140

func clock_text() -> String:
	return "DAY %d  ·  %02d:%02d  ·  %s" % [day,int(clock_minutes)/60,int(clock_minutes)%60,"NIGHT" if is_night() else "DAYLIGHT"]

func can_pay(cost: Dictionary) -> bool:
	for item in cost:
		if inventory.get(item,0)<cost[item]: return false
	return true

func spend(cost: Dictionary) -> void:
	for item in cost: inventory[item]-=cost[item]

func add_items(items: Dictionary) -> void:
	for item in items: inventory[item]=inventory.get(item,0)+int(items[item])

func cost_text(cost: Dictionary) -> String:
	var parts=PackedStringArray()
	for item in cost: parts.append(str(cost[item])+" "+item.replace("_"," "))
	return ", ".join(parts)

func nearby_kind(kind: String, distance: float=4) -> bool:
	for item in nodes:
		if item.kind==kind and game.player.position.distance_to(item.node.position)<distance: return true
	return false

func craft(index: int) -> bool:
	if index<0 or index>=recipes.size(): return false
	var r=recipes[index]
	if r.need=="fire" and not nearby_kind("fire"): game.toast("Cook beside a campfire."); return false
	if r.need=="bench" and (not outpost_claimed or not nearby_kind("outpost",5)): game.toast("Use the workbench in your claimed outpost."); return false
	if r.item=="upgrade" and upgraded: game.toast("Your sword is already tempered."); return false
	if not can_pay(r.cost): game.toast("Need "+cost_text(r.cost)); return false
	spend(r.cost)
	if r.item=="upgrade": upgraded=true
	else: inventory[r.item]+=r.amount
	crafted+=1
	game.toast("Crafted · "+r.name)
	game.sound(480,.12)
	return true

func input(event: InputEvent) -> bool:
	if event.is_action_pressed("pause"):
		if placing: end_placement(); return true
		if menu!="": menu=""; return true
	if game.paused or game.dialogue_open: return false
	if event.is_action_pressed("inventory"): menu="" if menu=="inventory" else "inventory"; return true
	if event.is_action_pressed("crafting"): menu="" if menu=="craft" else "craft"; return true
	if event.is_action_pressed("map"): menu="" if menu=="map" else "map"; return true
	if event.is_action_pressed("build"): menu=""; start_placement(); return true
	if event.is_action_pressed("potion"): game.player.heal(); return true
	if placing and event.is_action_pressed("interact"): place_fire(); return true
	if event.is_action_pressed("eat"):
		if inventory.food>0 and hunger<100: inventory.food-=1; hunger=minf(100,hunger+38); game.toast("Ate a ration · +38 food")
		elif inventory.food==0: game.toast("No rations. Scavenge homes or cook raw food.")
		return true
	if event.is_action_pressed("drink"):
		if inventory.water>0 and thirst<100: inventory.water-=1; thirst=minf(100,thirst+45); game.toast("Drank water · +45 hydration")
		elif inventory.water==0: game.toast("No water. Refill at a marked well or spring.")
		return true
	if menu!="":
		if menu=="craft":
			for i in range(6):
				if event.is_action_pressed("recipe"+str(i+1)): craft(i)
		return true
	if event.is_action_pressed("save") and not game.verify_mode: save_game(); game.toast("World saved"); return true
	return false

func nearest() -> Dictionary:
	var result={}
	var distance=2.3
	for item in nodes:
		if item.left<=0 and item.kind not in ["well","outpost","beacon","fire","bedroll"]: continue
		var d=game.player.position.distance_to(item.node.position)
		if d<distance:
			distance=d
			result=item
	return result

func prompt_for(item: Dictionary) -> String:
	match item.kind:
		"wood","stone","fiber","ore": return "E  ·  Gather "+item.kind+"  [%d left]" % item.left
		"cache": return "E  ·  Search "+item.label
		"well": return "E  ·  Refill water"
		"fire": return "E  ·  Cook here  /  C recipes"
		"outpost": return "E  ·  Rest at shelter" if outpost_claimed else "E  ·  Claim shelter  [12 wood, 8 stone]"
		"beacon": return "E  ·  Beacon restored" if beacon_lit else "E  ·  Restore beacon  [signal lens + 4 ore]"
		"bedroll": return "E  ·  Set respawn / rest"
	return "E  ·  Interact"

func interact(item: Dictionary) -> void:
	if busy>0: return
	busy=.42
	match item.kind:
		"wood","stone","fiber","ore":
			if stamina<8: game.toast("Catch your breath first."); return
			stamina-=8
			item.left-=1
			add_items(item.items)
			gathered+=1
			game.player.swing=.32
			game.player.facing=(item.node.position-game.player.position).normalized()
			game.sound(150,.1)
			game.toast("Gathered · "+cost_text(item.items))
			if item.left<=0: item.node.scale.y=.18
		"cache":
			if item.get("guarded",false):
				for enemy in game.enemies:
					if not enemy.dead and enemy.home.distance_to(item.node.position)<12: game.toast("Clear the keep's guards before taking the lens."); return
			item.left=0
			add_items(item.items)
			item.node.scale.y=.4
			game.toast("Scavenged · "+cost_text(item.items))
		"well":
			inventory.water=maxi(inventory.water,5)
			thirst=100
			game.toast("Clean water · filled five flasks")
		"fire": menu="craft"
		"outpost":
			if not outpost_claimed:
				if not can_pay({"wood":12,"stone":8}): game.toast("Claim shelter: 12 wood + 8 stone."); return
				spend({"wood":12,"stone":8})
				outpost_claimed=true
				game.toast("Outpost claimed · workbench and shelter unlocked")
				if not game.verify_mode: save_game()
			else: rest(item.node.position)
		"bedroll": rest(item.node.position)
		"beacon":
			if beacon_lit: return
			if not outpost_claimed: game.toast("Claim the ranger outpost first."); return
			if not can_pay({"relay":1,"ore":4}): game.toast("Recover the signal lens from Blackthorn Keep, and bring 4 ore."); return
			spend({"relay":1,"ore":4})
			beacon_lit=true
			Art.lantern(game,item.node.position+Vector3(0,1.0,0))
			game.toast("FOOTHOLD ESTABLISHED · the valley is yours to explore")
			if not game.verify_mode: save_game()

func rest(pos: Vector3) -> void:
	if game.nearest_enemy(pos,12)!=null: game.toast("Enemies are too close to rest."); return
	respawn=pos+Vector3(0,.1,1.5)
	game.player.hp=100
	stamina=100
	if clock_minutes>=480: day+=1
	clock_minutes=8*60
	hunger=maxf(15,hunger-8)
	thirst=maxf(15,thirst-10)
	game.toast("Rested until morning · respawn set here")
	if not game.verify_mode: save_game()

func start_placement() -> void:
	if placing: end_placement(); return
	if inventory.campfire<=0 and inventory.bedroll<=0: game.toast("Craft a campfire kit or bedroll first [C]."); return
	placing=true
	ghost=Node3D.new()
	game.add_child(ghost)
	var ring=Art.cylinder(ghost,Vector3(0,.05,0),.75,.08,Color("72bb84"))
	ring.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override.albedo_color.a=.55

func update_placement() -> void:
	build_position=game.player.position+game.player.facing*2.3
	build_position.y=.03
	ghost.position=build_position
	build_valid=abs(build_position.x)<83 and build_position.z>-94 and build_position.z<83
	for house in game.houses:
		var p=build_position-house.position
		if abs(p.x)<4.4 and abs(p.z)<4.2: build_valid=false
	for item in nodes:
		if item.node.position.distance_to(build_position)<1.8: build_valid=false
	var shape=SphereShape3D.new()
	shape.radius=.7
	var q=PhysicsShapeQueryParameters3D.new()
	q.shape=shape
	q.transform=Transform3D(Basis(),build_position+Vector3(0,.85,0))
	q.collision_mask=1
	if not game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(): build_valid=false
	ghost.get_child(0).material_override.albedo_color=Color(.35,.8,.45,.55) if build_valid else Color(.9,.2,.15,.55)

func place_fire() -> bool:
	if not build_valid: game.toast("Blocked placement. Find clear ground outside."); return false
	var kind="fire" if inventory.campfire>0 else "bedroll"
	inventory["campfire" if kind=="fire" else "bedroll"]-=1
	add_structure(kind,build_position)
	end_placement()
	game.toast("Placed "+kind+" · E to use")
	return true

func end_placement() -> void:
	placing=false
	if is_instance_valid(ghost): ghost.queue_free()

func add_structure(kind: String, pos: Vector3, remember: bool=true) -> void:
	var root=Node3D.new()
	game.add_child(root)
	root.position=pos
	if kind=="fire":
		for i in range(9):
			var a=i*TAU/9
			Art.sphere(root,Vector3(cos(a)*.55,.12,sin(a)*.55),.17,Color("68665e"))
		for i in range(3):
			var log=Art.box(root,Vector3(0,.16,0),Vector3(.9,.18,.2),Color("66503b"))
			log.rotation.y=i*PI/3
			log.material_override=Art.pbr("bark",.6)
		var flame=Art.ellipsoid(root,Vector3(0,.43,0),Vector3(.15,.34,.15),Color("ffd27b"))
		flame.material_override=Art.material(Color("ffad4e"),4)
		var light=OmniLight3D.new()
		root.add_child(light)
		light.position.y=1
		light.light_color=Color("ffc77e")
		light.light_energy=2
		light.omni_range=7
		fires_built+=1
	else:
		Art.box(root,Vector3(0,.12,0),Vector3(.85,.22,1.8),Color("555c49"))
		Art.cylinder(root,Vector3(0,.28,-.7),.18,.8,Color("777362")).rotation.z=PI/2
	nodes.append({"id":"placed_"+str(nodes.size()),"kind":kind,"node":root,"left":1,"items":{},"label":kind})
	if remember: placed.append({"kind":kind,"pos":[pos.x,pos.y,pos.z]})

func objective_lines() -> Array:
	if beacon_lit: return ["FOOTHOLD ESTABLISHED","Explore, build and survive."]
	if gathered<3: return ["Scavenge and gather","E at crates, logs and rocks.","Gather resources: %d / 3" % gathered]
	if fires_built<1: return ["Make your first camp","C: craft a campfire kit","B: preview · E: place"]
	if not outpost_claimed: return ["Claim the ranger outpost","Southwest · see map [M]","Bring 12 wood and 8 stone"]
	if inventory.relay<1: return ["Recover the signal lens","Blackthorn Keep · far north","Defeat the warden and guards"]
	return ["Restore the outpost beacon","Bring the lens and 4 ore","Return to the ranger outpost"]

func save_game(path: String="") -> bool:
	if path=="": path=save_path
	var states={}
	for item in nodes: states[item.id]=item.left
	var defeated=[]
	for i in range(game.enemies.size()):
		if game.enemies[i].dead: defeated.append(i)
	var data={"version":1,"inventory":inventory,"hunger":hunger,"thirst":thirst,"stamina":stamina,"clock":clock_minutes,"day":day,"pos":[game.player.position.x,game.player.position.y,game.player.position.z],"hp":game.player.hp,"gold":game.player.gold,"potions":game.player.potions,"quest":game.quest,"kills":game.kills,"defeated":defeated,"nodes":states,"placed":placed,"discovered":discovered,"gathered":gathered,"crafted":crafted,"outpost":outpost_claimed,"beacon":beacon_lit,"upgraded":upgraded,"respawn":[respawn.x,respawn.y,respawn.z]}
	var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data))
	f.close()
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func load_game(path: String="") -> bool:
	if path=="": path=save_path
	if not FileAccess.file_exists(path): return false
	var data=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or data.get("version",0)!=1: return false
	for key in ["inventory","hunger","thirst","stamina","clock","day","pos","hp","gold","potions","quest","kills","defeated","nodes","placed","discovered","gathered","crafted","outpost","beacon","upgraded","respawn"]:
		if not data.has(key): return false
	if not data.inventory is Dictionary or not data.pos is Array or data.pos.size()!=3: return false
	for item in inventory: inventory[item]=int(data.inventory.get(item,inventory[item]))
	hunger=data.hunger; thirst=data.thirst; stamina=data.stamina; clock_minutes=data.clock; day=data.day
	game.player.position=Vector3(data.pos[0],data.pos[1],data.pos[2])
	game.player.hp=data.hp; game.player.gold=data.gold; game.player.potions=data.potions; game.quest=data.quest; game.kills=data.kills
	respawn=Vector3(data.respawn[0],data.respawn[1],data.respawn[2])
	outpost_claimed=data.outpost; beacon_lit=data.beacon; upgraded=data.upgraded
	gathered=data.gathered; crafted=data.crafted; discovered=data.discovered
	for i in data.defeated:
		var e=game.enemies[int(i)]
		e.dead=true; e.collision_layer=0; e.visible=false
	for item in nodes:
		item.left=int(data.nodes.get(item.id,item.left))
		if item.left<=0: item.node.scale.y=.18
	# Loading is performed at startup, before any dynamic structures exist.
	placed=data.placed
	for entry in placed: add_structure(entry.kind,Vector3(entry.pos[0],entry.pos[1],entry.pos[2]),false)
	if beacon_lit:
		for item in nodes:
			if item.kind=="beacon": Art.lantern(game,item.node.position+Vector3(0,1,0))
	game.relic.visible=game.quest<2
	game.snap_camera()
	game.toast("Journey resumed · Day "+str(day))
	return true
