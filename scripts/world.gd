class_name WorldBuilder
extends RefCounted
var game: Node3D
var rng = RandomNumberGenerator.new()
var stone=Color("555551")
var wood=Color("514c37")

func build(root: Node3D) -> void:
	game=root
	rng.seed=7291
	var env=WorldEnvironment.new()
	var e=Environment.new()
	e.background_mode=Environment.BG_COLOR
	e.background_color=Color("253d40")
	e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color=Color("71818b")
	e.ambient_light_energy=.19
	e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	e.ssao_enabled=true
	e.ssao_radius=1.4
	e.ssao_intensity=1.5
	e.glow_enabled=true
	e.glow_intensity=.55
	e.fog_enabled=true
	e.fog_light_color=Color("343a3e")
	e.fog_density=.007
	e.volumetric_fog_enabled=true
	e.volumetric_fog_density=.010
	e.volumetric_fog_albedo=Color("667079")
	e.volumetric_fog_length=55
	e.volumetric_fog_detail_spread=3
	env.environment=e
	root.add_child(env)
	var sun=DirectionalLight3D.new()
	game.sun=sun
	root.add_child(sun)
	sun.rotation_degrees=Vector3(-35,-35,0)
	sun.light_color=Color("b5c1cf")
	sun.light_energy=1.05
	sun.shadow_enabled=true
	sun.light_angular_distance=1.0
	sun.directional_shadow_max_distance=70
	var terrain=Art.box(root,Vector3(0,-.3,-3),Vector3(140,.6,140),Color("344d3e"),true)
	terrain.material_override=Art.pbr("earth",.22)
	path(Vector3(0,0,-5),Vector2(4.5,53))
	path(Vector3(0,0,10),Vector2(27,4))
	for x in [-8,8]: path(Vector3(x,0,8),Vector2(2.6,6))
	# Village boundary and open gate.
	for side in [-1,1]:
		for i in range(6):
			Art.box(root,Vector3(side*(4+i*2),.6,-3),Vector3(1.9,1.2,.8),stone,true).material_override=Art.pbr("masonry",.4)
			Art.box(root,Vector3(side*(4+i*2),1.28,-3),Vector3(2.0,.16,.96),Color("7b8370"))
		Art.box(root,Vector3(side*3,1.6,-3),Vector3(1.1,3.2,1.1),stone,true).material_override=Art.pbr("masonry",.4)
		Art.box(root,Vector3(side*3,3.25,-3),Vector3(1.3,.2,1.3),Color("969781"))
		Art.lantern(root,Vector3(side*2.8,2.2,-3))
	for x in [-8,8]:
		var h=CutawayHouse.new()
		root.add_child(h)
		h.build(Vector3(x,0,2),"MARA'S HEARTH" if x<0 else "THE WAYFARER",Color("7e7770") if x<0 else Color("77736b"))
		game.houses.append(h)
	# Well and village market.
	for i in range(12):
		var a=i*TAU/12
		var block=Art.box(root,Vector3(-4.4+cos(a)*.85,.48,13+sin(a)*.85),Vector3(.47,.8,.4),stone,true)
		block.rotation.y=-a
		block.material_override=Art.pbr("masonry",.45)
	Art.cylinder(root,Vector3(-4.4,.2,13),.7,.1,Color("25444b"))
	for x in [-5.5,-3.3]: Art.box(root,Vector3(x,1.35,13),Vector3(.16,2.7,.16),wood).material_override=Art.pbr("timber",.5)
	Art.box(root,Vector3(-4.4,2.6,13),Vector3(2.5,.14,.5),wood).material_override=Art.pbr("timber",.5)
	Art.beam(root,Vector3(-4.4,2.6,13),Vector3(-4.4,.5,13),.022,Color("7a6951"))
	for i in range(4):
		Art.cylinder(root,Vector3(12+i%2*.9,.4,10+i/2*.85),.38,.8,Color("716143")).material_override=Art.pbr("timber",.7)
		Art.cylinder(root,Vector3(12+i%2*.9,.62,10+i/2*.85),.4,.06,Color("39433a"))
	Art.box(root,Vector3(8,.68,12),Vector3(3.8,1.3,.9),wood,true).material_override=Art.pbr("timber",.6)
	for i in range(9): Art.sphere(root,Vector3(6.5+i*.36,1.45,12),.16,Color("ab8f48") if i%2 else Color("8b543b"))
	for x in [6.1,9.9]: Art.box(root,Vector3(x,1.6,12.5),Vector3(.12,3.2,.12),wood).material_override=Art.pbr("timber",.5)
	var canopy=Art.box(root,Vector3(8,3.0,12),Vector3(4.3,.12,2),Color("493730"))
	canopy.rotation.x=.15
	canopy.material_override=Art.pbr("timber",.4)
	for x in [6.1,9.9]:
		Art.beam(root,Vector3(x,2.9,12.4),Vector3(x,2.1,11.4),.065,wood).material_override=Art.pbr("timber",.5)
	for p in [Vector3(-2,0,8),Vector3(2,0,15),Vector3(-11,0,9),Vector3(11,0,7),Vector3(-2,0,-11)]: Art.lantern(root,p)
	# Ruined sanctuary with broken pillars and a shallow turquoise basin.
	Art.box(root,Vector3(0,.015,-23),Vector3(15,.03,13),Color("4e5e52")).material_override=Art.pbr("road",.25)
	for x in [-6,6]:
		for z in [-28,-23,-18]:
			Art.box(root,Vector3(x,.18,z),Vector3(1.7,.35,1.7),stone,true)
			var height=rng.randf_range(1.6,3.8)
			Art.cylinder(root,Vector3(x,height/2,z),.49,height,Color("778272"),.4).material_override=Art.pbr("masonry",.45)
			Art.box(root,Vector3(x,height,z),Vector3(1.3,.3,1.3),stone)
	Art.box(root,Vector3(0,.1,-28),Vector3(9,.2,2.1),stone).material_override=Art.pbr("masonry",.5)
	Art.box(root,Vector3(0,.2,-26.6),Vector3(4,.4,2.6),Color("727e6e")).material_override=Art.pbr("masonry",.5)
	Art.cylinder(root,Vector3(0,.53,-26.7),1.05,.55,stone).material_override=Art.pbr("masonry",.5)
	var relic=Art.sphere(root,Vector3(0,1.35,-26.7),.35,Color("8de4cc"))
	relic.material_override=Art.material(Color("67e6cb"),2)
	game.relic=relic
	Art.label(root,Vector3(0,2.2,-26.7),"THE EMBER SEED",Color("c4ead2"),22)
	Art.lantern(root,Vector3(-2,0,-27))
	Art.lantern(root,Vector3(2,0,-27))
	# Forest silhouette, rocks, flowers. Keep navigable corridors generous.
	for i in range(110):
		var x=rng.randf_range(-29,29)
		var z=rng.randf_range(-32,26)
		if abs(x)<17 and z>-4 and z<18: continue
		if abs(x)<8: continue
		tree(Vector3(x,0,z),rng.randf_range(.7,1.3))
	for i in range(90):
		var x=rng.randf_range(-25,25)
		var z=rng.randf_range(-31,23)
		if abs(x)<4 or (abs(x)<16 and z>-4 and z<17): continue
		var rock=Art.sphere(root,Vector3(x,.2,z),rng.randf_range(.2,.7),Color("697567"))
		rock.scale=Vector3(1,.65,.8)
		rock.material_override=Art.pbr("masonry",.5)
	for i in range(500):
		var x=rng.randf_range(-25,25)
		var z=rng.randf_range(-32,24)
		if abs(x)<2.8 or (abs(x)<12 and z>-3 and z<7): continue
		for j in range(3):
			var stem=Art.beam(root,Vector3(x,.04,z),Vector3(x+rng.randf_range(-.18,.18),rng.randf_range(.13,.48),z+rng.randf_range(-.18,.18)),.012,Color("6a6049"),.003)
	# Ruined gothic gateway and a partially collapsed sanctuary arcade.
	arch(Vector3(0,0,-3),3.0,3.15)
	arch(Vector3(0,0,-28.5),4.0,3.5)
	for side in [-1,1]:
		for z in [-19,-24,-29]:
			var buttress=Art.box(root,Vector3(side*7.1,1.4,z),Vector3(.7,2.8,1.0),stone)
			buttress.material_override=Art.pbr("masonry",.5)
			for row in range(4):
				var stoneblock=Art.box(root,Vector3(side*7.1,2.8+row*.32,z),Vector3(.92-row*.15,.35,1.2-row*.1),stone)
				stoneblock.material_override=Art.pbr("masonry",.5)
		for z in [17,20,23]:
			grave(Vector3(side*rng.randf_range(7,13),0,z),rng.randf_range(-.4,.4))
	for i in range(110):
		var p=Vector3(rng.randf_range(-14,14),.09,rng.randf_range(-31,-5))
		if abs(p.x)<3: continue
		var rubble=Art.box(root,p,Vector3(rng.randf_range(.15,.7),rng.randf_range(.1,.35),rng.randf_range(.2,.7)),stone)
		rubble.rotation=Vector3(rng.randf_range(-.25,.25),rng.randf()*TAU,rng.randf_range(-.2,.2))
		rubble.material_override=Art.pbr("masonry",.5)
	# Warped fence stakes, not an empty lawn, frame the village road.
	for side in [-1,1]:
		for i in range(12):
			var p=Vector3(side*(15.0+rng.randf_range(-.1,.1)),0,5+i*1.5)
			var post=Art.beam(root,p,p+Vector3(rng.randf_range(-.15,.15),1.2,0),.08,wood,.035)
			post.material_override=Art.pbr("timber",.5)
			if i<11:
				for y in [.5,.9]:
					Art.beam(root,p+Vector3(0,y,0),p+Vector3(0,y,1.5),.04,wood)
	# Grit, airborne ash and low mist unify the open spaces.
	var ash=GPUParticles3D.new()
	root.add_child(ash)
	ash.position=Vector3(0,2,-4)
	ash.amount=160
	ash.lifetime=12
	ash.visibility_aabb=AABB(Vector3(-35,-5,-35),Vector3(70,15,70))
	var pm=ParticleProcessMaterial.new()
	pm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents=Vector3(26,3,30)
	pm.direction=Vector3(-1,.2,.2)
	pm.spread=15
	pm.initial_velocity_min=.2
	pm.initial_velocity_max=.6
	pm.gravity=Vector3.ZERO
	pm.scale_min=.012
	pm.scale_max=.035
	ash.process_material=pm
	var mote=SphereMesh.new()
	mote.radius=1
	mote.height=2
	mote.material=Art.material(Color("b3aa96"),.3)
	ash.draw_pass_1=mote

func arch(pos: Vector3, half_width: float, base: float) -> void:
	var group=Node3D.new()
	game.add_child(group)
	group.position=pos
	game.arches.append(group)
	for i in range(19):
		var x=-half_width+i*half_width/9
		var y=base+pow(maxf(0,1-abs(x/half_width)),.72)*half_width
		var b=Art.box(group,Vector3(x,y,0),Vector3(.48,.65,1.1),stone)
		b.rotation.z=(.7 if x<0 else -.7)
		b.material_override=Art.pbr("masonry",.5)
	for side in [-1,1]:
		var column=Art.box(group,Vector3(side*half_width,base/2,0),Vector3(.65,base,1.0),stone)
		column.material_override=Art.pbr("masonry",.5)

func grave(pos: Vector3, angle: float) -> void:
	var root=Node3D.new()
	game.add_child(root)
	root.position=pos
	root.rotation.y=angle
	var tomb=Art.box(root,Vector3(0,.12,.7),Vector3(.85,.24,1.6),stone)
	tomb.material_override=Art.pbr("masonry",.65)
	var slab=Art.box(root,Vector3(0,.65,0),Vector3(.62,1.3,.19),stone)
	slab.rotation.z=angle*.3
	slab.material_override=Art.pbr("masonry",.5)
	Art.box(root,Vector3(0,.86,-.12),Vector3(.045,.44,.03),Color("1e2222"))
	Art.box(root,Vector3(0,.94,-.12),Vector3(.27,.045,.03),Color("1e2222"))

func path(center: Vector3, size: Vector2) -> void:
	var road=Art.box(game,center+Vector3(0,.025,0),Vector3(size.x,.05,size.y),Color("605d56"))
	var worn=ShaderMaterial.new()
	worn.shader=load("res://shaders/road.gdshader")
	for field in ["road_color","earth_color","road_normal","earth_normal"]:
		worn.set_shader_parameter(field,load("res://assets/textures/"+field+".jpg"))
	worn.set_shader_parameter("center",Vector2(center.x,center.z))
	worn.set_shader_parameter("half_size",size/2)
	road.material_override=worn
	# Irregular broken kerbs avoid the old perfect paving grid.
	if size.y>size.x:
		for side in [-1,1]:
			for j in range(int(size.y/1.2)):
				if rng.randf()<.18: continue
				var p=center+Vector3(side*(size.x/2+.12),.08,-size.y/2+j*1.2)
				var kerb=Art.box(game,p,Vector3(.22,.18,rng.randf_range(.5,1.1)),stone)
				kerb.rotation.y=rng.randf_range(-.08,.08)
				kerb.material_override=Art.pbr("masonry",.5)

func tree(pos: Vector3, scale_factor: float) -> void:
	var n=Node3D.new()
	game.add_child(n)
	game.trees.append(n)
	n.position=pos
	n.scale=Vector3.ONE*scale_factor
	var bend=Vector3(rng.randf_range(-.7,.7),3.1,rng.randf_range(-.5,.5))
	var trunk=Art.beam(n,Vector3.ZERO,bend,.24,wood,.12)
	trunk.material_override=Art.pbr("bark",.7)
	trunk.create_trimesh_collision()
	for i in range(7):
		var a=rng.randf()*TAU
		var begin=bend*(.45+i*.07)
		var end=begin+Vector3(cos(a)*rng.randf_range(1,2.3),rng.randf_range(.8,2.2),sin(a)*rng.randf_range(1,2.3))
		var limb=Art.beam(n,begin,end,.085,wood,.025)
		limb.material_override=Art.pbr("bark",.7)
		for j in range(2):
			var tip=end+Vector3(cos(a+j-.5)*.7,rng.randf_range(.3,1.0),sin(a+j-.5)*.7)
			var twig=Art.beam(n,end,tip,.025,wood,.002)
			twig.material_override=Art.pbr("bark",.7)
	for i in range(5):
		var a=i*TAU/5
		var root=Art.beam(n,Vector3(0,.3,0),Vector3(cos(a)*.8,.03,sin(a)*.8),.12,wood,.015)
		root.material_override=Art.pbr("bark",.7)
