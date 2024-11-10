/datum/component/equipment_fault
	//tool flags to clear
	var/interactions = 0
	var/static/list/tool_to_repair_type = list("[TOOL_CUTTING]"=/datum/contextAction/repair/cut,
											   "[TOOL_PRYING]"=/datum/contextAction/repair/pry,
											   "[TOOL_PULSING]"=/datum/contextAction/repair/pulse,
											   "[TOOL_SCREWING]"=/datum/contextAction/repair/screw,
											   "[TOOL_SNIPPING]"=/datum/contextAction/repair/cut,
											   "[TOOL_WELDING]"=/datum/contextAction/repair/weld,
											   "[TOOL_WRENCHING]"=/datum/contextAction/repair/wrench,
											   )

TYPEINFO(/datum/component/equipment_fault)
	initialization_args = list(
		ARG_INFO("tool_flags", DATA_INPUT_BITFIELD, "Tools Required", TOOL_PULSING | TOOL_SCREWING),
	)

/datum/component/equipment_fault/Initialize(tool_flags)
	. = ..()
	if(!istype(parent, /obj/machinery))
		return COMPONENT_INCOMPATIBLE
	src.interactions = tool_flags
	RegisterSignal(parent, COMSIG_ATTACKBY, PROC_REF(ef_attackby))
	RegisterSignal(parent, COMSIG_ATTACKHAND, PROC_REF(ef_attackhand))

/datum/component/equipment_fault/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATTACKBY)
	UnregisterSignal(parent, COMSIG_ATTACKHAND)
	. = ..()

/datum/component/equipment_fault/proc/ef_attackby(atom/A, obj/item/I, mob/user = null)
	var/attempt = FALSE
	var/interaction_type = 0
	var/duration = 2 SECONDS
	if(src.interactions & TOOL_CUTTING && iscuttingtool(I))
		attempt = TRUE
		interaction_type = TOOL_CUTTING
	else if(src.interactions & TOOL_PULSING && ispulsingtool(I))
		attempt = TRUE
		interaction_type = TOOL_PULSING
	else if(src.interactions & TOOL_PRYING && ispryingtool(I))
		attempt = TRUE
		interaction_type = TOOL_PRYING
	else if(src.interactions & TOOL_SCREWING && isscrewingtool(I))
		attempt = TRUE
		interaction_type = TOOL_SCREWING
	else if(src.interactions & TOOL_SNIPPING && issnippingtool(I))
		attempt = TRUE
		interaction_type = TOOL_SNIPPING
	else if(src.interactions & TOOL_WRENCHING && iswrenchingtool(I))
		attempt = TRUE
		interaction_type = TOOL_WRENCHING
	else if(src.interactions & TOOL_WELDING && isweldingtool(I))
		if(I:try_weld(user,1))
			attempt = TRUE
			interaction_type = TOOL_WELDING

	if(attempt)
		actions.start(new /datum/action/bar/icon/callback(user, src.parent, duration, PROC_REF(complete_stage), list(user, I, interaction_type), I.icon, I.icon_state,
			null, null, src), user)
	else
		showContextActions(user)

	return TRUE


/datum/component/equipment_fault/proc/ef_attackhand(atom/A, mob/user)
	if(showContextActions(user))
		boutput(user, SPAN_ALERT("You need to use some tools on [A] before it can be fixed."))
	else
		boutput(user, SPAN_ALERT("You feel as though [A] isn't working right..."))
	return TRUE

/datum/component/equipment_fault/proc/showContextActions(mob/user)
	if(!istype(user))
		return
	var/decon_contexts = list()
	if (interactions & TOOL_SCREWING)
		var/datum/contextAction/repair/screw/newcon = new
		decon_contexts += newcon
	if (interactions & TOOL_WRENCHING)
		var/datum/contextAction/repair/wrench/newcon = new
		decon_contexts += newcon
	if (interactions & TOOL_PRYING)
		var/datum/contextAction/repair/pry/newcon = new
		decon_contexts += newcon
	if (interactions & TOOL_WRENCHING)
		var/datum/contextAction/repair/weld/newcon = new
		decon_contexts += newcon
	if (interactions & TOOL_SNIPPING)
		var/datum/contextAction/repair/cut/newcon = new
		decon_contexts += newcon
	if (interactions & TOOL_PULSING)
		var/datum/contextAction/repair/pulse/newcon = new
		decon_contexts += newcon


	. = length(decon_contexts)
	if(.)
		user.showContextActions(decon_contexts, src.parent)


/datum/component/equipment_fault/proc/complete_stage(mob/user as mob, obj/item/W as obj, interaction)
	//clear interaction
	src.interactions &= ~interaction

	user.removeContextAction(src.tool_to_repair_type["[interaction]"])

	if(src.interactions == 0)
		UnregisterFromParent()
		boutput(user, SPAN_ALERT("You feel as though you have repaired [src.parent]. Job well done!"))
	else
		showContextActions(user)

/datum/contextAction/repair
	icon = 'icons/ui/context16x16.dmi'
	name = "Repair with Tool"
	desc = "You shouldn't be reading this, bug."
	icon_state = "wrench"
	var/omni_mode
	var/omni_path
	var/success_text
	var/success_sound

	proc/success_feedback(atom/target, mob/user)
		user.show_text(replacetext(success_text, "%target%", target), "blue")
		if (success_sound)
			playsound(target, success_sound, 50, TRUE)

	proc/omnitool_swap(atom/target, mob/user, obj/item/tool/omnitool/omni)
		if (!(omni_mode in omni.modes))
			return FALSE
		omni.change_mode(omni_mode, user, omni_path)
		user.show_text("You flip [omni] to [name] mode.", "blue")
		sleep(0.5 SECONDS)
		return TRUE

	execute(atom/target, mob/user, obj/item/tool/I)
		if (isobj(target))
			target.Attackby(I, user, null)
			// if (O.decon_contexts)
			// 	success_feedback(target, user)
			// 	O.decon_contexts -= src
			// 	if (length(O.decon_contexts) <= 0)
			// 		user.show_text("Looks like [target] is ready to be repaired with the device.", "blue")
			// 	else
			// 		user.showContextActions(O.decon_contexts, O)
		// else
		// 	target.removeContextAction(src.type)

	checkRequirements(atom/target, mob/user)
		if(!can_act(user) || !in_interact_range(target, user))
			return FALSE
		. = TRUE

	wrench
		name = "Wrench"
		desc = "Wrenching required to repair."
		icon_state = "wrench"
		omni_mode = OMNI_MODE_WRENCHING
		omni_path = /obj/item/wrench
		success_text = "You wrench %target%'s bolts. Nice and snug."
		success_sound = 'sound/items/Ratchet.ogg'

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if(istype(I, /obj/item/tool/omnitool))
					if(omnitool_swap(target, user, I))
						return ..(target, user, I)
				if (iswrenchingtool(I))
					return ..(target, user, I)

	cut
		name = "Cut"
		desc = "Cutting required to repair."
		icon_state = "cut"
		omni_mode = OMNI_MODE_SNIPPING
		omni_path = /obj/item/wirecutters
		success_text = "You cut some vestigial wires from %target%."
		success_sound = 'sound/items/Wirecutter.ogg'

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if(istype(I, /obj/item/tool/omnitool))
					if(omnitool_swap(target, user,I))
						return ..(target, user, I)
				if (iscuttingtool(I) || issnippingtool(I))
					return ..(target, user, I)
	weld
		name = "Weld"
		desc = "Welding required to repair."
		icon_state = "weld"
		omni_mode = OMNI_MODE_WELDING
		omni_path = /obj/item/weldingtool
		success_text = "You weld %target% carefully."
		success_sound = null // sound handled in try_weld

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if (isweldingtool(I))
					if (I:try_weld(user, 2))
						return ..(target, user, I)
				if(istype(I, /obj/item/tool/omnitool))
					var/obj/item/tool/omnitool/omni = I
					if(omnitool_swap(target, user,I))
						if (omni:try_weld(user, 2))
							return ..(target, user, I)

	pry
		name = "Pry"
		desc = "Prying required to repair. Try a crowbar."
		icon_state = "bar"
		omni_mode = OMNI_MODE_PRYING
		omni_path = /obj/item/crowbar
		success_text = "You pry things back into place on %target% with all your might."
		success_sound = 'sound/items/Crowbar.ogg'

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if(istype(I, /obj/item/tool/omnitool))
					if(omnitool_swap(target, user, I))
						return ..(target, user, I)
				if (ispryingtool(I))
					return ..(target, user, I)
	screw
		name = "Screw"
		desc = "Screwing required to repair."
		icon_state = "screw"
		omni_mode = OMNI_MODE_SCREWING
		omni_path = /obj/item/screwdriver
		success_text = "You screw in some of the screws on %target%."
		success_sound = 'sound/items/Screwdriver.ogg'

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if(istype(I, /obj/item/tool/omnitool))
					if(omnitool_swap(target, user, I))
						return ..(target, user, I)
				if (isscrewingtool(I))
					return ..(target, user, I)

	pulse
		name = "Pulse"
		desc = "Pulsing required to repair. Try a multitool."
		icon_state = "pulse"
		omni_mode = OMNI_MODE_PULSING
		omni_path = /obj/item/device/multitool
		success_text = "You pulse %target%. In a general sense."
		success_sound = 'sound/items/penclick.ogg'

		execute(atom/target, mob/user)
			for (var/obj/item/I in user.equipped_list())
				if(istype(I, /obj/item/tool/omnitool))
					if(omnitool_swap(target, user, I))
						return ..(target, user, I)
				if (ispulsingtool(I))
					return ..(target, user, I)
