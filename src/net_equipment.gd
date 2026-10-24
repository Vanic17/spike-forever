extends Node3D
## Visual equipment only; ball and player collision remain owned by the match.
const Assets=preload("res://src/source_assets.gd")
var posts: Array[Node3D]=[]
var stand: Node3D
var official: Node3D
func material(color: String) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(color); m.roughness=.73; return m
func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> void:
	var node:=MeshInstance3D.new(); var shape:=BoxMesh.new(); shape.size=size
	node.mesh=shape; node.position=at; node.material_override=mat; parent.add_child(node)
func rod(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var node:=MeshInstance3D.new(); var shape:=CylinderMesh.new()
	shape.top_radius=radius; shape.bottom_radius=radius; shape.height=from.distance_to(to); shape.radial_segments=12
	node.mesh=shape; node.position=(from+to)*.5; node.material_override=mat; parent.add_child(node)
	var direction:=(to-from).normalized()
	if absf(direction.dot(Vector3.UP))<.999: node.quaternion=Quaternion(Vector3.UP,direction)
func _ready() -> void:
	name="NetEquipment"
	var green:=material("254c37"); var steel:=material("c8cdd0"); var red:=material("a91f2b")
	var ink:=Image.load_from_file("res://assets/art/sponsors/credem-original.png").get_region(Rect2i(80,982,1160,145))
	ink.generate_mipmaps()
	var print_mat:=StandardMaterial3D.new(); print_mat.albedo_texture=ImageTexture.create_from_image(ink)
	print_mat.roughness=.8; print_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for side in [-1,1]:
		var post:=Node3D.new(); post.name="CredemPostLeft" if side<0 else "CredemPostRight"; post.position.x=side*5.2; add_child(post); posts.append(post)
		rod(post,Vector3(0,.04,0),Vector3(0,2.56,0),.075,steel)
		box(post,Vector3(0,1.19,0),Vector3(.29,2.34,.29),green)
		box(post,Vector3(0,.075,0),Vector3(.36,.12,.36),green)
		for face in 4:
			var angle:=face*PI/2
			var panel:=MeshInstance3D.new(); var quad:=QuadMesh.new(); quad.size=Vector2(2.10,.25)
			panel.mesh=quad; panel.position=Vector3(sin(angle)*.147,1.23,cos(angle)*.147)
			panel.rotation=Vector3(0,angle,PI/2); panel.material_override=print_mat
			post.add_child(panel)
		rod(post,Vector3(-side*.10,2.43,0),Vector3(-side*.62,2.43,0),.017,steel)
		box(self,Vector3(side*4.5,1.93,.008),Vector3(.045,1.0,.016),material("eeeade"))
		for stripe in 8:
			rod(self,Vector3(side*4.5,2.43+stripe*.10,0),Vector3(side*4.5,2.53+stripe*.10,0),.012,red if stripe%2==0 else steel)
	# Left in the default behind-court view (negative court X), outside free play.
	stand=Node3D.new(); stand.name="RefereeStandLeft"; stand.position=Vector3(-6.10,0,0); add_child(stand)
	box(stand,Vector3(0,.05,0),Vector3(1.18,.10,1.50),red)
	box(stand,Vector3(0,.98,0),Vector3(.84,1.88,.76),red)
	box(stand,Vector3(.03,1.98,0),Vector3(.93,.12,1.16),material("242b35"))
	for z in [-.60,.60]:
		rod(stand,Vector3(-.58,.12,z),Vector3(-.58,2.68,z),.025,red)
		rod(stand,Vector3(-.58,2.68,z),Vector3(.40,2.68,z),.025,red)
		rod(stand,Vector3(.40,2.68,z),Vector3(.40,2.05,z),.025,red)
	for rung in 7:
		rod(stand,Vector3(-.60,.21+rung*.28,-.43),Vector3(-.60,.21+rung*.28,.43),.022,steel)
	var badge:=MeshInstance3D.new(); var plate:=QuadMesh.new(); plate.size=Vector2(.65,1.50)
	badge.mesh=plate; badge.position=Vector3(.431,1.15,0); badge.rotation.y=PI/2
	var badge_material:=material("254c37"); badge.material_override=badge_material; stand.add_child(badge)
	var label:=Label3D.new(); label.text="CREDEM\nBANCA"; label.font_size=45; label.pixel_size=.0026; label.modulate=Color("fff04b")
	label.position=Vector3(.44,1.18,0); label.rotation.y=PI/2; label.outline_size=0; stand.add_child(label)
	official=preload("res://src/referee.gd").new(); official.position=Vector3(-6.07,2.045,0); official.rotation.y=PI/2; add_child(official)
