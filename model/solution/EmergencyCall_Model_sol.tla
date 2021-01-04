------------------------------ MODULE EmergencyCall_Model_sol ------------------------------
EXTENDS Naturals, Sequences, FiniteSets, TLC

VARIABLES

 (* sets *)
 ue_emergency_number_set, (* initialized, don't care in init *)
 ue_emergency_number_set_init,
\* ue_sim_emergency_number_set,  (* ue_sim_emergency_number_set should always be equal to amf_home_emergency_number_set *)
 amf_home0_emergency_number_set, (* probably bad, initialized, not modified *)
 amf_home1_emergency_number_set, (* probably good *)
 amf_roam0_emergency_number_set, (* probably bad, initialized, not modified *)
 amf_roam1_emergency_number_set, (* probably good *)
 amf_emergency_number_set, (* initialized *)
 ecc_localization_enabled_mnc_set, (* initialized *)

 (* messages *)
 ue_attach_request_message, (* don't care in init *)
 ue_detach_request_message, (* don't care in init *)
 amf_attach_accept_message, (* don't care in init *)
 ue_emergency_setup_message, (* don't care in init *)
 amf_call_connect_message, (* don't care in init *)
 amf_call_failure_message, (* don't care in init *)

 (* actions *)
 ue_dial_emergency, (* don't care in init *)
 user_dial_number, (* don't care in init *)
 user_make_call, (* don't care in init *)

 (* states *)
 pc_UE, (* don't care in init *)
 pc_AMF, (* don't care in init *)
 ue_current_mnc, (* don't care in init *)
 routed_psap, (* don't care in init *)
 enable_adversary, (* could be fixed in init *)
 ecc_localization_enabled, (* could be fixed in init *)
 ue_valid_subscription, (* could be fixed in init *)
 screen_locked, (* could be fixed in init *)

 (* environment space options *)
 ue_sim_card_present, (* environment, initialized *)
 mnc_home_only, (* environment, initialized *)
 mnc_set, (* environment, initialized *)
 amf_allow_emergency_attach, (* environment, initialized *)
 amf_allow_emergency_setup, (* environment, initialized *)

 (* design space options *)
 amf_0_normal_attach_accept_include_enl, (* environment, initialized *)
 amf_1_normal_attach_accept_include_enl, (* environment, initialized *)
 amf_0_emergency_attach_accept_include_enl, (* environment, initialized *)
 amf_1_emergency_attach_accept_include_enl, (* environment, initialized *)
 amf_home_reject_or_allow_unmarked_emergency_request, (* environment, initialized *)
 amf_roam_reject_or_allow_unmarked_emergency_request, (* environment, initialized *)
 amf_home_route_with_type_or_number, (* environment, initialized *)
 amf_roam_route_with_type_or_number, (* environment, initialized *)
 amf_home_require_emergency_registration_for_emergency_session (* environment, initialized *)
 (* design space options *)
 (* For normal call in roaming, home or roam network decides if the user is dialing an emergency number. *) (* 3GPP 23.167: 7.1.2 *) (* non UE detectible emergency session *)
 (* AS marks a non-emergency session as an emergency session. *) (* 3GPP 23.167: 6.2.8 *) (* non UE detectible emergency session *) (* already considered *) 

-----------------------------------------------------------------------------
(* model constant *)

AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION == 0

UE_FIXED_EMERGENCY_NUMBER_SET == {"911"} (* "112" *)
UE_ME_EMERGENCY_NUMBER_SET == {"110"}
LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET == {"120"}
EMERGENCY_NUMBER_CANDIDATES_SET == UNION {UE_FIXED_EMERGENCY_NUMBER_SET, UE_ME_EMERGENCY_NUMBER_SET, LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET}
ECC_LIST_SET == LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET
NON_EMERGENCY_NUMBER_CANDIDATES_SET == {"224"}
DEFAULT_NUMBER_SET == {"0"}
NUMBER_CANDIDATES_SET == UNION {EMERGENCY_NUMBER_CANDIDATES_SET, NON_EMERGENCY_NUMBER_CANDIDATES_SET, DEFAULT_NUMBER_SET}
SET_OF_NUMBER_CANDIDATES_SET == {{"911"}, {"110"}, {"120"}, {"224"}, {"0"}, {}}

HOME_MNC_CANDIDATES_SET == {"home0", "home1"}
ROAM_MNC_CANDIDATES_SET == {"roam0", "roam1"}
MNC_CANDIDATES_SET == UNION {HOME_MNC_CANDIDATES_SET, ROAM_MNC_CANDIDATES_SET}
EMERGENCY_CATEGORY_SET == {"police"} (* {"police", "ambulance", "fire"} *)
NONE_CATEGORY_SET == {"none"}
CATEGORY_SET == UNION {EMERGENCY_CATEGORY_SET, NONE_CATEGORY_SET}

-----------------------------------------------------------------------------

SetInvariant ==
        /\ ue_emergency_number_set \subseteq NUMBER_CANDIDATES_SET
        /\ ue_emergency_number_set_init \subseteq NUMBER_CANDIDATES_SET
        /\ amf_home0_emergency_number_set \subseteq NUMBER_CANDIDATES_SET (* home 0 could be controlled by the adversary. *)
        /\ amf_home1_emergency_number_set \subseteq EMERGENCY_NUMBER_CANDIDATES_SET (* home 1 is an official network. *)
        /\ amf_roam0_emergency_number_set \subseteq NUMBER_CANDIDATES_SET (* roam 0 could be controlled by the adversary. *)
        /\ amf_roam1_emergency_number_set \subseteq EMERGENCY_NUMBER_CANDIDATES_SET (* roam 1 is an official network. *)
        /\ amf_emergency_number_set \in {amf_home0_emergency_number_set, amf_home1_emergency_number_set, amf_roam0_emergency_number_set, amf_roam1_emergency_number_set}
        /\ ecc_localization_enabled_mnc_set \subseteq {"home1", "roam1"}


TypeInvariant ==
        /\ ue_emergency_number_set \in SUBSET NUMBER_CANDIDATES_SET
        /\ \E number \in (NUMBER_CANDIDATES_SET \ {"0"}): amf_home0_emergency_number_set = {number}
        /\ \E number \in EMERGENCY_NUMBER_CANDIDATES_SET : amf_home1_emergency_number_set = {number}
        /\ \E number \in (NUMBER_CANDIDATES_SET \ {"0"}): amf_roam0_emergency_number_set = {number}
        /\ \E number \in EMERGENCY_NUMBER_CANDIDATES_SET : amf_roam1_emergency_number_set = {number}
        /\ \E code \in {"home1", "roam1"} : ecc_localization_enabled_mnc_set = {code}

        /\ amf_emergency_number_set \in {amf_home0_emergency_number_set, amf_home1_emergency_number_set, amf_roam0_emergency_number_set, amf_roam1_emergency_number_set}

        /\ ue_attach_request_message \in [type: {"normal", "emergency"}]
        /\ ue_detach_request_message \in {0, 1}
        /\ amf_attach_accept_message \in [emergency_number_list: SUBSET NUMBER_CANDIDATES_SET, mnc : MNC_CANDIDATES_SET] (* 3GPP 24.008: 9.4.2, 3GPP 24.008: 10.5.3.13 x100*)
        /\ ue_emergency_setup_message \in [number: (NUMBER_CANDIDATES_SET \ {"0"}), category: CATEGORY_SET] (* 3GPP 24.008: 5.2.1, 3GPP 24.008: 9.3.8  x30*)
        /\ amf_call_connect_message \in {0, 1}
        /\ amf_call_failure_message \in [error_code: {"none", "unmarked_emergency_request", "emergency_registration_required", "non_emergency_request_with_emergency_registration", "normal_call_disallowed_in_emergency_session", "invalid_subscription"}]

        /\ user_make_call \in {0, 1}
        /\ user_dial_number \in NUMBER_CANDIDATES_SET
        /\ pc_UE \in {"ue_emm_deregistered", "ue_emm_registered_initiated", "ue_emm_registered",
         "ue_call_initiated", "ue_refuse_call"} (* 3GPP 24.301: 5.1.3.2, 3GPP 24.008: 5.2.1.1 *)
        /\ pc_AMF \in {"amf_emm_deregistered", "amf_emm_registered", "amf_call_release"} (* 3GPP 24.301: Fig. 5.1.3.4 *)
        /\ ue_current_mnc \in MNC_CANDIDATES_SET (* 3GPP 22.101: 10.4.1 *)
        /\ routed_psap \in CATEGORY_SET
        /\ enable_adversary \in {0, 1}
        /\ ecc_localization_enabled \in {0, 1}
        /\ ue_valid_subscription \in {0, 1}
        /\ screen_locked \in {0, 1}

        /\ ue_sim_card_present \in {0, 1}
        /\ mnc_home_only \in {0, 1}
        /\ mnc_set \subseteq MNC_CANDIDATES_SET
        /\ amf_allow_emergency_attach \in {0, 1}
        /\ amf_allow_emergency_setup \in {0, 1}

        /\ amf_0_normal_attach_accept_include_enl \in {0, 1}
        /\ amf_1_normal_attach_accept_include_enl \in {0, 1}
        /\ amf_0_emergency_attach_accept_include_enl \in {0, 1}
        /\ amf_1_emergency_attach_accept_include_enl \in {0, 1}
        /\ amf_home_reject_or_allow_unmarked_emergency_request \in {0, 1}
        /\ amf_roam_reject_or_allow_unmarked_emergency_request \in {0, 1}
        /\ amf_home_route_with_type_or_number \in {0, 1}
        /\ amf_roam_route_with_type_or_number \in {0, 1}
        /\ amf_home_require_emergency_registration_for_emergency_session \in {0, 1}

-----------------------------------------------------------------------------

(* With the assumption: the ue belongs to HOME1 *)
UE_reboot ==
        /\ ue_emergency_number_set_init = UNION { UE_FIXED_EMERGENCY_NUMBER_SET, UE_ME_EMERGENCY_NUMBER_SET, NON_EMERGENCY_NUMBER_CANDIDATES_SET}
        /\ \/ /\ ue_sim_card_present = 1
              /\ enable_adversary = 1
              /\ ue_emergency_number_set = UNION{UE_FIXED_EMERGENCY_NUMBER_SET, amf_home1_emergency_number_set}  (* 3 *)
           \/ /\ ue_sim_card_present = 1
              /\ enable_adversary = 0
              /\ \E number \in EMERGENCY_NUMBER_CANDIDATES_SET : ue_emergency_number_set = UNION { UE_FIXED_EMERGENCY_NUMBER_SET, {number}}
           \/ /\ ue_sim_card_present = 0
              /\ ue_emergency_number_set = UNION { UE_FIXED_EMERGENCY_NUMBER_SET, UE_ME_EMERGENCY_NUMBER_SET}
        /\ user_make_call = 0
        /\ ue_dial_emergency = 0
        /\ user_dial_number = "0"
        /\ ue_current_mnc = "home1"
        /\ pc_UE = "ue_emm_deregistered"


AMF_Init ==
        /\ \E number \in NON_EMERGENCY_NUMBER_CANDIDATES_SET : amf_home0_emergency_number_set = {number}
        /\ \E number \in EMERGENCY_NUMBER_CANDIDATES_SET : amf_home1_emergency_number_set = {number}
        /\ amf_call_connect_message = 0
        /\ amf_call_failure_message = [error_code |-> "none"]
        /\ \/ /\ mnc_home_only = 0
              /\ mnc_set = MNC_CANDIDATES_SET
           \/ /\ mnc_home_only = 1
              /\ mnc_set = HOME_MNC_CANDIDATES_SET
        /\ pc_AMF = "amf_emm_deregistered"


UE_tentative ==
        /\ ue_attach_request_message = [type |-> "normal"]
        /\ ue_detach_request_message = 0
        /\ ue_emergency_setup_message = [number |-> "911", category |-> "police"]


AMF_tentative ==
        /\ amf_attach_accept_message = [emergency_number_list |-> {"911"}, mnc |-> "home1"]
        /\ amf_call_connect_message = 0
        /\ routed_psap = "none"


Init ==
        /\ AMF_Init
        /\ AMF_tentative
        /\ UE_reboot
        /\ UE_tentative
        /\ TypeInvariant
        /\ SetInvariant


vars == << amf_home_require_emergency_registration_for_emergency_session, amf_attach_accept_message, amf_call_connect_message, amf_call_failure_message, amf_0_emergency_attach_accept_include_enl, amf_1_emergency_attach_accept_include_enl, amf_home0_emergency_number_set, amf_home1_emergency_number_set, amf_roam0_emergency_number_set, amf_roam1_emergency_number_set, amf_emergency_number_set, amf_home_reject_or_allow_unmarked_emergency_request, amf_home_route_with_type_or_number, amf_0_normal_attach_accept_include_enl, amf_1_normal_attach_accept_include_enl, amf_roam_reject_or_allow_unmarked_emergency_request, amf_roam_route_with_type_or_number, pc_AMF, pc_UE, routed_psap, ue_attach_request_message, ue_current_mnc, ue_detach_request_message, ue_dial_emergency, ue_emergency_number_set, ue_emergency_number_set_init, ue_emergency_setup_message, ue_sim_card_present, user_make_call, user_dial_number, mnc_home_only, mnc_set, amf_allow_emergency_attach, amf_allow_emergency_setup, enable_adversary, ecc_localization_enabled, ecc_localization_enabled_mnc_set, ue_valid_subscription, screen_locked >>

-----------------------------------------------------------------------------

USER_make_call == 
        \E num \in (NUMBER_CANDIDATES_SET \ {"0"}) : 
        /\ pc_UE /= "ue_call_initiated"
        /\ user_dial_number' = num
        /\ user_make_call' = 1
        /\ UNCHANGED << vars \ {user_make_call, user_dial_number} >>


UE_send_normal_attach_request ==
        /\ pc_UE = "ue_emm_deregistered"
        /\ ue_sim_card_present = 1
        /\ ue_attach_request_message' =
         [ue_attach_request_message EXCEPT !.type = "normal"]
        /\ pc_UE' = "ue_emm_registered_initiated"
        /\ UNCHANGED << vars \ {ue_attach_request_message, pc_UE} >>


(* 3GPP 23.167: 4.1.7 *)
UE_send_emergency_attach_request ==
        /\ pc_AMF /= "amf_call_release"
        /\  \/  /\ pc_UE /= "ue_emm_registered"
                /\ user_make_call = 1
                /\ user_dial_number \in ue_emergency_number_set
                /\ ue_attach_request_message' =
                    [ue_attach_request_message EXCEPT !.type = "emergency"]
                /\ pc_UE' = "ue_emm_registered_initiated"
                /\ UNCHANGED << vars \ {ue_attach_request_message, pc_UE} >>
            \/  /\ amf_call_failure_message.error_code = "emergency_registration_required"
                /\ user_make_call = 1
                /\ user_dial_number \in ue_emergency_number_set
                /\ ue_attach_request_message' =
                    [ue_attach_request_message EXCEPT !.type = "emergency"]
                /\ pc_UE' = "ue_emm_registered_initiated"
                /\ UNCHANGED << vars \ {ue_attach_request_message, pc_UE} >>


(* 3GPP 23.167: 4.1.7 *)
(* UE detach from normal registration for emergency registration in roaming *)
UE_send_detach_request_for_emergency ==
        /\ pc_UE /= "ue_emm_deregistered"
        /\ user_make_call = 1
        /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
        /\ ue_attach_request_message.type = "normal"
        /\ ue_dial_emergency' = 0
        /\ amf_call_connect_message' = 0
        /\ pc_UE' = "ue_emm_deregistered"
        /\ UNCHANGED << vars \ {ue_dial_emergency, amf_call_connect_message, pc_UE} >>


AMF_send_attach_response == (* Adversary controls AMF. *)
        \E code \in mnc_set:
        /\ pc_AMF = "amf_emm_deregistered"
        /\ pc_UE = "ue_emm_registered_initiated"
        /\ ue_detach_request_message /= 1
        /\  \/  /\ ue_attach_request_message.type = "normal"
                /\  \/  /\ amf_0_normal_attach_accept_include_enl = 1
                        /\ enable_adversary = 1
                        /\  \/ code = "home0"
                            \/ code = "roam0"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = 
                                        CASE code = "home0" -> amf_home0_emergency_number_set
                                        [] code = "roam0" -> amf_roam0_emergency_number_set,
                             !.mnc = code]
                    \/  /\ amf_1_normal_attach_accept_include_enl = 1
                        /\  \/ code = "home1"
                            \/ code = "roam1"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = 
                                        CASE code = "home1" -> amf_home1_emergency_number_set
                                        [] code = "roam1" -> amf_roam1_emergency_number_set,
                             !.mnc = code]    
                    \/  /\  \/  /\ amf_0_normal_attach_accept_include_enl = 0
                                /\ enable_adversary = 1
                                /\  \/ code = "home0"
                                    \/ code = "roam0"
                            \/  /\ amf_1_normal_attach_accept_include_enl = 0
                                /\  \/ code = "home1"
                                    \/ code = "roam1"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = {},
                             !.mnc = code]
            \/  /\ ue_attach_request_message.type = "emergency"
                /\ amf_allow_emergency_attach = 1
                /\  \/  /\ amf_0_emergency_attach_accept_include_enl = 1
                        /\ enable_adversary = 1
                        /\  \/ code = "home0"
                            \/ code = "roam0"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = 
                                        CASE code = "home0" -> amf_home0_emergency_number_set
                                        [] code = "roam0" -> amf_roam0_emergency_number_set,
                             !.mnc = code]
                    \/  /\ amf_1_emergency_attach_accept_include_enl = 1
                        /\  \/ code = "home1"
                            \/ code = "roam1"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = 
                                        CASE code = "home1" -> amf_home1_emergency_number_set
                                        [] code = "roam1" -> amf_roam1_emergency_number_set,
                             !.mnc = code]    
                    \/  /\  \/  /\ amf_0_emergency_attach_accept_include_enl = 0
                                /\ enable_adversary = 1
                                /\  \/ code = "home0"
                                    \/ code = "roam0"
                            \/  /\ amf_1_emergency_attach_accept_include_enl = 0
                                /\  \/ code = "home1"
                                    \/ code = "roam1"
                        /\ amf_attach_accept_message' =
                            [amf_attach_accept_message EXCEPT !.emergency_number_list = {},
                             !.mnc = code]
        /\ pc_AMF' = "amf_emm_registered"
        /\ amf_emergency_number_set' = 
            CASE code = "home0" -> amf_home0_emergency_number_set
            [] code = "home1" -> amf_home1_emergency_number_set
            [] code = "roam0" -> amf_roam0_emergency_number_set
            [] code = "roam1" -> amf_roam1_emergency_number_set
        /\ UNCHANGED << vars \ {amf_attach_accept_message, amf_emergency_number_set, pc_AMF} >>


(* 3GPP 24.301: 5.4.7 *)
UE_send_attach_complete ==
        /\ pc_UE = "ue_emm_registered_initiated"
        /\ pc_AMF = "amf_emm_registered"
        /\  \/  /\ ue_sim_card_present = 1 (* 3GPP 22.101: 10.1.1 *) (* 3GPP 24.008: 4.7.3.1.3 *) (* 3GPP 24.301: 5.3.7 *)
                    (* unchanged MCC and attach_accept.enl is empty *)
                /\  \/  /\  \/  /\  ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in HOME_MNC_CANDIDATES_SET
                            \/  /\  ue_current_mnc \in ROAM_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in ROAM_MNC_CANDIDATES_SET
                        /\ amf_attach_accept_message.emergency_number_list = {}   
                        /\ ue_emergency_number_set' = UNION {ue_emergency_number_set, amf_home1_emergency_number_set} (* ue_sim_emergency_number_set *)
                    (* changed MCC or attach_accept.enl is not empty *)
                    \/  /\  \/  /\  ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in ROAM_MNC_CANDIDATES_SET
                            \/  /\  ue_current_mnc \in ROAM_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in HOME_MNC_CANDIDATES_SET
                            \/  /\  amf_attach_accept_message.emergency_number_list /= {}
                        /\ ue_emergency_number_set' = UNION {UE_FIXED_EMERGENCY_NUMBER_SET, amf_home1_emergency_number_set, amf_attach_accept_message.emergency_number_list}
            \/  /\ ue_sim_card_present = 0
                /\ ue_emergency_number_set' = UNION {UE_FIXED_EMERGENCY_NUMBER_SET, UE_ME_EMERGENCY_NUMBER_SET}
                (* /\  \/  /\  \/  /\  ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in HOME_MNC_CANDIDATES_SET
                            \/  /\  ue_current_mnc \in ROAM_MNC_CANDIDATES_SET
                                /\ amf_attach_accept_message.mnc \in ROAM_MNC_CANDIDATES_SET
                        /\ ue_emergency_number_set' = UNION {ue_emergency_number_set, UE_ME_EMERGENCY_NUMBER_SET}
                    \/  /\  \/  /\  ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                /\  amf_attach_accept_message.mnc \in ROAM_MNC_CANDIDATES_SET
                            \/  /\  ue_current_mnc \in ROAM_MNC_CANDIDATES_SET
                                /\ amf_attach_accept_message.mnc \in HOME_MNC_CANDIDATES_SET
                        /\ ue_emergency_number_set' = UNION {UE_FIXED_EMERGENCY_NUMBER_SET, UE_ME_EMERGENCY_NUMBER_SET} *)
        
        /\ ue_current_mnc' = amf_attach_accept_message.mnc
        /\ pc_UE' = "ue_emm_registered"
        /\ UNCHANGED << vars \ {ue_emergency_number_set, ue_current_mnc, pc_UE} >>


UE_hang_up ==
        /\ pc_UE = "ue_refuse_call"
        /\ user_make_call' = 0
        /\ ue_dial_emergency' = 0
        /\ pc_UE' = "ue_emm_registered"
        /\ UNCHANGED << vars \ {user_make_call, ue_dial_emergency, pc_UE} >>


(* call setup *)
UE_send_setup ==
        /\ pc_UE = "ue_emm_registered"
        /\ pc_AMF = "amf_emm_registered"
        /\ user_make_call = 1
            (* UE has just received an error code for unmarked_emergency_request *)
        /\  \/  /\ user_dial_number \in ue_emergency_number_set
                /\ amf_call_failure_message.error_code = "emergency_registration_required"
                /\ ue_dial_emergency' = 1
                /\ ue_emergency_setup_message' =
                    [ue_emergency_setup_message EXCEPT !.number = user_dial_number, !.category = "police"]
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_call_initiated"
            (* UE accept a call in ENL *) (* ECC NOT ENABLED *)
            \/  /\ user_dial_number \in ue_emergency_number_set
                /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                /\ \/ ecc_localization_enabled = 0
                   \/ user_dial_number \notin ECC_LIST_SET
                   \/ ue_current_mnc \notin ecc_localization_enabled_mnc_set
                /\ ue_dial_emergency' = 1
                /\ \E cat \in EMERGENCY_CATEGORY_SET : ue_emergency_setup_message' =
                    [ue_emergency_setup_message EXCEPT !.number = user_dial_number, !.category = cat]
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_call_initiated"
            (* UE accept a call in ENL *) (* ECC ENABLED *)
            \/  /\ user_dial_number \in ue_emergency_number_set
                /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                /\ ecc_localization_enabled = 1
                /\ user_dial_number \in ECC_LIST_SET
                /\ ue_current_mnc \in ecc_localization_enabled_mnc_set
                /\ ue_dial_emergency' = 1
                /\ ue_emergency_setup_message' =
                    [ue_emergency_setup_message EXCEPT !.number = user_dial_number, !.category = "none"]
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_call_initiated"
            (* non UE detectible emergency session *) (* 3GPP 23.167: 7.1.2 *)
            \/  /\ user_dial_number \notin ue_emergency_number_set
                /\ screen_locked = 0
                /\ ue_attach_request_message.type = "normal"
                /\ ue_dial_emergency' = 0
                /\ ue_emergency_setup_message' =
                    [ue_emergency_setup_message EXCEPT !.number = user_dial_number, !.category = "none"]
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_call_initiated"
            (* UE is required to be emergency registered in roaming *) (* 3GPP 23.167: 7.2 *)
            \/  /\ user_dial_number \in ue_emergency_number_set
                /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                /\ ue_attach_request_message.type = "normal"
                /\ ue_dial_emergency' = ue_dial_emergency
                /\ ue_detach_request_message' = 1
                /\ pc_UE' = "ue_emm_deregistered"
                /\ ue_emergency_setup_message' = ue_emergency_setup_message
            \/  /\ user_dial_number \in ue_emergency_number_set
                /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                /\ ue_attach_request_message.type = "emergency"
                /\ ue_dial_emergency' = 1
                /\ \E cat \in EMERGENCY_CATEGORY_SET : ue_emergency_setup_message' =
                    [ue_emergency_setup_message EXCEPT !.number = user_dial_number, !.category = cat]
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_call_initiated"
            (* UE refuse a call not in ENL *) (* screen locked or emergency dialing *)
            \/  /\ user_dial_number \notin ue_emergency_number_set
                /\ ue_dial_emergency' = ue_dial_emergency
                /\ ue_detach_request_message' = ue_detach_request_message
                /\ pc_UE' = "ue_refuse_call"
                /\ ue_emergency_setup_message' = ue_emergency_setup_message

        /\ amf_call_failure_message' = [amf_call_failure_message EXCEPT !.error_code = "none"]
        /\ UNCHANGED << vars \ {ue_dial_emergency, ue_emergency_setup_message, pc_UE, amf_call_failure_message, ue_detach_request_message} >>


AMF_send_call_response ==
        /\ pc_AMF = "amf_emm_registered"
        /\ pc_UE = "ue_call_initiated"
        /\ ue_detach_request_message /= 1
        /\  \/  /\ ue_current_mnc \in {"home0", "roam0"}
                /\ routed_psap' = routed_psap
                /\ amf_call_connect_message' = amf_call_connect_message
                /\ amf_call_failure_message' =
                    [amf_call_failure_message EXCEPT !.error_code = "none"]

            \/  /\ ue_current_mnc \notin {"home0", "roam0"}
                /\ ue_valid_subscription = 1
                /\ ue_emergency_setup_message.category = "none"
                /\  \/  /\ ue_attach_request_message.type = "emergency"
                        /\ routed_psap' = routed_psap
                        /\ amf_call_connect_message' = amf_call_connect_message
                        /\ amf_call_failure_message' =
                            [amf_call_failure_message EXCEPT !.error_code = "non_emergency_request_with_emergency_registration"]

                    \/  /\ ue_attach_request_message.type = "normal"
                        /\  \/  /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                /\  \/  /\ ue_emergency_setup_message.number \notin amf_emergency_number_set
                                        /\ routed_psap' = "none"
                                        /\ amf_call_connect_message' = 1
                                        /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_emergency_setup_message.number \in amf_emergency_number_set
                                        /\  \/  /\ amf_home_reject_or_allow_unmarked_emergency_request = 0
                                                /\ routed_psap' = routed_psap
                                                /\ amf_call_connect_message' = amf_call_connect_message
                                                /\ amf_call_failure_message' =
                                                    [amf_call_failure_message EXCEPT !.error_code = "unmarked_emergency_request"]

                                            \/  /\ amf_home_reject_or_allow_unmarked_emergency_request = 1
                                                /\ routed_psap' = "police"
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message


                            \/  /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                                /\  \/  /\ ue_emergency_setup_message.number \notin amf_emergency_number_set
                                        /\ routed_psap' = "none"
                                        /\ amf_call_connect_message' = 1
                                        /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_emergency_setup_message.number \in amf_emergency_number_set
                                        /\  \/  /\ amf_roam_reject_or_allow_unmarked_emergency_request = 0
                                                /\ routed_psap' = routed_psap
                                                /\ amf_call_connect_message' = amf_call_connect_message
                                                /\ amf_call_failure_message' =
                                                    [amf_call_failure_message EXCEPT !.error_code = "unmarked_emergency_request"]

                                            \/  /\ amf_roam_reject_or_allow_unmarked_emergency_request = 1
                                                /\ routed_psap' = "police"
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message

            \/  /\ ue_current_mnc \notin {"home0", "roam0"}
                /\ ue_valid_subscription = 0
                /\ ue_emergency_setup_message.category = "none"
                /\ routed_psap' = routed_psap
                /\ amf_call_connect_message' = amf_call_connect_message
                /\ amf_call_failure_message' =
                    [amf_call_failure_message EXCEPT !.error_code = "invalid_subscription"]

            \/  /\ ue_current_mnc = "home1"
                /\ ue_emergency_setup_message.category /= "none"
                /\  \/  /\ ue_emergency_setup_message.number \notin UNION{UE_FIXED_EMERGENCY_NUMBER_SET, amf_home1_emergency_number_set}
                        /\ routed_psap' = routed_psap
                        /\ amf_call_connect_message' = 0
                        /\ amf_call_failure_message' =
                            [amf_call_failure_message EXCEPT !.error_code = "unmarked_emergency_request"]
                    \/  /\ ue_emergency_setup_message.number \in UNION{UE_FIXED_EMERGENCY_NUMBER_SET, amf_home1_emergency_number_set}
                        /\ amf_allow_emergency_setup = 1
                        /\  \/  /\ ue_attach_request_message.type = "emergency"
                                /\  \/  /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_home_route_with_type_or_number = 0
                                                /\ routed_psap' = ue_emergency_setup_message.category
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message

                                            \/  /\ amf_home_route_with_type_or_number = 1
                                                /\  \/  /\ ue_emergency_setup_message.number \in amf_emergency_number_set
                                                        /\ routed_psap' = "police"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message
                                                    \/  /\ ue_emergency_setup_message.number \notin amf_emergency_number_set
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 0
                                                                /\ routed_psap' = routed_psap
                                                                /\ amf_call_connect_message' = 0
                                                                /\ amf_call_failure_message' =
                                                                    [amf_call_failure_message EXCEPT !.error_code = "normal_call_disallowed_in_emergency_session"]
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 1
                                                                /\ routed_psap' = "none"
                                                                /\ amf_call_connect_message' = 1
                                                                /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_roam_route_with_type_or_number = 0
                                                /\ routed_psap' = ue_emergency_setup_message.category
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message

                                            \/  /\ amf_roam_route_with_type_or_number = 1
                                                /\  \/  /\ ue_emergency_setup_message.number \in amf_emergency_number_set
                                                        /\ routed_psap' = "police"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message
                                                    \/  /\ ue_emergency_setup_message.number \notin amf_emergency_number_set
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 0
                                                                /\ routed_psap' = routed_psap
                                                                /\ amf_call_connect_message' = 0
                                                                /\ amf_call_failure_message' =
                                                                    [amf_call_failure_message EXCEPT !.error_code = "normal_call_disallowed_in_emergency_session"]
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 1
                                                                /\ routed_psap' = "none"
                                                                /\ amf_call_connect_message' = 1
                                                                /\ amf_call_failure_message' = amf_call_failure_message

                            \/  /\ ue_attach_request_message.type = "normal"
                                /\  \/  /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_home_require_emergency_registration_for_emergency_session = 1
                                                /\ routed_psap' = routed_psap
                                                /\ amf_call_connect_message' = amf_call_connect_message
                                                /\ amf_call_failure_message' =
                                                    [amf_call_failure_message EXCEPT !.error_code = "emergency_registration_required"]

                                            \/  /\ amf_home_require_emergency_registration_for_emergency_session = 0
                                                /\  \/  /\ amf_home_route_with_type_or_number = 0
                                                        /\ routed_psap' = ue_emergency_setup_message.category
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message

                                                    \/  /\ amf_home_route_with_type_or_number = 1
                                                        /\ \/ /\ ue_emergency_setup_message.number \in amf_emergency_number_set
                                                              /\ routed_psap' = "police"
                                                           \/ /\ ue_emergency_setup_message.number \notin amf_emergency_number_set
                                                              /\ routed_psap' = "none"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                                        /\ routed_psap' = routed_psap
                                        /\ amf_call_connect_message' = amf_call_connect_message
                                        /\ amf_call_failure_message' =
                                            [amf_call_failure_message EXCEPT !.error_code = "emergency_registration_required"]

            \/  /\ ue_current_mnc = "roam1"
                /\ ue_emergency_setup_message.category /= "none"
                /\ amf_allow_emergency_setup = 1
                /\  \/  /\ ue_emergency_setup_message.number \notin UNION{UE_FIXED_EMERGENCY_NUMBER_SET, amf_emergency_number_set, amf_home1_emergency_number_set}
                        /\ routed_psap' = routed_psap
                        /\ amf_call_connect_message' = 0
                        /\ amf_call_failure_message' =
                            [amf_call_failure_message EXCEPT !.error_code = "unmarked_emergency_request"]
                    \/  /\ ue_emergency_setup_message.number \in UNION{UE_FIXED_EMERGENCY_NUMBER_SET, amf_emergency_number_set, amf_home1_emergency_number_set}
                        /\  \/  /\ ue_attach_request_message.type = "emergency"
                                /\  \/  /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_home_route_with_type_or_number = 0
                                                /\ routed_psap' = ue_emergency_setup_message.category
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message

                                            \/  /\ amf_home_route_with_type_or_number = 1
                                                /\  \/  /\ ue_emergency_setup_message.number \in UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                        /\ routed_psap' = "police"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message
                                                    \/  /\ ue_emergency_setup_message.number \notin UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 0
                                                                /\ routed_psap' = routed_psap
                                                                /\ amf_call_connect_message' = 0
                                                                /\ amf_call_failure_message' =
                                                                    [amf_call_failure_message EXCEPT !.error_code = "normal_call_disallowed_in_emergency_session"]
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 1
                                                                /\ routed_psap' = "none"
                                                                /\ amf_call_connect_message' = 1
                                                                /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_roam_route_with_type_or_number = 0
                                                /\ routed_psap' = ue_emergency_setup_message.category
                                                /\ amf_call_connect_message' = 1
                                                /\ amf_call_failure_message' = amf_call_failure_message

                                            \/  /\ amf_roam_route_with_type_or_number = 1
                                                /\  \/  /\ ue_emergency_setup_message.number \in UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                        /\ routed_psap' = "police"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message
                                                    \/  /\ ue_emergency_setup_message.number \notin UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 0
                                                                /\ routed_psap' = routed_psap
                                                                /\ amf_call_connect_message' = 0
                                                                /\ amf_call_failure_message' =
                                                                    [amf_call_failure_message EXCEPT !.error_code = "normal_call_disallowed_in_emergency_session"]
                                                        /\  \/  /\ AMF_ALLOW_NORMAL_CALL_IN_EMERGENCY_SESSION = 1
                                                                /\ routed_psap' = "none"
                                                                /\ amf_call_connect_message' = 1
                                                                /\ amf_call_failure_message' = amf_call_failure_message

                            \/  /\ ue_attach_request_message.type = "normal"
                                /\  \/  /\ ue_current_mnc \in HOME_MNC_CANDIDATES_SET
                                        /\  \/  /\ amf_home_require_emergency_registration_for_emergency_session = 1
                                                /\ routed_psap' = routed_psap
                                                /\ amf_call_connect_message' = amf_call_connect_message
                                                /\ amf_call_failure_message' =
                                                    [amf_call_failure_message EXCEPT !.error_code = "emergency_registration_required"]

                                            \/  /\ amf_home_require_emergency_registration_for_emergency_session = 0
                                                /\  \/  /\ amf_home_route_with_type_or_number = 0
                                                        /\ routed_psap' = ue_emergency_setup_message.category
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message

                                                    \/  /\ amf_home_route_with_type_or_number = 1
                                                        /\ \/ /\ ue_emergency_setup_message.number \in UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                              /\ routed_psap' = "police"
                                                           \/ /\ ue_emergency_setup_message.number \notin UNION{amf_emergency_number_set, amf_home1_emergency_number_set}
                                                              /\ routed_psap' = "none"
                                                        /\ amf_call_connect_message' = 1
                                                        /\ amf_call_failure_message' = amf_call_failure_message

                                    \/  /\ ue_current_mnc \notin HOME_MNC_CANDIDATES_SET
                                        /\ routed_psap' = routed_psap
                                        /\ amf_call_connect_message' = amf_call_connect_message
                                        /\ amf_call_failure_message' =
                                            [amf_call_failure_message EXCEPT !.error_code = "emergency_registration_required"]


        /\ pc_AMF' = "amf_call_release"
        /\ UNCHANGED << vars \ {routed_psap, amf_call_connect_message, amf_call_failure_message, pc_AMF} >>


UE_release_call ==
        /\ pc_AMF = "amf_call_release"
        /\ user_make_call' = 0
        /\ ue_dial_emergency' = 0
        /\ user_dial_number' = "0"
        /\ amf_call_connect_message' = 0
        /\  \/  /\ ue_attach_request_message.type = "normal" (* normal attach *)
                /\ pc_UE' = "ue_emm_registered"
                /\ ue_detach_request_message' = ue_detach_request_message

            \/  /\ ue_attach_request_message.type = "emergency" (* emergency attach *)
                /\ pc_UE' = "ue_emm_deregistered"
                /\ ue_detach_request_message' = 1

        /\ UNCHANGED << vars \ {user_make_call, ue_dial_emergency, user_dial_number, amf_call_connect_message, pc_UE, ue_detach_request_message} >>


UE_send_detach_request ==
        /\ pc_UE /= "ue_emm_deregistered"
        /\ pc_AMF /= "amf_call_release"
        /\ ue_detach_request_message' = 1
        /\ user_make_call' = 0
        /\ ue_dial_emergency' = 0
        /\ user_dial_number' = "0"
        /\ amf_call_connect_message' = 0
        /\ pc_UE' = "ue_emm_deregistered"
        /\ UNCHANGED << vars \ {user_make_call, ue_dial_emergency, user_dial_number, amf_call_connect_message, ue_detach_request_message, pc_UE} >>


AMF_send_detach_accept ==
        /\ ue_detach_request_message = 1
        /\ ue_detach_request_message' = 0
        /\ pc_AMF' = "amf_emm_deregistered"
        /\ UNCHANGED << vars \ {ue_detach_request_message, pc_AMF} >>


UE_Next ==
        \/ UE_send_normal_attach_request
        \/ UE_send_emergency_attach_request
        \/ UE_send_detach_request_for_emergency
        \/ UE_send_attach_complete
        \/ UE_hang_up
        \/ UE_send_setup
        \/ UE_release_call
        \/ UE_send_detach_request


AMF_Next ==
        \/ AMF_send_attach_response
        \/ AMF_send_call_response
        \/ AMF_send_detach_accept


Next ==
        \/ UE_Next
        \/ AMF_Next
        \/ USER_make_call

-----------------------------------------------------------------------------

System_Constraint ==
\*        /\ amf_allow_emergency_attach = 0 (* System Constraint *)
        /\ amf_allow_emergency_setup = 0 (* System Constraint *)
        /\ amf_home_route_with_type_or_number = 1 (* System Constraint *)
        /\ amf_home1_emergency_number_set = LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET (* System Constraint *)
        /\ amf_roam1_emergency_number_set = LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET (* System Constraint *)
        /\ enable_adversary = 0 (* System Constraint *)
        /\ amf_home0_emergency_number_set = {"224"} (* don't care in init *)
        /\ amf_roam0_emergency_number_set = {"224"} (* don't care in init *)


System_Constraint_sol ==
        /\ amf_allow_emergency_setup = 1  (* 2 *)
        /\ amf_home_route_with_type_or_number = 1
        /\ amf_1_normal_attach_accept_include_enl = 1 (* 1 *)
        /\ amf_1_emergency_attach_accept_include_enl = 1  (* 1 *)
        /\ amf_home1_emergency_number_set = LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET
        /\ amf_roam1_emergency_number_set = LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET
        /\ enable_adversary = 0
        /\ amf_home0_emergency_number_set = {"224"}
        /\ amf_roam0_emergency_number_set = {"224"}


\* Init0 will show a trace that user can successfully dial an emergency call
Init0 ==
        /\ Init
        /\ System_Constraint


Cond1 ==
        /\ ue_sim_card_present = 0 (* F1 Core *)


Init1 ==
        /\ Init
        /\ System_Constraint
        /\ Cond1


Init1_sol ==
        /\ Init
        /\ System_Constraint_sol
        /\ Cond1


F1 == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET) => (routed_psap = "none")


F1_sol == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET /\ ue_dial_emergency = 1 /\ amf_call_connect_message = 1)
           => (routed_psap /= "none")


Cond2 ==
        /\ mnc_home_only = 1 (* SIM is issued by local mnc carrier. *)
        /\ ecc_localization_enabled = 0


Init2 ==
        /\ Init
        /\ System_Constraint
        /\ ~(Cond1) (* F1 Core *)
        /\ Cond2


Init2_sol ==
        /\ Init
        /\ System_Constraint_sol
        /\ ~(Cond1)
        /\ Cond2


F2 == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET) => (routed_psap = "none")


F2_sol == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET /\ ue_dial_emergency = 1 /\ amf_call_connect_message = 1)
           => (routed_psap /= "none")


Cond3 ==
        /\ ue_valid_subscription = 0


Init3 ==
        /\ Init
        /\ System_Constraint
        /\ ~(Cond1) (* F1 Core *)
        /\ Cond3


Init3_sol ==
        /\ Init
        /\ System_Constraint_sol
        /\ ~(Cond1)
        /\ Cond3


F3 == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET) => (routed_psap = "none")


F3_sol == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET /\ ue_dial_emergency = 1 /\ amf_call_connect_message = 1)
           => (routed_psap /= "none")


Cond4 ==
        /\ screen_locked = 1


Init4 ==
        /\ Init
        /\ System_Constraint
        /\ ~(Cond1) (* F1 Core *)
        /\ ~(Cond3) (* F3 Core *)
        /\ Cond4


Init4_sol ==
        /\ Init
        /\ System_Constraint_sol
        /\ ~(Cond1)
        /\ ~(Cond3)
        /\ Cond4


F4 == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET /\ LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET \intersect ue_emergency_number_set = {} ) => (routed_psap = "none")


F4_sol == (user_dial_number \in LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET /\ ue_dial_emergency = 1 /\ amf_call_connect_message = 1 /\ ue_current_mnc = "roam1" /\ LOCAL_EMERGENCY_NUMBER_CANDIDATES_SET \intersect ue_emergency_number_set_init = {} )
            => (routed_psap /= "none")


Spec == /\ Init1
        /\ [][Next]_vars


-----------------------------------------------------------------------------

(* Attack1: Spoofing: Without unlocking a cell phone, the adversary dials a normal number with emergency tag.
 Then the call is connected successfully. *)
(* P *)
System_Constraint_US1 ==
        /\ amf_allow_emergency_setup = 1
        /\ amf_home_route_with_type_or_number = 1
        /\ amf_roam_route_with_type_or_number = 1
        /\ amf_home1_emergency_number_set = UE_FIXED_EMERGENCY_NUMBER_SET
        /\ amf_roam1_emergency_number_set = UE_FIXED_EMERGENCY_NUMBER_SET
        /\ enable_adversary = 1
        /\ amf_0_normal_attach_accept_include_enl \in {0, 1}
        /\ amf_1_normal_attach_accept_include_enl = 0
        /\ amf_0_emergency_attach_accept_include_enl \in {0, 1}
        /\ amf_1_emergency_attach_accept_include_enl = 0


Init_US1 ==
        /\ Init
        /\ System_Constraint_US1


Init_US1_sol ==
        /\ Init
        /\ System_Constraint_sol


Attack1 == (ue_dial_emergency = 1 /\ amf_call_connect_message = 1 /\ ue_emergency_setup_message.number \notin EMERGENCY_NUMBER_CANDIDATES_SET)
           => (ue_emergency_setup_message.number \in amf_emergency_number_set \/ routed_psap /= "none")


(* Attack2: Denial of Service: The adversary uses a fake station to push an enl with normal numbers
 to all phones in that region. Then the victims cannot dial the normal numbers within that enl, but is connected to PSAP. *)
(* P *)
System_Constraint_US2 ==
        /\ amf_allow_emergency_setup = 1
        /\ amf_home_route_with_type_or_number = 0
        /\ amf_roam_route_with_type_or_number = 0
        /\ amf_home1_emergency_number_set = UE_FIXED_EMERGENCY_NUMBER_SET
        /\ amf_roam1_emergency_number_set = UE_FIXED_EMERGENCY_NUMBER_SET
        /\ enable_adversary = 1
        /\ amf_0_normal_attach_accept_include_enl \in {0, 1}
        /\ amf_1_normal_attach_accept_include_enl = 0
        /\ amf_0_emergency_attach_accept_include_enl \in {0, 1}
        /\ amf_1_emergency_attach_accept_include_enl = 0


Init_US2 ==
        /\ Init
        /\ System_Constraint_US2


Attack2 == (user_make_call = 1 /\ ue_emergency_setup_message.number \notin EMERGENCY_NUMBER_CANDIDATES_SET /\ amf_call_connect_message = 1)
           => (routed_psap = "none")


Init_US2_sol ==
        /\ Init
        /\ System_Constraint_sol


(* Constraint_auto *)
Constraint_auto == TRUE

=============================================================================