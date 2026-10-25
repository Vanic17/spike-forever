extends RefCounted
## Only 3D image assets participate. UI, identity prints and simulation stay intact.
static var max_size:=0
static var records: Array[Dictionary]=[]
static func prepare(image: Image) -> Image:
	if max_size>0 and maxi(image.get_width(),image.get_height())>max_size:
		var factor: float=float(max_size)/maxi(image.get_width(),image.get_height())
		image.resize(maxi(1,roundi(image.get_width()*factor)),maxi(1,roundi(image.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
	image.generate_mipmaps()
	return image
static func create(image: Image,path: String,region: Rect2i=Rect2i()) -> ImageTexture:
	var texture:=ImageTexture.create_from_image(prepare(image))
	records.append({"texture":weakref(texture),"path":path,"region":region,"limit":max_size})
	return texture
static func apply(limit: int) -> void:
	max_size=limit
	var live: Array[Dictionary]=[]
	for record in records:
		var texture=record.texture.get_ref()
		if texture==null: continue
		live.append(record)
		if record.limit==limit: continue
		var image:=Image.load_from_file(record.path)
		if image==null: continue
		if record.region.has_area(): image=image.get_region(record.region)
		texture.set_image(prepare(image)); record.limit=limit
	records=live
