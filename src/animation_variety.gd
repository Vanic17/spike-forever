extends RefCounted
## Additional, distinct source performances. Selection is visual only: the
## existing actor, ball deadline, contact IK and court movement remain owners.
const Expansion = preload("res://src/animation_expansion.gd")
const SOURCES := {
	"receive_low": "PASS/PASS_2H_FrontDown_Distance0_FromHalfSquat_NoRecoil.psa",
	"receive_squat": "PASS/PASS_2H_FrontCenter_Distance0_FromSquat_NoRecoil.psa",
	"receive_step": "PASS/PASS_2H_FrontCenter_Distance1_FromHalfSquat_NoRecoil.psa",
	"receive_left_step": "PASS/PASS_2H_LeftCenter_Distance1_FromHalfSquat_NoRecoil.psa",
	"receive_right_step": "PASS/PASS_2H_RightCenter_Distance1_FromHalfSquat_NoRecoil.psa",
	"set_short_front": "SET/SET_Jumped_R_Short_Front_slow.psa",
	"set_short_back": "SET/SET_Jumped_R_Short_Back_slow.psa",
	"set_left_front": "SET/SET_Jumped_L_Long_Front_slow.psa",
	"set_left_back": "SET/SET_Jumped_L_Long_Back_slow.psa",
	"set_running_front": "SET/SET_RunJump_LRL_FrontRight_Long_Front_slow.psa",
	"attack_angle_left": "SPIKE/SPK_Line_45L_After_RunLRL.psa",
	"attack_angle_right": "SPIKE/SPK_Line_45R_After_RunLRL.psa",
	"attack_turn": "SPIKE/SPK_Line_90R_After_RunLRL.psa",
	"attack_pin_left": "SPIKE/SPK_OutsideLeft_After_RunLRL_45L.psa",
	"attack_pin_right": "SPIKE/SPK_OutsideRight_After_RunLRL_45R.psa"
}
const CLIPS := ["receive_low", "receive_squat", "receive_step", "receive_left_step", "receive_right_step", "set_short_front", "set_short_back", "set_left_front", "set_left_back", "set_running_front", "attack_angle_left", "attack_angle_right", "attack_turn", "attack_pin_left", "attack_pin_right"]

static func receive(local: Vector3, speed: float, incoming: String, serial: int) -> String:
	if incoming=="serve" and local.y<1.75:
		# Use the same stable native platform/footwork family for pressured
		# service passes too, rather than repeating the upright source pass.
		var slot:=posmod(serial,7)
		if absf(local.x)>.55:return "receive_left_step" if local.x>0 else "receive_right_step"
		if slot==1:return "receive_braced80"
		if slot==2:return "receive_platform80"
		if slot==3 and local.y<1.4:return "receive_knee80" if local.x>=0 else "receive_knee_right80"
		if slot==4:return "receive_step" if speed>1.3 else "receive_front75"
	if incoming in ["spike","soft","block","tip","net","shank"] and local.y<1.75:
		var slot:=posmod(serial,12)
		var left:=local.x>.15 or (absf(local.x)<=.15 and posmod(serial/12,2)==0)
		if slot in [1,2,3]:return "receive_platform80"
		if slot in [4,5]:return "receive_braced80"
		if slot in [6,7,8]:return "receive_knee80" if left else "receive_knee_right80"
		if slot in [9,10]:return ("receive_low76" if left else "receive_low_right76") if absf(local.x)>.35 else "receive_platform80"
		if slot==11:return "receive_slide77" if left else "receive_slide_right77"
	# Low lateral hard-driven balls use the folded-knee support, never a
	# generic forward dive or an upright reception in the opposite direction.
	if incoming in ["spike","soft","block"] and local.x>.35 and local.y<1.45 and posmod(serial,3)==0: return "receive_low76"
	if incoming in ["spike","soft","block"] and local.x<-.35 and local.y<1.45 and posmod(serial,3)==0: return "receive_low_right76"
	# Choose a compatible support, never a random fall. The final platform
	# preparation is authored from the short reference; old variants remain.
	if incoming in ["spike","soft","block"] and posmod(serial,3)!=2:
		if local.x>.65: return "receive_left75"
		if local.x<-.65: return "receive_right75"
		if local.y<1.55: return "receive_front75"
	var expanded := Expansion.receiving(local,speed,incoming,serial)
	if not expanded.is_empty(): return expanded
	# The root's lateral reach chooses the actual stepping performance. A low
	# hard-driven dig and a deep ready squat have their own support mechanics.
	if local.x > 0.65: return "receive_left_step"
	if local.x < -0.65: return "receive_right_step"
	if incoming == "spike" and (local.z > 0.35 or serial % 2 == 0): return "receive_low"
	if Vector2(local.x, local.z).length() > 1.0 or speed > 1.5: return "receive_step"
	if serial % 3 == 0: return "receive_squat"
	return "receive_follow" if serial % 3 == 1 else "receive"

static func setting(back: bool, speed: float, quality: float, serial: int) -> String:
	var expanded := Expansion.setting(back,speed,quality,serial)
	if not expanded.is_empty(): return expanded
	if quality < 0.72: return "set_short_back" if back else "set_short_front"
	if not back and speed > 1.8: return "set_running_front"
	if serial % 2 == 0: return "set_left_back" if back else "set_left_front"
	return "set_back" if back else "set"

static func attack(direction: int, quality: float, serial: int) -> String:
	if quality < 0.66: return "attack_turn"
	match direction:
		0: return ["attack_v26_02","attack_pin_left","attack_angle_left"][posmod(serial,3)]
		2: return ["attack_v26_03","attack_pin_right","attack_angle_right"][posmod(serial,3)]
		_: return ["attack_v26_01","attack_line","attack_angle_left"][posmod(serial,3)]

static func fast_setting(back: bool, speed: float, quality: float, serial: int, normal_variant: String = "") -> String:
	var paired := Expansion.paired_quick(normal_variant)
	if not paired.is_empty(): return paired
	var expanded := Expansion.setting(back,speed,quality,serial,true)
	return expanded if not expanded.is_empty() else ("fast_set_back" if back else "fast_set")

static func blocking(local_velocity: Vector3, index: int, serial: int) -> String:
	return Expansion.blocking(local_velocity,index,serial)

static func diving(local: Vector3, incoming: String, serial: int) -> String:
	if incoming!="serve":
		if incoming=="spike" and local.z>.15 and absf(local.x)<.65 and posmod(serial,16)==0:return "dive_hand75"
		if absf(local.x)>.55:return "dive_slide77" if local.x>0 else "dive_slide_right77"
		return "dive_platform80"
	if incoming in ["spike","soft","block"] and absf(local.x)>.55 and posmod(serial,5)==1:
		return "dive_slide77" if local.x>0 else "dive_slide_right77"
	if incoming=="spike" and local.z>.15 and absf(local.x)<.65 and posmod(serial,3)==0: return "dive_hand75"
	return Expansion.diving(local,incoming,serial)
