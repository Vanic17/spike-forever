extends RefCounted
## Eighteen curved panels in object space: the pattern and markings rotate
## with the actual simulated quaternion, including topspin and replay poses.
static func material() -> ShaderMaterial:
	var result:=ShaderMaterial.new()
	result.shader=load("res://src/volleyball_v200.gdshader")
	var image:=Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/art/ball68/mark.svg"),2.0)
	image.generate_mipmaps()
	result.set_shader_parameter("markings",ImageTexture.create_from_image(image))
	return result
