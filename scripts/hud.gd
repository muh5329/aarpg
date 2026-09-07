extends Control
var game: Node3D
var font: Font=ThemeDB.fallback_font
var title_font: SystemFont
var cream=Color("d5cbb9")
var muted=Color("958e82")
var gold=Color("9b8154")
var ink=Color(.035,.03,.029,.9)

func _ready() -> void:
	title_font=SystemFont.new()
	title_font.font_names=PackedStringArray(["Baskerville","Georgia","serif"])

func text(at: Vector2, value: String, size_px: int=18, color: Color=Color("d5cbb9")) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func heading(at: Vector2, value: String, size_px: int=23, color: Color=Color("cabc9e")) -> void:
	draw_string(title_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func panel(rect: Rect2) -> void:
	draw_rect(rect,ink)
	draw_rect(rect,Color("5b5040"),false,1)
	for corner in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
		var points=PackedVector2Array([corner+Vector2(0,-3),corner+Vector2(3,0),corner+Vector2(0,3),corner+Vector2(-3,0)])
		draw_colored_polygon(points,gold)

func centered(value: String, y: float, size_px: int, color: Color) -> void:
	text(Vector2((size.x-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x)/2,y),value,size_px,color)

func skill_icon(center: Vector2, kind: int, color: Color) -> void:
	if kind==0:
		draw_line(center+Vector2(-10,11),center+Vector2(12,-14),color,3,true)
		draw_line(center+Vector2(-11,1),center+Vector2(1,11),color,2,true)
		draw_line(center+Vector2(-11,12),center+Vector2(-15,16),gold,4,true)
	elif kind==1:
		draw_arc(center+Vector2(-8,0),18,-PI/2,PI/2,24,color,2,true)
		draw_line(center+Vector2(-8,-18),center+Vector2(-8,18),color,1,true)
		draw_line(center+Vector2(-14,0),center+Vector2(19,0),color,2,true)
		draw_line(center+Vector2(13,-5),center+Vector2(19,0),color,2,true)
	elif kind==2:
		for i in range(3):
			draw_line(center+Vector2(-12+i*9,-12),center+Vector2(-3+i*9,0),color,2,true)
			draw_line(center+Vector2(-3+i*9,0),center+Vector2(-12+i*9,12),color,2,true)
	else:
		draw_circle(center+Vector2(0,5),10,Color("783d32"))
		draw_arc(center+Vector2(0,5),10,0,TAU,24,color,1,true)
		draw_rect(Rect2(center+Vector2(-4,-13),Vector2(8,10)),color,false,2)
		draw_line(center+Vector2(-6,-14),center+Vector2(6,-14),gold,3,true)

func _draw() -> void:
	if title_font==null: return
	var w=size.x
	var h=size.y
	# Soft edge vignette leaves the middle of the world unobscured.
	for i in range(16):
		draw_rect(Rect2(Vector2(i*4,i*3),size-Vector2(i*8,i*6)),Color(0,0,0,.017),false,12)
	heading(Vector2(34,48),game.location,27)
	draw_line(Vector2(35,60),Vector2(260,60),Color("73634b"),1)
	text(Vector2(35,80),game.survival.clock_text(),11,muted)
	var s=game.survival
	world_map(Rect2(w-207,27,176,158),false)
	heading(Vector2(w-302,221),"A Foothold in the Vale",21)
	draw_line(Vector2(w-302,231),Vector2(w-28,231),Color("665740"),1)
	var lines=s.objective_lines()
	for i in range(lines.size()): text(Vector2(w-300,258+i*24),lines[i],14,cream if i==0 else muted)
	text(Vector2(w-300,350),"M  Map   TAB  Pack   C  Craft",12,gold)
	panel(Rect2(26,h-147,210,111))
	stat_bar(Vector2(40,h-122),"FOOD",s.hunger,Color("a29454"))
	stat_bar(Vector2(40,h-90),"WATER",s.thirst,Color("689da7"))
	stat_bar(Vector2(40,h-58),"STAMINA",s.stamina,Color("94a976"))
	# Carved iron action bar, blood-red vitality globe and engraved skill slots.
	panel(Rect2(w/2-310,h-124,620,90))
	var orb=Vector2(w/2-231,h-96)
	for r in [54,50,47]: draw_circle(orb,r,Color("292522") if r!=50 else gold)
	draw_circle(orb,43,Color("180b0b"))
	var blood=PackedVector2Array()
	for i in range(65):
		var a=i*TAU/64
		blood.append(orb+Vector2(cos(a)*41,maxf(sin(a)*41,41-game.player.hp*.82)))
	draw_colored_polygon(blood,Color("7e1d1b"))
	draw_arc(orb,39,.3,2.8,32,Color("b7482b"),2,true)
	draw_arc(orb+Vector2(-8,-9),24,3.3,4.7,18,Color(.8,.42,.3,.25),4,true)
	text(orb+Vector2(-25,7),"%d" % int(game.player.hp),22,cream)
	text(orb+Vector2(-22,65),"VITALITY",10,muted)
	var keys=["J","K","SPACE","R"]
	for i in range(4):
		var rect=Rect2(w/2-146+i*72,h-110,62,58)
		panel(rect)
		var selected=(i==game.player.weapon and i<2)
		if selected: draw_rect(rect.grow(-2),Color("ac8551"),false,1)
		skill_icon(rect.get_center()+Vector2(0,-5),i,cream if selected else Color("8c8375"))
		text(rect.position+Vector2(9,52),keys[i],10,gold)
		var cd=game.player.cooldown/(.42 if i==0 else .58) if i<2 else game.player.dodge_cd/.9 if i==2 else 0.0
		if cd>0: draw_rect(Rect2(rect.position,Vector2(rect.size.x,rect.size.y*minf(cd,1))),Color(0,0,0,.55))
	text(Vector2(w/2+159,h-93),"%d" % game.player.gold,20,gold)
	text(Vector2(w/2+159,h-74),"SILVER",10,muted)
	text(Vector2(w/2+159,h-48),"%d heal / %d arrows" % [game.player.potions+game.survival.inventory.bandage,game.survival.inventory.arrows],12,muted)
	centered("WASD Move   SHIFT Sprint   E Use   C Craft   B Build   F Eat   G Drink   TAB Pack   M Map   F5 Save",h-13,12,muted)
	if game.message_time>0 and not game.dialogue_open:
		centered(game.message,h-167,16,cream)
	if game.prompt!="" and not game.dialogue_open:
		var tw=font.get_string_size(game.prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
		panel(Rect2((w-tw)/2-15,h-238,tw+30,37))
		centered(game.prompt,h-214,17,Color("d9bd84"))
	if game.dialogue_open:
		panel(Rect2(w/2-395,h-360,790,204))
		heading(Vector2(w/2-364,h-323),game.dialogue_title,27)
		draw_line(Vector2(w/2-365,h-310),Vector2(w/2+365,h-310),Color("5b4e3a"),1)
		var speech_lines=game.dialogue_text.split("\n")
		for i in range(speech_lines.size()): text(Vector2(w/2-365,h-280+i*27),speech_lines[i],17,cream)
		text(Vector2(w/2-365,h-178),game.dialogue_action,14,gold)
	if game.flash>0: draw_rect(Rect2(Vector2.ZERO,size),Color(.6,.09,.04,game.flash*.5))
	if s.menu!="": draw_survival_menu()
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,.7))
		panel(Rect2(w/2-245,h/2-120,490,240))
		heading(Vector2(w/2-90,h/2-63),"HOLLOWMERE",27)
		centered("ESC  Resume",h/2-12,18,cream)
		centered("J / K  Quick attack     Q + click  Manual aim",h/2+23,15,muted)
		centered("Space  Dodge     R  Healing tonic",h/2+53,15,muted)
		centered("The Last Lantern",h/2+92,13,gold)

func stat_bar(pos: Vector2, name: String, value: float, color: Color) -> void:
	text(pos,name,10,muted)
	draw_rect(Rect2(pos+Vector2(70,-9),Vector2(104,7)),Color("292822"))
	draw_rect(Rect2(pos+Vector2(70,-9),Vector2(104*value/100,7)),color)
	text(pos+Vector2(177,0),str(int(value)),10,cream)

func world_map(rect: Rect2, full: bool) -> void:
	panel(rect)
	var inner=rect.grow(-15)
	var s=game.survival
	var transform_point=func(p: Vector2) -> Vector2: return inner.position+Vector2((p.x+90)/180,(p.y+102)/192)*inner.size
	for route in [[Vector2(-55,10),Vector2(65,10)],[Vector2(-40,-47),Vector2(-40,55)],[Vector2(47,-54),Vector2(47,60)],[Vector2(-40,55),Vector2(47,55)],[Vector2(-40,-47),Vector2(47,-47)],[Vector2(0,13),Vector2(0,-90)]]:
		draw_line(transform_point.call(route[0]),transform_point.call(route[1]),Color("605b4a"),2 if full else 1)
	for poi in s.pois:
		var p=transform_point.call(poi.pos)
		var found=poi.name in s.discovered
		draw_circle(p,4 if full else 2,gold if found else Color("625e54"))
		if full:
			text(p+Vector2(7,-6),poi.name,14,cream if found else muted)
			text(p+Vector2(7,10),poi.detail,10,muted)
	for entry in s.placed:
		draw_circle(transform_point.call(Vector2(entry.pos[0],entry.pos[2])),3,Color("e6b86b"))
	var player_point=transform_point.call(Vector2(game.player.position.x,game.player.position.z))
	draw_circle(player_point,4,Color("d0ebdd"))
	text(rect.position+Vector2(10,14),"N ↑  THE HOLLOW VALE" if full else "M  ·  VALLEY MAP",10,gold)

func draw_survival_menu() -> void:
	var s=game.survival
	var w=size.x
	var h=size.y
	draw_rect(Rect2(Vector2.ZERO,size),Color(0,0,0,.65))
	if s.menu=="map":
		world_map(Rect2(w/2-370,45,740,h-105),true)
		centered("Charted landmarks are dim until explored.  M / ESC to close.",h-32,14,cream)
		return
	var left=w/2-400
	var top=h/2-240
	panel(Rect2(left,top,800,480))
	heading(Vector2(left+26,top+38),"CRAFTING" if s.menu=="craft" else "SURVIVOR'S PACK",27)
	text(Vector2(left+26,top+65),"Choose a numbered recipe. Materials are consumed only when crafting succeeds." if s.menu=="craft" else "F eat  ·  G drink  ·  R heal  ·  B place a crafted campfire or bedroll",14,muted)
	if s.menu=="craft":
		for i in range(s.recipes.size()):
			var r=s.recipes[i]
			var y=top+110+i*48
			var ready=s.can_pay(r.cost)
			text(Vector2(left+26,y),str(i+1)+"   "+r.name,19,cream if ready else muted)
			text(Vector2(left+285,y),s.cost_text(r.cost),15,gold if ready else muted)
			if r.need!="": text(Vector2(left+590,y),"At campfire" if r.need=="fire" else "Claimed workbench",12,muted)
	else:
		var i=0
		for item in s.inventory:
			var col=i/7
			var row=i%7
			var x=left+28+col*375
			var y=top+111+row*35
			text(Vector2(x,y),item.replace("_"," ").capitalize(),17,cream)
			text(Vector2(x+240,y),str(s.inventory[item]),18,gold)
			i+=1
		text(Vector2(left+26,top+386),"Sword: "+("tempered" if s.upgraded else "iron")+"    Shelter: "+("claimed" if s.outpost_claimed else "unclaimed"),15,gold)
	if game.message_time>0: text(Vector2(left+26,top+414),game.message,13,gold)
	text(Vector2(left+26,top+445),"C craft  ·  TAB pack  ·  ESC close  ·  F5 save while exploring",13,muted)
