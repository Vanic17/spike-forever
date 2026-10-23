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
	var expanded := Expansion.attacking(direction,quality,serial)
	if not expanded.is_empty(): return expanded
	if quality < 0.66: return "attack_turn"
	match direction:
		0: return "attack_pin_left" if serial % 2 == 0 else "attack_angle_left"
		2: return "attack_pin_right" if serial % 2 == 0 else "attack_angle_right"
		_: return "attack_angle_left" if serial % 2 == 0 else "attack_line"

static func fast_setting(back: bool, speed: float, quality: float, serial: int, normal_variant: String = "") -> String:
	var paired := Expansion.paired_quick(normal_variant)
	if not paired.is_empty(): return paired
	var expanded := Expansion.setting(back,speed,quality,serial,true)
	return expanded if not expanded.is_empty() else ("fast_set_back" if back else "fast_set")

static func blocking(local_velocity: Vector3, index: int, serial: int) -> String:
	return Expansion.blocking(local_velocity,index,serial)

static func diving(local: Vector3, incoming: String, serial: int) -> String:
	return Expansion.diving(local,incoming,serial)
