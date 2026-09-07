class_name FrontierBuilder
extends RefCounted
var game: Node3D
var rng=RandomNumberGenerator.new()
var art_world: WorldBuilder

func build(root: Node3D) -> void:
	game=root
	rng.seed=98361
	art_world=WorldBuilder.new()
	art_world.game=game
	art_world.rng.seed=391
	# A continuous 176 x 188 m playable valley with loops between landmarks.
	var floor=Art.box(game,Vector3(0,-.3,-6),Vector3(220,.6,220),Color("545044"),true)
	floor.material_override=Art.pbr("earth",.22)
	for data in [ [Vector3(0,0,10),Vector2(116,4.8)], [Vector3(-40,0,7),Vector2(4.8,110)], [Vector3(47,0,7),Vector2(4.8,110)], [Vector3(0,0,-61),Vector2(4.8,68)], [Vector3(3.5,0,55),Vector2(92,4.8)], [Vector3(3.5,0,-47),Vector2(92,4.8)] ]:
		art_world.path(data[0],data[1])
	# Clear tree trunks from roads extended through the original settlement margins.
	for tree in game.trees.duplicate():
		if abs(tree.position.z-10)<3.3 or abs(tree.position.x)<3.3:
			game.trees.erase(tree)
			tree.get_parent().remove_child(tree)
			tree.queue_free()
	for data in [[Vector3(54,0,3),"BRIAR FARMHOUSE"],[Vector3(66,0,3),"FARM STOREHOUSE"],[Vector3(-48,0,49),"RANGER'S LODGE"],[Vector3(54,0,-54),"ABANDONED TANNERY"],[Vector3(-52,0,3),"WOODCUTTER'S CABIN"]]:
		var house=CutawayHouse.new()
		game.add_child(house)
		house.build(data[0],data[1],Color("7c7669"))
		game.houses.append(house)
	# Every district has legible road signs and its own resources.
	for poi in game.survival.pois:
		var p=Vector3(poi.pos.x,0,poi.pos.y)
		Art.label(game,p+Vector3(0,3.2,0),poi.name.to_upper(),Color("c9bea2"),24)
		if poi.name!="Hollowmere": Art.lantern(game,p+Vector3(-2.2,0,1.6))
	resource("starter_crate","cache",Vector3(3.5,0,13),"settlement supplies",{"wood":4,"stone":2,"fiber":3,"food":3,"water":2,"hide":2},1)
	resource("town_well","well",Vector3(-4.4,0,14.3),"well",{},1)
	resource("camp_kitchen","fire",Vector3(-12.8,0,10),"village hearth",{},1)
	resource("farm_cache","cache",Vector3(54,0,3),"pantry",{"raw_food":6,"food":3,"fiber":4,"hide":2},1)
	resource("store_cache","cache",Vector3(66,0,3),"storehouse",{"wood":6,"stone":4,"bandage":3,"arrows":12},1)
	resource("timber_cache","cache",Vector3(-52,0,3),"woodcutter's chest",{"wood":8,"fiber":6,"food":2},1)
	resource("tannery_cache","cache",Vector3(54,0,-54),"tannery chest",{"hide":6,"fiber":6,"bandage":2},1)
	resource("outpost","outpost",Vector3(-48,0,49),"ranger shelter",{},1)
	resource("beacon","beacon",Vector3(-34,0,55),"signal beacon",{},1)
	resource("spring","well",Vector3(43,0,60),"marsh spring",{},1)
	resource("marsh_cache","cache",Vector3(51,0,58),"abandoned fishing camp",{"raw_food":4,"hide":3,"water":3},1)
	# Reliable marked gathering sites; capacities support multiple camps and recovery.
	for i in range(7):
		resource("timber_"+str(i),"wood",Vector3(-47-i%3*3.1,0,12+i/3*3.4),"fallen timber",{"wood":4},3)
		resource("fiber_"+str(i),"fiber",Vector3(-34+i%3*2.3,0,15+i/3*2.4),"flax",{"fiber":3},3)
	for i in range(6):
		resource("stone_"+str(i),"stone",Vector3(-45-i%3*3.1,0,-43+i/3*3.2),"stone seam",{"stone":4},4)
		resource("ore_"+str(i),"ore",Vector3(-45-i%3*3.1,0,-51-i/3*3.1),"iron vein",{"ore":3,"stone":1},3)
	for i in range(4):
		resource("nearstone_"+str(i),"stone",Vector3(-23-i*2.8,0,14),"field stone",{"stone":3},2)
		resource("farm_crop_"+str(i),"cache",Vector3(51+i*2,0,17),"root vegetables",{"raw_food":3},1)
		resource("marsh_reed_"+str(i),"fiber",Vector3(39+i*2,0,64),"reeds",{"fiber":3},3)
	# Farm plots and fences, quarry walls, water and old military ruins.
	for i in range(7):
		var soil=Art.box(game,Vector3(56,.035,16+i*1.1),Vector3(13,.05,.6),Color("322c23"))
		soil.material_override=Art.pbr("earth",.6)
		for j in range(10):
			Art.ellipsoid(game,Vector3(51+j, .18,16+i*1.1),Vector3(.16,.22,.16),Color("626548"))
	for i in range(13):
		var p=Vector3(-58-i%3*2.0,0,-58+i*1.45)
		var rock=Art.sphere(game,p+Vector3(0,1,0),1.4+rng.randf(),Color("62645e"))
		rock.scale=Vector3(1,1.3,.8)
		rock.material_override=Art.pbr("masonry",.3)
		rock.create_trimesh_collision()
	var water=Art.box(game,Vector3(60,-.005,68),Vector3(25,.025,19),Color("273d3b"))
	water.material_override.roughness=.12
	water.material_override.metallic=.5
	# Reeds ring a shallow wetland. The central trail stays dry and accessible.
	for i in range(70):
		var p=Vector3(rng.randf_range(48,72),0,rng.randf_range(60,78))
		for j in range(2): Art.beam(game,p,p+Vector3(.1,rng.randf_range(.5,1.2),.1),.025,Color("65614a"),.01)
	for side in [-1,1]:
		for z in [-74,-81,-88]:
			var wall=Art.box(game,Vector3(side*10,1.4,z),Vector3(1.0,2.8,6.5),Color("68655d"),true)
			wall.material_override=Art.pbr("masonry",.4)
			for i in range(3):
				Art.box(game,Vector3(side*10,3.05,z-2+i*2),Vector3(1.1,.5,.8),Color("605d55")).material_override=Art.pbr("masonry",.4)
	art_world.arch(Vector3(0,0,-69),3.6,3.5)
	art_world.arch(Vector3(0,0,-91),5.5,4.2)
	resource("signal_lens","cache",Vector3(0,0,-88),"warden's signal chest",{"relay":1,"ore":4,"food":3},1,true)
	for data in [[Vector3(42,0,23),"prowler"],[Vector3(61,0,24),"shambler"],[Vector3(-58,0,19),"shambler"],[Vector3(-31,0,-42),"prowler"],[Vector3(-48,0,-59),"brute"],[Vector3(40,0,-41),"shambler"],[Vector3(55,0,-45),"prowler"],[Vector3(36,0,67),"shambler"],[Vector3(56,0,62),"shambler"],[Vector3(-28,0,69),"prowler"],[Vector3(-6,0,-75),"prowler"],[Vector3(6,0,-75),"shambler"],[Vector3(0,0,-82),"warden"]]:
		var enemy=game.Enemy.new()
		enemy.game=game
		enemy.archetype=data[1]
		enemy.position=data[0]
		game.add_child(enemy)
		game.enemies.append(enemy)
	# Sparse outer woodland: concentrated clusters, with roads and POIs kept clear.
	for i in range(150):
		var p=Vector3(rng.randf_range(-82,82),0,rng.randf_range(-94,82))
		if abs(p.x)<30 and p.z>-34 and p.z<28: continue
		if abs(p.x)<5 or abs(p.x+40)<5 or abs(p.x-47)<5 or abs(p.z-10)<5 or abs(p.z-55)<5 or abs(p.z+47)<5: continue
		var near=false
		for poi in game.survival.pois:
			if Vector2(p.x,p.z).distance_to(poi.pos)<17: near=true
		if near: continue
		art_world.tree(p,rng.randf_range(.7,1.15))
	# Buildings added beyond the original village need clearance from both
	# woodland passes, including enough margin for overhanging branches.
	for tree in game.trees.duplicate():
		for house in game.houses:
			if Vector2(tree.position.x-house.position.x,tree.position.z-house.position.z).length()<8:
				game.trees.erase(tree)
				tree.get_parent().remove_child(tree)
				tree.queue_free()
				break
	# Physical cliffs mark the valley boundary instead of invisible movement clamps.
	for side in [-1,1]:
		var edge=Art.box(game,Vector3(side*88,1,-6),Vector3(4,3,192),Color("454a42"),true)
		edge.material_override=Art.pbr("masonry",.25)
	for z in [-101,89]:
		var edge=Art.box(game,Vector3(0,1,z),Vector3(180,3,4),Color("454a42"),true)
		edge.material_override=Art.pbr("masonry",.25)

func resource(id: String, kind: String, pos: Vector3, label: String, items: Dictionary, amount: int, guarded: bool=false) -> void:
	var root=Node3D.new()
	game.add_child(root)
	root.position=pos
	match kind:
		"wood":
			Art.beam(root,Vector3(-.8,.22,0),Vector3(.8,.25,.15),.23,Color("66543d")).material_override=Art.pbr("bark",.6)
			Art.beam(root,Vector3(0,.25,0),Vector3(.2,.55,.5),.10,Color("66543d"),.03).material_override=Art.pbr("bark",.6)
		"stone","ore":
			var rock=Art.sphere(root,Vector3(0,.35,0),.65,Color("787a73"))
			rock.scale=Vector3(1,.7,.8)
			rock.material_override=Art.pbr("masonry",.5)
			if kind=="ore":
				for i in range(4): Art.ellipsoid(root,Vector3(-.3+i*.2,.65,0),Vector3(.065,.06,.2),Color("ac7350"),true)
		"fiber":
			for i in range(7):
				var a=i*TAU/7
				Art.beam(root,Vector3.ZERO,Vector3(cos(a)*.4,.55+i*.04,sin(a)*.4),.03,Color("7c845c"),.008)
		"cache":
			Art.box(root,Vector3(0,.35,0),Vector3(.9,.7,.6),Color("776043")).material_override=Art.pbr("timber",.5)
			for side in [-1,1]: Art.box(root,Vector3(side*.3,.71,0),Vector3(.06,.045,.65),Color("353736"))
		"well":
			Art.cylinder(root,Vector3(0,.13,0),.75,.26,Color("676858")).material_override=Art.pbr("masonry",.5)
			Art.cylinder(root,Vector3(0,.27,0),.54,.02,Color("528889"))
		"outpost":
			Art.box(root,Vector3(0,.6,-.5),Vector3(1.3,1.2,.7),Color("675d47")).material_override=Art.pbr("timber",.5)
		"beacon":
			Art.cylinder(root,Vector3(0,1,0),.4,2,Color("6a665a")).material_override=Art.pbr("masonry",.5)
			Art.cylinder(root,Vector3(0,2.1,0),.7,.15,Color("44443a"))
		"fire":
			Art.lantern(root,Vector3.ZERO)
	game.survival.nodes.append({"id":id,"kind":kind,"node":root,"left":amount,"items":items,"label":label,"guarded":guarded})
