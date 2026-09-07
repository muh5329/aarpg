class_name Art
extends RefCounted
static var pbr_cache: Dictionary = {}

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color if glow>0 else color.lerp(Color(color.v,color.v,color.v),.30).darkened(.08)
	m.roughness = 0.88
	if glow > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	return shape(parent, pos, mesh, color, solid)

static func shape(parent: Node3D, pos: Vector3, mesh: Mesh, color: Color, solid: bool = false) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.material_override = material(color)
	parent.add_child(n)
	n.position = pos
	if solid:
		n.create_trimesh_collision()
	return n

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius if top < 0 else top
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	return shape(parent, pos, mesh, color)

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = 16
	mesh.rings = 10
	return shape(parent, pos, mesh, color)

static func label(parent: Node3D, pos: Vector3, text: String, color: Color, size: int = 26) -> Label3D:
	var n = Label3D.new()
	n.text = text
	n.font_size = size
	n.pixel_size = 0.014
	n.modulate = color
	n.outline_size = 4
	n.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	n.no_depth_test = true
	parent.add_child(n)
	n.position = pos
	return n

static func lantern(parent: Node3D, pos: Vector3) -> void:
	var iron=Color("302b25")
	var post=cylinder(parent,pos+Vector3(0,1,0),.065,2,iron)
	post.material_override.metallic=.8
	for y in [.12,.3,1.7]: cylinder(parent,pos+Vector3(0,y,0),.10,.08,iron)
	cylinder(parent,pos+Vector3(0,1.93,0),.13,.27,iron,.31)
	cylinder(parent,pos+Vector3(0,2.05,0),.34,.07,iron)
	for i in range(6):
		var a=i*TAU/6
		beam(parent,pos+Vector3(cos(a)*.29,2.03,sin(a)*.29),pos+Vector3(cos(a)*.25,2.4,sin(a)*.25),.022,iron)
	var flame=ellipsoid(parent,pos+Vector3(0,2.22,0),Vector3(.13,.28,.13),Color("ffae48"))
	flame.material_override=material(Color("ff8c31"),4)
	var heart=ellipsoid(parent,pos+Vector3(0,2.18,0),Vector3(.075,.18,.075),Color("ffe2a1"))
	heart.material_override=material(Color("ffda8a"),6)
	flame.set_meta("flame",true)
	flame.add_to_group("flames")
	var light=OmniLight3D.new()
	parent.add_child(light)
	light.position=pos+Vector3(0,2.35,0)
	light.light_color=Color("ffac57")
	light.light_energy=3.0
	light.omni_range=7
	light.shadow_enabled=true
	light.omni_shadow_mode=OmniLight3D.SHADOW_DUAL_PARABOLOID

static func pbr(name: String, scale_uv: float = 1.0) -> StandardMaterial3D:
	var key=name+str(scale_uv)
	if pbr_cache.has(key): return pbr_cache[key]
	var m=StandardMaterial3D.new()
	m.albedo_texture=load("res://assets/textures/"+name+"_color.jpg")
	m.normal_enabled=true
	m.normal_texture=load("res://assets/textures/"+name+"_normal.jpg")
	m.normal_scale=1.15
	m.roughness_texture=load("res://assets/textures/"+name+"_rough.jpg")
	m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.uv1_triplanar=true
	m.uv1_world_triplanar=true
	m.uv1_scale=Vector3.ONE*scale_uv
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	pbr_cache[key]=m
	return m

static func beam(parent: Node3D, a: Vector3, b: Vector3, radius: float, tint: Color, top: float = -1.0) -> MeshInstance3D:
	var node=cylinder(parent,(a+b)/2,radius,a.distance_to(b),tint,top)
	var axis=(b-a).normalized()
	var side=axis.cross(Vector3.FORWARD).normalized()
	if side.length()<.1: side=axis.cross(Vector3.RIGHT).normalized()
	node.basis=Basis(side,axis,side.cross(axis))
	return node

static func ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, tint: Color, metal: bool = false) -> MeshInstance3D:
	var n=sphere(parent,pos,1,tint)
	n.scale=size
	if metal:
		n.material_override.metallic=.8
		n.material_override.roughness=.38
	return n

static func cape(parent: Node3D, tint: Color) -> MeshInstance3D:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in range(9):
		for x in range(8):
			for v in [Vector2(x,y),Vector2(x+1,y),Vector2(x,y+1),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
				var t=v.y/9.0
				var u=v.x/8.0
				st.set_uv(Vector2(u,t))
				st.add_vertex(Vector3((u-.5)*(.6+t*.38),1.4-t*1.1-sin(u*29)*.04*t,.19+t*.22+sin(u*PI*7)*.065))
	st.generate_normals()
	var n=shape(parent,Vector3.ZERO,st.commit(),tint)
	n.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	return n

static func humanoid(parent: Node3D, color: Color, enemy: bool = false, civilian: bool = false) -> Dictionary:
	var rig=Node3D.new()
	parent.add_child(rig)
	var leather=Color("282322")
	var steel=color.darkened(.2) if civilian else Color("777d7d") if not enemy else Color("453f37")
	var brass=Color("a08a5e")
	var cloak=cape(rig,color.darkened(.3))
	ellipsoid(rig,Vector3(0,1.1,0),Vector3(.29,.39,.21),leather)
	var chest=ellipsoid(rig,Vector3(0,1.16,-.115),Vector3(.29,.28,.16),steel,not civilian)
	for i in range(3):
		ellipsoid(rig,Vector3(0,.9-i*.10,-.14),Vector3(.25+i*.012,.085,.14),steel.darkened(i*.07),not civilian)
	box(rig,Vector3(0,.75,0),Vector3(.54,.09,.39),leather)
	box(rig,Vector3(0,.75,-.23),Vector3(.105,.09,.05),brass)
	for side in [-1,1]:
		var pauldron=ellipsoid(rig,Vector3(side*.35,1.36,0),Vector3(.16,.13,.19) if civilian else Vector3(.24,.15,.27),steel,not civilian)
		pauldron.rotation.z=side*-.25
		ellipsoid(rig,Vector3(side*.39,1.3,-.04),Vector3(.21,.06,.25),brass.darkened(.35),not civilian)
		for k in range(3):
			ellipsoid(rig,Vector3(side*.25,.68-k*.095,.0),Vector3(.15,.075,.22),steel.darkened(.18),not civilian)
	var head=ellipsoid(rig,Vector3(0,1.64,-.015),Vector3(.16,.21,.165),Color("988574"))
	var hood=ellipsoid(rig,Vector3(0,1.69,.04),Vector3(.19,.23,.19),steel.darkened(.18),not civilian)
	# An angular faceplate, brow and nose bridge give a readable helmet silhouette.
	ellipsoid(rig,Vector3(0,1.64,-.154),Vector3(.155,.16,.075),Color("202322"),not civilian)
	box(rig,Vector3(0,1.69,-.212),Vector3(.26,.023,.03),Color("090c0c"))
	box(rig,Vector3(0,1.65,-.228),Vector3(.025,.21,.035),steel)
	beam(rig,Vector3(0,1.92,.10),Vector3(0,1.84,-.15),.035,brass)
	var legs=[]
	for side in [-1,1]:
		var leg=Node3D.new()
		rig.add_child(leg)
		leg.position=Vector3(side*.15,.7,0)
		ellipsoid(leg,Vector3(0,-.18,0),Vector3(.115,.23,.13),leather)
		ellipsoid(leg,Vector3(0,-.35,-.08),Vector3(.13,.10,.09),steel,not civilian)
		ellipsoid(leg,Vector3(0,-.5,0),Vector3(.10,.16,.12),steel.darkened(.2),not civilian)
		ellipsoid(leg,Vector3(0,-.65,-.10),Vector3(.115,.08,.22),leather)
		legs.append(leg)
	var left=Node3D.new()
	rig.add_child(left)
	left.position=Vector3(-.36,1.25,0)
	ellipsoid(left,Vector3(-.015,-.21,0),Vector3(.10,.23,.11),leather)
	ellipsoid(left,Vector3(-.01,-.37,-.025),Vector3(.105,.14,.12),steel,not civilian)
	var hand=Node3D.new()
	rig.add_child(hand)
	hand.position=Vector3(.37,1.25,0)
	ellipsoid(hand,Vector3(.01,-.21,0),Vector3(.10,.23,.11),leather)
	ellipsoid(hand,Vector3(.01,-.37,-.025),Vector3(.105,.14,.12),steel,not civilian)
	var sword=Node3D.new()
	hand.add_child(sword)
	var blade=box(sword,Vector3(0,-.39,-.66),Vector3(.09,.035,1.1),Color("c8d1ce"))
	blade.material_override.metallic=.95
	blade.material_override.roughness=.23
	box(sword,Vector3(0,-.39,-.1),Vector3(.36,.075,.07),brass)
	beam(sword,Vector3(0,-.39,-.1),Vector3(0,-.39,.12),.04,leather)
	var bow=Node3D.new()
	left.add_child(bow)
	bow.position=Vector3(0,-.28,-.12)
	for i in range(12):
		var a=-1.25+i*.21
		var b=a+.21
		beam(bow,Vector3(0,sin(a)*.7,-cos(a)*.35),Vector3(0,sin(b)*.7,-cos(b)*.35),.029,Color("715334"))
	beam(bow,Vector3(0,-.66,-.11),Vector3(0,.66,-.11),.009,Color("9d977d"))
	bow.visible=false
	sword.visible=not civilian
	if enemy:
		cloak.visible=false
		rig.scale=Vector3(1.12,1.06,1.08)
		for side in [-1,1]:
			beam(rig,Vector3(side*.14,1.81,.04),Vector3(side*.37,2.03,.1),.07,Color("a99a79"),.005)
			for i in range(3):
				beam(rig,Vector3(side*(.27+i*.09),1.44,.03),Vector3(side*(.3+i*.16),1.74-i*.08,.07),.06,Color("9d927a"),.002)
			var eye=sphere(rig,Vector3(side*.075,1.7,-.224),.022,Color("dc6336"))
			eye.material_override=material(Color("fa7239"),2)
	return {"rig":rig,"left":legs[0],"right":legs[1],"hand":hand,"sword":sword,"bow":bow,"cloak":cloak,"head":head,"hood":hood}
