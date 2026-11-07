extends RefCounted
## Render scale and contact conversions share one source of truth. Actor roots,
## court movement, rotation order and animation clocks remain unscaled.
const MODEL_CM:=189.4563
static var catalog: Dictionary={}
static func centimetres(person: Dictionary) -> float:
	if catalog.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gameplay/player_heights90.json"))
		if data is Dictionary:catalog=data
	var id: String=str(person.get("database_id",person.get("id","")))
	if "|" in id:id=id.get_slice("|",1)
	var value=person.get("height_cm",catalog.get(id,MODEL_CM))
	return clampf(float(value),150,230) if (value is float or value is int) and is_finite(float(value)) else MODEL_CM
static func prepare(actor) -> void:
	if actor.stature_pivot90!=null:return
	actor.stature_pivot90=Node3D.new();actor.stature_pivot90.name="Stature90"
	actor.add_child(actor.stature_pivot90)
	actor.visual_root.reparent(actor.stature_pivot90,false)
static func apply(actor,person: Dictionary) -> void:
	if actor.stature_pivot90==null or not actor.body_parts.has("head"):return
	var factor: float=centimetres(person)/MODEL_CM
	if is_equal_approx(actor.height_scale90,factor):return
	actor.height_scale90=factor;actor.stature_pivot90.scale=Vector3.ONE*factor
	actor.foot_planted=[false,false];actor.foot_weights=[0.0,0.0]
