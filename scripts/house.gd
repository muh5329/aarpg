class_name CutawayHouse
extends Node3D
var title: String
var cut_parts: Array[Node3D] = []
var opened = false
var visited = false
var transitions = 0
var back_wall: MeshInstance3D
var far_wall: MeshInstance3D

func build(at: Vector3, house_title: String, tint: Color) -> void:
	position = at
	title = house_title
	Art.box(self,Vector3(0,-.035,0),Vector3(7,.10,6),Color("555a4d"))
	for x in range(12):
		var floorboard=Art.box(self,Vector3(-3.2+x*.58,.035,0),Vector3(.55,.07,5.6),Color("675b42"))
		floorboard.material_override=Art.pbr("timber",.4)
	back_wall=Art.box(self,Vector3(0,1.45,-3),Vector3(7,2.9,.3),tint,true)
	var masonry=Art.pbr("masonry",.32)
	back_wall.material_override=masonry
	for side in [-1,1]:
		var wall = Art.box(self,Vector3(side*3.5,1.45,0),Vector3(.3,2.9,6),tint,true)
		wall.material_override=masonry
		if side>0: cut_parts.append(wall)
		else: far_wall=wall
		var front = Art.box(self,Vector3(side*2.32,1.45,3),Vector3(2.36,2.9,.3),tint,true)
		front.material_override=masonry
		cut_parts.append(front)
		for z in [-3.0,3.0]:
			var beam = Art.box(self,Vector3(side*3.48,1.5,z),Vector3(.23,3.1,.24),Color("343d34"))
			if z > 0: cut_parts.append(beam)
		var window = Art.box(self,Vector3(side*2.3,1.55,3.18),Vector3(.86,.88,.05),Color("e3b66b"))
		cut_parts.append(window)
		for dx in [-.47,0,.47]:
			cut_parts.append(Art.box(self,Vector3(side*2.3+dx,1.55,3.23),Vector3(.07,1.0,.09),Color("373c32")))
	cut_parts.append(Art.box(self,Vector3(0,2.72,3),Vector3(2.35,.38,.32),Color("384437")))
	var roof = Node3D.new()
	add_child(roof)
	cut_parts.append(roof)
	for side in [-1,1]:
		for row in range(8):
			for col in range(13):
				var px=side*(.22+row*.49)
				var py=5.05-abs(px)*.58
				var pz=-3.35+col*.55+(row%2)*.1
				var tile=Art.box(roof,Vector3(px,py,pz),Vector3(.57,.09,.61),Color("434744"))
				tile.rotation.z=-side*.525
				tile.material_override=Art.pbr("roof",.4)
		# Timber trusses and layered stone buttresses follow the cutaway group.
		for z in [-3.18,3.2]:
			var rafter=Art.beam(roof,Vector3(0,5.1,z),Vector3(side*3.95,2.88,z),.11,Color("433a2f"))
			rafter.material_override=Art.pbr("timber",.6)
		for z in [-2.9,0,2.9]:
			var group=Node3D.new()
			add_child(group)
			if side>0 or z>0: cut_parts.append(group)
			var support=Art.box(group,Vector3(side*3.66,1.0,z),Vector3(.4,2.0,.55),Color("666056"))
			support.material_override=masonry
			var cap=Art.box(group,Vector3(side*3.66,2.06,z),Vector3(.52,.15,.65),Color("666056"))
			cap.material_override=masonry
		# Deep window reveals and iron grilles.
		for y in [1.13,1.97]:
			var sill=Art.box(self,Vector3(side*2.3,y,3.24),Vector3(1.1,.12,.24),Color("696259"))
			sill.material_override=masonry
			cut_parts.append(sill)
	for z in [-3.01,3.01]:
		var gable_surface=SurfaceTool.new()
		gable_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for v in [Vector3(-3.48,2.88,z),Vector3(0,5.0,z),Vector3(3.48,2.88,z)]:
			gable_surface.add_vertex(v)
		gable_surface.generate_normals()
		var gable=Art.shape(roof,Vector3.ZERO,gable_surface.commit(),Color("635e54"))
		var gable_material=masonry.duplicate()
		gable_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		gable.material_override=gable_material
	var ridge=Art.beam(roof,Vector3(0,5.09,-3.7),Vector3(0,5.09,3.7),.13,Color("494338"))
	ridge.material_override=Art.pbr("timber",.6)
	var chimney=Art.box(roof,Vector3(2.0,4.65,-1.6),Vector3(.72,2.8,.82),Color("69665f"))
	chimney.material_override=masonry
	Art.box(roof,Vector3(2.0,6.08,-1.6),Vector3(.94,.18,1.04),Color("504e47"))
	for side in [-1,1]:
		var jamb=Art.box(self,Vector3(side*1.2,1.25,3.22),Vector3(.19,2.5,.45),Color("6c665b"))
		jamb.material_override=masonry
		cut_parts.append(jamb)
	for i in range(9):
		var a=i*PI/8
		var voussoir=Art.box(self,Vector3(cos(a)*1.2,2.3+sin(a)*.65,3.22),Vector3(.28,.3,.46),Color("80766a"))
		voussoir.rotation.z=a-PI/2
		voussoir.material_override=masonry
		cut_parts.append(voussoir)
	# Furniture leaves the central doorway and aisle free.
	Art.box(self,Vector3(-2.2,.35,-1.5),Vector3(1.6,.6,2.3),Color("483c2c"),true)
	Art.box(self,Vector3(-2.2,.7,-1.5),Vector3(1.5,.18,2.1),Color("4a706c"))
	Art.box(self,Vector3(-2.2,.83,-2.18),Vector3(1.35,.15,.45),Color("c3b694"))
	Art.box(self,Vector3(2.35,.48,-1.2),Vector3(1.25,.95,1.8),Color("645139"),true)
	for i in range(3):
		Art.box(self,Vector3(2.2,1.0,-1.6+i*.35),Vector3(.6,.09,.22),Color("a9956e"))
	Art.box(self,Vector3(0,.095,-.5),Vector3(2.1,.035,2.6),Color("6d4337"))
	Art.box(self,Vector3(0,1.1,-2.72),Vector3(1.8,2.0,.25),Color("3b3930"))
	for y in [.45,1.1,1.75]:
		Art.box(self,Vector3(0,y,-2.48),Vector3(1.8,.10,.42),Color("896e46"))
		for x in range(5):
			Art.box(self,Vector3(-.6+x*.28,y+.2,-2.49),Vector3(.14,.3,.21),Color("79674b") if x%2 else Color("55706b"))
	Art.lantern(self,Vector3(2.8,0,2.45))
	if at.x>0:
		for i in range(3):
			var target=Art.cylinder(self,Vector3(-3.25,1.55,-1.7+i*1.35),.38,.08,Color("b5a47a"))
			target.rotation.z=PI/2
	else:
		for i in range(3):
			Art.cylinder(self,Vector3(2.4,1.18,-1.4+i*.3),.095,.28,Color("759d88"),.055)
	for i in range(4):
		var wax=Art.cylinder(self,Vector3(2.15+i*.14,1.1,-1.8),.045,.22+i*.04,Color("b9a988"))
		var flame=Art.sphere(self,Vector3(2.15+i*.14,1.25+i*.04,-1.8),.037,Color("ffc985"))
		flame.material_override=Art.material(Color("ffb950"),3)
	Art.label(self,Vector3(0,2.0,3.28),title,Color("cfbea0"),17)
	for child in get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D and child.position.y<1.4:
			var c=child.material_override.albedo_color
			if c.r>c.b*1.25 and c.r<.65: child.material_override=Art.pbr("timber",.5)
	Art.box(self,Vector3(0,.025,3.55),Vector3(2.1,.05,1.0),Color("99917b"))

func update_cutaway(player_position: Vector3) -> void:
	var p = player_position - global_position
	# The approach margin removes obstruction before crossing the threshold;
	# hysteresis avoids flickering at the boundary and always restores on exit.
	var behind = p.z < -2.9 and p.z > -8.0 and p.x > -7.0 and p.x < 3.8
	back_wall.visible=not behind
	far_wall.visible=not behind
	var inside = abs(p.x) < 3.7 and p.z > -3.1 and p.z < 4.6
	if opened:
		inside = abs(p.x) < 4.3 and p.z > -3.7 and p.z < 5.5
	inside = inside or behind
	if inside != opened:
		opened = inside
		transitions += 1
		for part in cut_parts: part.visible = not opened
	if abs(p.x)<3.2 and abs(p.z)<2.8: visited = true
