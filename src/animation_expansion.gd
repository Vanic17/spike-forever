extends RefCounted
## Source-backed visual performances; selection never consumes gameplay RNG.
const SOURCES := {
    "attack_v26_01":  "SPIKE/SPK_Line_90L_After_RunLRL.psa",
    "attack_v26_02":  "SPIKE/SPK_OutsideLeft_After_RunLRL_45R.psa",
    "attack_v26_03":  "SPIKE/SPK_OutsideRight_After_RunLRL_45L.psa",
    "backpedal_v26_01":  "MOVE/STD_Move_BackRun_R_S2.psa",
    "backwalk_v26_01":  "MOVE/STD_Move_BackWalk_R_S2.psa",
    "block_ready_v26_01":  "BLOCK/BLK_upArm_HS_idle.psa",
    "block_v26_01":  "BLOCK/BLK_FromStepL_Front.psa",
    "block_v26_02":  "BLOCK/BLK_FromStepR_Front.psa",
    "block_v26_03":  "BLOCK/BLK_Static_45L_midArm_HS.psa",
    "block_v26_05":  "BLOCK/BLK_Static_45R_midArm_HS.psa",
    "block_v26_06":  "BLOCK/BLK_Static_45R_upArm_HS.psa",
    "block_v26_07":  "BLOCK/BLK_Static_Front_upArm_HS.psa",
    "cross_left_v26_01":  "MOVE/STD_Move_Crossing_LOOP_90L_D2.psa",
    "cross_right_v26_01":  "MOVE/STD_Move_Crossing_LOOP_90R_D2.psa",
    "dive_v26_01":  "PASS/PASS_1H_Dig_Front_RHand_FromSquat_V2.psa",
    "dive_v26_02":  "PASS/PASS_1H_Dig_Left_Rhand_FromHalfSquat_V2.psa",
    "dive_v26_03":  "PASS/PASS_1H_Dig_Left_Rhand_FromSquat_V2.psa",
    "dive_v26_04":  "PASS/PASS_1H_Dig_Right_Rhand_FromHalfSquat_V2.psa",
    "dive_v26_05":  "PASS/PASS_1H_Dig_Right_Rhand_FromSquat_V2.psa",
    "dive_v26_06":  "PASS/PASS_2H_Dig_Front_RHand_FromSquat.psa",
    "fast_set_v26_01":  "SET/SET_Jumped_L_Long_Back_quick.psa",
    "fast_set_v26_02":  "SET/SET_Jumped_L_Long_Front_quick.psa",
    "fast_set_v26_03":  "SET/SET_Jumped_L_Short_Back_quick.psa",
    "fast_set_v26_04":  "SET/SET_Jumped_L_Short_Front_quick.psa",
    "fast_set_v26_05":  "SET/SET_Jumped_R_Long_Back_quick.psa",
    "fast_set_v26_06":  "SET/SET_Jumped_R_Long_Front_quick.psa",
    "fast_set_v26_07":  "SET/SET_RunJump_LRL_FrontRight_Long_Back_quick.psa",
    "fast_set_v26_08":  "SET/SET_RunJump_LRL_FrontRight_Long_Front_quick.psa",
    "fast_set_v26_09":  "SET/SET_RunJump_LRL_FrontRight_Short_Back_quick.psa",
    "fast_set_v26_10":  "SET/SET_RunJump_LRL_FrontRight_Short_Front_quick.psa",
    "fast_set_v26_11":  "SET/SET_RunJump_LRL_FrontRight_VeryLong_Front_quick.psa",
    "ready_v26_01":  "WAIT_OPP_SERVE/WS_Idle_HSR_Loop_HSR_02.psa",
    "ready_v26_02":  "WAIT_OPP_SERVE/WS_Idle_HS_Loop_HS_01.psa",
    "ready_v26_03":  "WAIT_OPP_SERVE/WS_Idle_HS_Loop_HS_02.psa",
    "ready_v26_04":  "WAIT_OPP_SERVE/WS_Idle_HS_Loop_HS_04.psa",
    "ready_v26_05":  "WAIT_OPP_SERVE/WS_Idle_S_Loop_S_01.psa",
    "ready_v26_06":  "WAIT_OPP_SERVE/WS_Idle_S_Loop_S_02.psa",
    "ready_v26_07":  "WAIT_OPP_SERVE/WS_Idle_S_Loop_S_03.psa",
    "receive_v26_01":  "PASS/PASS_2H_FrontCenter_Distance0_FromSquat_Recoil.psa",
    "receive_v26_02":  "PASS/PASS_2H_FrontCenter_Distance1_FromSquat_NoRecoil.psa",
    "receive_v26_03":  "PASS/PASS_2H_FrontDown_Distance0_FromHalfSquat_Recoil.psa",
    "receive_v26_04":  "PASS/PASS_2H_FrontDown_Distance0_FromSquat_NoRecoil.psa",
    "receive_v26_05":  "PASS/PASS_2H_FrontDown_Distance0_FromSquat_Recoil.psa",
    "receive_v26_06":  "PASS/PASS_2H_FrontDown_Distance1_FromHalfSquat_NoRecoil.psa",
    "receive_v26_07":  "PASS/PASS_2H_FrontDown_Distance1_FromSquat_NoRecoil.psa",
    "receive_v26_08":  "PASS/PASS_2H_FrontUp_Distance0_FromHalfSquat_NoRecoil.psa",
    "receive_v26_09":  "PASS/PASS_2H_FrontUp_Distance0_FromHalfSquat_Recoil.psa",
    "receive_v26_10":  "PASS/PASS_2H_FrontUp_Distance0_FromSquat_Recoil.psa",
    "receive_v26_11":  "PASS/PASS_2H_FrontUp_Distance1_FromHalfSquat_NoRecoil.psa",
    "receive_v26_12":  "PASS/PASS_2H_FrontUp_Distance1_FromSquat_NoRecoil.psa",
    "receive_v26_13":  "PASS/PASS_2H_LeftCenter_Distance1_FromHalfSquat_Recoil.psa",
    "receive_v26_14":  "PASS/PASS_2H_LeftCenter_Distance1_FromSquat_NoRecoil.psa",
    "receive_v26_15":  "PASS/PASS_2H_LeftCenter_Distance1_FromSquat_Recoil.psa",
    "receive_v26_16":  "PASS/PASS_2H_LeftCenter_Distance1_FromSquat_Run_L.psa",
    "receive_v26_17":  "PASS/PASS_2H_LeftDown_Distance1_FromSquat_Run_L.psa",
    "receive_v26_18":  "PASS/PASS_2H_Reflex_FrontCenter_Distance0_S.psa",
    "receive_v26_19":  "PASS/PASS_2H_RightCenter_Distance1_FromSquat_NoRecoil.psa",
    "receive_v26_20":  "PASS/PASS_2H_leftUp_Distance1_FromHalfSquat_NoRecoil.psa",
    "relaxed_v26_01":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_02.psa",
    "relaxed_v26_02":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_03.psa",
    "relaxed_v26_03":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_04.psa",
    "relaxed_v26_04":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_05.psa",
    "relaxed_v26_05":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_06.psa",
    "relaxed_v26_06":  "WAIT_OPP_SERVE/WS_Idle_U_Loop_U_07.psa",
    "run_v26_01":  "MOVE/STD_Move_Run_L_S1.psa",
    "run_v26_02":  "MOVE/STD_Move_Run_L_S3.psa",
    "run_v26_03":  "MOVE/STD_Move_Run_R_S1.psa",
    "run_v26_04":  "MOVE/STD_Move_Run_R_S3.psa",
    "set_v26_01":  "SET/SET_Jumped_L_Short_Back_slow.psa",
    "set_v26_02":  "SET/SET_Jumped_L_Short_Front_slow.psa",
    "set_v26_03":  "SET/SET_RunJump_LRL_FrontRight_Long_Back_slow.psa",
    "set_v26_04":  "SET/SET_RunJump_LRL_FrontRight_Short_Back_slow.psa",
    "set_v26_05":  "SET/SET_RunJump_LRL_FrontRight_Short_Front_slow.psa",
    "set_v26_06":  "SET/SET_RunJump_LRL_FrontRight_VeryLong_Front_slow.psa",
    "shuffle_left_v26_01":  "MOVE/STD_Move_Sidesteps_L_D2.psa",
    "shuffle_right_v26_01":  "MOVE/STD_Move_Sidesteps_R_D2.psa",
    "walk_v26_01":  "MOVE/STD_Move_Walk_R_S2.psa",
    "wall_shuffle_left":  "BLOCK/BLK_Step_Left_Loop_D0_upArm.psa",
    "wall_shuffle_right":  "BLOCK/BLK_Step_Right_Loop_D0_upArm.psa"
}
const FAMILIES := {
    "attack_v26_01":  "attack",
    "attack_v26_02":  "attack",
    "attack_v26_03":  "attack",
    "backpedal_v26_01":  "backpedal",
    "backwalk_v26_01":  "backwalk",
    "block_ready_v26_01":  "block_ready",
    "block_v26_01":  "block",
    "block_v26_02":  "block",
    "block_v26_03":  "block",
    "block_v26_05":  "block",
    "block_v26_06":  "block",
    "block_v26_07":  "block",
    "cross_left_v26_01":  "cross_left",
    "cross_right_v26_01":  "cross_right",
    "dive_v26_01":  "dive",
    "dive_v26_02":  "dive",
    "dive_v26_03":  "dive",
    "dive_v26_04":  "dive",
    "dive_v26_05":  "dive",
    "dive_v26_06":  "dive",
    "fast_set_v26_01":  "fast_set",
    "fast_set_v26_02":  "fast_set",
    "fast_set_v26_03":  "fast_set",
    "fast_set_v26_04":  "fast_set",
    "fast_set_v26_05":  "fast_set",
    "fast_set_v26_06":  "fast_set",
    "fast_set_v26_07":  "fast_set",
    "fast_set_v26_08":  "fast_set",
    "fast_set_v26_09":  "fast_set",
    "fast_set_v26_10":  "fast_set",
    "fast_set_v26_11":  "fast_set",
    "ready_v26_01":  "ready",
    "ready_v26_02":  "ready",
    "ready_v26_03":  "ready",
    "ready_v26_04":  "ready",
    "ready_v26_05":  "ready",
    "ready_v26_06":  "ready",
    "ready_v26_07":  "ready",
    "receive_v26_01":  "receive",
    "receive_v26_02":  "receive",
    "receive_v26_03":  "receive",
    "receive_v26_04":  "receive",
    "receive_v26_05":  "receive",
    "receive_v26_06":  "receive",
    "receive_v26_07":  "receive",
    "receive_v26_08":  "receive",
    "receive_v26_09":  "receive",
    "receive_v26_10":  "receive",
    "receive_v26_11":  "receive",
    "receive_v26_12":  "receive",
    "receive_v26_13":  "receive",
    "receive_v26_14":  "receive",
    "receive_v26_15":  "receive",
    "receive_v26_16":  "receive",
    "receive_v26_17":  "receive",
    "receive_v26_18":  "receive",
    "receive_v26_19":  "receive",
    "receive_v26_20":  "receive",
    "relaxed_v26_01":  "relaxed",
    "relaxed_v26_02":  "relaxed",
    "relaxed_v26_03":  "relaxed",
    "relaxed_v26_04":  "relaxed",
    "relaxed_v26_05":  "relaxed",
    "relaxed_v26_06":  "relaxed",
    "run_v26_01":  "run",
    "run_v26_02":  "run",
    "run_v26_03":  "run",
    "run_v26_04":  "run",
    "set_v26_01":  "set",
    "set_v26_02":  "set",
    "set_v26_03":  "set",
    "set_v26_04":  "set",
    "set_v26_05":  "set",
    "set_v26_06":  "set",
    "shuffle_left_v26_01":  "shuffle_left",
    "shuffle_right_v26_01":  "shuffle_right",
    "walk_v26_01":  "walk",
    "wall_shuffle_left":  "shuffle_left",
    "wall_shuffle_right":  "shuffle_right"
}
const GROUPS := {
    "attack":  [
                   "attack_v26_01",
                   "attack_v26_02",
                   "attack_v26_03"
               ],
    "backpedal":  [
                      "backpedal_v26_01"
                  ],
    "backwalk":  [
                     "backwalk_v26_01"
                 ],
    "block_ready":  [
                        "block_ready_v26_01"
                    ],
    "block":  [
                  "block_v26_01",
                  "block_v26_02",
                  "block_v26_03",
                  "block_v26_05",
                  "block_v26_06",
                  "block_v26_07"
              ],
    "cross_left":  [
                       "cross_left_v26_01"
                   ],
    "cross_right":  [
                        "cross_right_v26_01"
                    ],
    "dive":  [
                 "dive_v26_01",
                 "dive_v26_02",
                 "dive_v26_03",
                 "dive_v26_04",
                 "dive_v26_05",
                 "dive_v26_06"
             ],
    "fast_set":  [
                     "fast_set_v26_01",
                     "fast_set_v26_02",
                     "fast_set_v26_03",
                     "fast_set_v26_04",
                     "fast_set_v26_05",
                     "fast_set_v26_06",
                     "fast_set_v26_07",
                     "fast_set_v26_08",
                     "fast_set_v26_09",
                     "fast_set_v26_10",
                     "fast_set_v26_11"
                 ],
    "ready":  [
                  "ready_v26_01",
                  "ready_v26_02",
                  "ready_v26_03",
                  "ready_v26_04",
                  "ready_v26_05",
                  "ready_v26_06",
                  "ready_v26_07"
              ],
    "receive":  [
                    "receive_v26_01",
                    "receive_v26_02",
                    "receive_v26_03",
                    "receive_v26_04",
                    "receive_v26_05",
                    "receive_v26_06",
                    "receive_v26_07",
                    "receive_v26_08",
                    "receive_v26_09",
                    "receive_v26_10",
                    "receive_v26_11",
                    "receive_v26_12",
                    "receive_v26_13",
                    "receive_v26_14",
                    "receive_v26_15",
                    "receive_v26_16",
                    "receive_v26_17",
                    "receive_v26_18",
                    "receive_v26_19",
                    "receive_v26_20"
                ],
    "relaxed":  [
                    "relaxed_v26_01",
                    "relaxed_v26_02",
                    "relaxed_v26_03",
                    "relaxed_v26_04",
                    "relaxed_v26_05",
                    "relaxed_v26_06"
                ],
    "run":  [
                "run_v26_01",
                "run_v26_02",
                "run_v26_03",
                "run_v26_04"
            ],
    "set":  [
                "set_v26_01",
                "set_v26_02",
                "set_v26_03",
                "set_v26_04",
                "set_v26_05",
                "set_v26_06"
            ],
    "shuffle_left":  [
                         "shuffle_left_v26_01",
                         "wall_shuffle_left"
                     ],
    "shuffle_right":  [
                          "shuffle_right_v26_01",
                          "wall_shuffle_right"
                      ],
    "walk":  [
                 "walk_v26_01"
             ]
}
const CLIPS := [
    "attack_v26_01",
    "attack_v26_02",
    "attack_v26_03",
    "backpedal_v26_01",
    "backwalk_v26_01",
    "block_ready_v26_01",
    "block_v26_01",
    "block_v26_02",
    "block_v26_03",
    "block_v26_05",
    "block_v26_06",
    "block_v26_07",
    "cross_left_v26_01",
    "cross_right_v26_01",
    "dive_v26_01",
    "dive_v26_02",
    "dive_v26_03",
    "dive_v26_04",
    "dive_v26_05",
    "dive_v26_06",
    "fast_set_v26_01",
    "fast_set_v26_02",
    "fast_set_v26_03",
    "fast_set_v26_04",
    "fast_set_v26_05",
    "fast_set_v26_06",
    "fast_set_v26_07",
    "fast_set_v26_08",
    "fast_set_v26_09",
    "fast_set_v26_10",
    "fast_set_v26_11",
    "ready_v26_01",
    "ready_v26_02",
    "ready_v26_03",
    "ready_v26_04",
    "ready_v26_05",
    "ready_v26_06",
    "ready_v26_07",
    "receive_v26_01",
    "receive_v26_02",
    "receive_v26_03",
    "receive_v26_04",
    "receive_v26_05",
    "receive_v26_06",
    "receive_v26_07",
    "receive_v26_08",
    "receive_v26_09",
    "receive_v26_10",
    "receive_v26_11",
    "receive_v26_12",
    "receive_v26_13",
    "receive_v26_14",
    "receive_v26_15",
    "receive_v26_16",
    "receive_v26_17",
    "receive_v26_18",
    "receive_v26_19",
    "receive_v26_20",
    "relaxed_v26_01",
    "relaxed_v26_02",
    "relaxed_v26_03",
    "relaxed_v26_04",
    "relaxed_v26_05",
    "relaxed_v26_06",
    "run_v26_01",
    "run_v26_02",
    "run_v26_03",
    "run_v26_04",
    "set_v26_01",
    "set_v26_02",
    "set_v26_03",
    "set_v26_04",
    "set_v26_05",
    "set_v26_06",
    "shuffle_left_v26_01",
    "shuffle_right_v26_01",
    "walk_v26_01",
    "wall_shuffle_left",
    "wall_shuffle_right"
]

static func pick(pool: Array, serial: int, fallback: String = "") -> String:
	return str(pool[posmod(serial, pool.size())]) if not pool.is_empty() else fallback

static func receiving(local: Vector3, speed: float, incoming: String, serial: int) -> String:
	if posmod(serial,5)<2: return ""
	var pool: Array=[]
	for name in GROUPS.receive:
		var source: String=SOURCES[name].to_lower()
		if local.x>0.65:
			if "left" in source: pool.append(name)
		elif local.x < -0.65:
			if "right" in source: pool.append(name)
		elif "front" in source:
			if incoming=="spike" and ("down" in source or "reflex" in source): pool.append(name)
			elif incoming!="spike" and not "down" in source: pool.append(name)
	return pick(pool,serial/5)

static func setting(back: bool, speed: float, quality: float, serial: int, quick: bool = false) -> String:
	if posmod(serial,5)<2 or (quality<0.72 and not quick): return ""
	var pool: Array=[]
	for name in GROUPS.fast_set if quick else GROUPS.set:
		var source: String=SOURCES[name]
		if ("_Back_" in source)!=back: continue
		if ("RunJump" in source)!=(speed>1.8): continue
		if quality<0.72 and not "_Short_" in source: continue
		if quality>=0.72 and "_Short_" in source and quick: continue
		pool.append(name)
	return pick(pool,serial/5)

static func attacking(direction: int, quality: float, serial: int) -> String:
	if posmod(serial,5)<2: return ""
	if quality<0.66 or direction in [1,3]: return "attack_v26_01"
	return "attack_v26_02" if direction==0 else "attack_v26_03"

static func blocking(local_velocity: Vector3, index: int, serial: int) -> String:
	if local_velocity.x>0.8: return "block_v26_01"
	if local_velocity.x < -0.8: return "block_v26_02"
	return pick(["block","block_v26_03","block_v26_05","block_v26_06","block_v26_07"],index+serial)

static func diving(local: Vector3, incoming: String, serial: int) -> String:
	if posmod(serial,4)==0: return "dive_short" if incoming in ["soft","tip","net"] else "dive"
	if local.x>0.55: return pick(["dive_v26_02","dive_v26_03"],serial/4)
	if local.x < -0.55: return pick(["dive_v26_04","dive_v26_05"],serial/4)
	return pick(["dive_v26_01","dive_v26_06","dive_short","dive"],serial/4)

static func stance_or_gait(action: String, team: int, jersey: int) -> String:
	var index: int=team*6+jersey-1
	if action=="idle": return "ready_v26_01" if index%2==1 else "idle"
	var pool: Array=[action]
	if action=="run": pool.append("run_right")
	for name in GROUPS.get(action,[]):
		if not str(name).begins_with("wall_") and name!="walk_v26_01": pool.append(name)
	return pick(pool,index)

static func paired_quick(normal: String) -> String:
	var fixed := {"set":"fast_set_v26_06","set_back":"fast_set_v26_05","set_left_front":"fast_set_v26_02","set_left_back":"fast_set_v26_01","set_short_front":"fast_set","set_short_back":"fast_set_back","set_running_front":"fast_set_v26_08"}
	if fixed.has(normal): return fixed[normal]
	if not SOURCES.has(normal): return ""
	var wanted: String=SOURCES[normal].replace("_slow.psa","_quick.psa")
	for name in GROUPS.fast_set:
		if SOURCES[name]==wanted: return name
	return ""
