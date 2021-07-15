#define CLOSED_AND_OFF 1
#define OPEN_AND_ON 2
#define OPEN_AND_OFF 3

// Contains:
// - Baton parent
// - Subtypes

////////////////////////////////////////// Stun baton parent //////////////////////////////////////////////////

// Completely refactored the ca. 2009-era code here. Powered batons also use power cells now (Convair880).
/obj/item/baton
	name = "stun baton"
	desc = "A standard issue baton for stunning people with."
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "stunbaton"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	item_state = "baton-A"
	uses_multiple_icon_states = 1
	flags = FPRINT | ONBELT | TABLEPASS
	force = 10
	throwforce = 7
	w_class = W_CLASS_NORMAL
	mats = list("MET-3"=10, "CON-2"=10)
	contraband = 4
	stamina_damage = 15
	stamina_cost = 21
	stamina_crit_chance = 5
	item_function_flags = USE_INTENT_SWITCH_TRIGGER

	var/icon_on = "stunbaton_active"
	var/icon_off = "stunbaton"
	var/item_on = "baton-A"
	var/item_off = "baton-D"
	var/flick_baton_active = "baton_active"
	var/wait_cycle = 0 // Update sprite periodically if we're using a self-charging cell.

	var/cell_type = /obj/item/ammo/power_cell/med_power // Type of cell to spawn by default.
	var/obj/item/ammo/power_cell/cell = null // Ignored for cyborgs and when used_electricity is false.
	var/cost_normal = 25 // Cost in PU. Doesn't apply to cyborgs.
	var/cost_cyborg = 500 // Battery charge to drain when user is a cyborg.
	var/uses_charges = 1 // Does it deduct charges when used? Distinct from...
	var/is_active = TRUE

	var/stun_normal_weakened = 15

	var/disorient_stamina_damage = 130 // Amount of stamina drained.
	var/can_swap_cell = 1
	var/beepsky_held_this = 0 // Did a certain validhunter hold this?
	var/flipped = false //is it currently rotated so that youre grabbing it by the head?

	New()
		..()
		if ((!isnull(src.cell_type) && ispath(src.cell_type, /obj/item/ammo/power_cell)) && (!src.cell || !istype(src.cell)))
			src.cell = new src.cell_type(src)
		processing_items |= src
		src.update_icon()
		src.setItemSpecial(/datum/item_special/spark)

		BLOCK_SETUP(BLOCK_ROD)

	disposing()
		processing_items -= src
		if(cell)
			cell.dispose()
			cell = null
		..()

	examine()
		. = ..()
		if (src.uses_charges != 0)
			if (!src.cell || !istype(src.cell))
				. += "<span class='alert'>No power cell installed.</span>"
			else
				. += "The baton is turned [src.is_active ? "on" : "off"]. There are [src.cell.charge]/[src.cell.max_charge] PUs left! Each stun will use [src.cost_normal] PUs."

	emp_act()
		if (src.uses_charges != 0)
			src.is_active = FALSE
			src.process_charges(-INFINITY)
		return

	process()
		src.wait_cycle = !src.wait_cycle
		if (src.wait_cycle)
			return

		if (!(src in processing_items))
			logTheThing("debug", null, null, "<b>Convair880</b>: Process() was called for a stun baton ([src.type]) that wasn't in the item loop. Last touched by: [src.fingerprintslast ? "[src.fingerprintslast]" : "*null*"]")
			processing_items.Add(src)
			return
		if (!src.cell || !istype(src.cell))
			processing_items.Remove(src)
			return
		if (!istype(src.cell, /obj/item/ammo/power_cell/self_charging)) // Kick out batons with a plain cell.
			processing_items.Remove(src)
			return
		if (src.cell.charge == src.cell.max_charge) // Keep self-charging cells in the loop, though.
			return

		src.update_icon()
		return

	proc/update_icon()
		if (!src || !istype(src))
			return

		if (src.is_active)
			src.set_icon_state("[src.icon_on][src.flipped ? "-f" : ""]") //if flipped is true, attach -f to the icon state. otherwise leave it as normal
			src.item_state = "[src.item_on][src.flipped ? "-f" : ""]"
		else
			src.set_icon_state("[src.icon_off][src.flipped ? "-f" : ""]")
			src.item_state = "[src.item_off][src.flipped ? "-f" : ""]"
			return

	proc/can_stun(var/amount = 1, var/mob/user)
		if (!src || !istype(src))
			return 0
		if (!(src.is_active))
			return 0
		if (amount <= 0)
			return 0

		src.regulate_charge()
		if (user && isrobot(user))
			var/mob/living/silicon/robot/R = user
			if (R.cell && R.cell.charge >= (src.cost_cyborg * amount))
				return 1
			else
				return 0
		if (!src.cell || !istype(src.cell))
			if (user && ismob(user))
				user.show_text("The [src.name] doesn't have a power cell!", "red")
			return 0
		if (src.cell.charge < (src.cost_normal * amount))
			if (user && ismob(user))
				user.show_text("The [src.name] is out of charge!", "red")
			return 0
		else
			return 1

	proc/regulate_charge()
		if (!src || !istype(src))
			return

		if (src.cell && istype(src.cell))
			if (src.cell.charge < 0)
				src.cell.charge = 0
			if (src.cell.charge > src.cell.max_charge)
				src.cell.charge = src.cell.max_charge

			src.cell.update_icon()
			src.update_icon()

		return

	proc/process_charges(var/amount = -1, var/mob/user)
		if (!src || !istype(src) || amount == 0)
			return
		if (user && isrobot(user))
			var/mob/living/silicon/robot/R = user
			if (amount < 0)
				R.cell.use(src.cost_cyborg * -(amount))
		else
			if (src.uses_charges != 0 && (src.cell && istype(src.cell)))
				if (amount < 0)
					src.cell.use(src.cost_normal * -(amount))
					if (user && ismob(user))
						if (src.cell.charge > 0)
							user.show_text("The [src.name] now has [src.cell.charge]/[src.cell.max_charge] PUs remaining.", "blue")
						else if (src.cell.charge <= 0)
							user.show_text("The [src.name] is now out of charge!", "red")
							src.stamina_damage = initial(src.stamina_damage)
							src.is_active = FALSE
							if (istype(src, /obj/item/baton/ntso)) //since ntso batons have some extra stuff, we need to set their state var to the correct value to make this work
								var/obj/item/baton/ntso/B = src
								B.state = OPEN_AND_OFF
				else if (amount > 0)
					src.cell.charge(src.cost_normal * amount)

		src.update_icon()
		if(istype(user)) // user can be a Securitron sometims, scream
			user.update_inhands()
		return

	proc/charge(var/amt)
		if(src.cell)
			return src.cell.charge(amt)
		else
			//No cell. Tell anything trying to charge it.
			return -1

	proc/do_stun(var/mob/user, var/mob/victim, var/type = "", var/stun_who = 2)
		if (!src || !istype(src) || type == "")
			return
		if (!user || !victim || !ismob(victim))
			return

		// Sound effects, log entries and text messages.
		switch (type)
			if ("failed")
				logTheThing("combat", user, null, "accidentally stuns [himself_or_herself(user)] with the [src.name] at [log_loc(user)].")
				user.visible_message("<span class='alert'><b>[user]</b> fumbles with the [src.name] and accidentally stuns [himself_or_herself(user)]!</span>")
				flick(flick_baton_active, src)
				playsound(src, "sound/impact_sounds/Energy_Hit_3.ogg", 50, 1, -1)

			if ("failed_stun")
				user.visible_message("<span class='alert'><B>[victim] has been prodded with the [src.name] by [user]! Luckily it was off.</B></span>")
				playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1, -1)
				logTheThing("combat", user, victim, "unsuccessfully tries to stun [constructTarget(victim,"combat")] with the [src.name] at [log_loc(victim)].")

				if (src.is_active && (src.cell && istype(src.cell) && (src.cell.charge < src.cost_normal)))
					if (user && ismob(user))
						user.show_text("The [src.name] is out of charge!", "red")
				return

			if ("failed_harm")
				user.visible_message("<span class='alert'><B>[user] has attempted to beat [victim] with the [src.name] but held it wrong!</B></span>")
				playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 50, 1, -1)
				logTheThing("combat", user, victim, "unsuccessfully tries to beat [constructTarget(victim,"combat")] with the [src.name] at [log_loc(victim)].")

			if ("stun")
				user.visible_message("<span class='alert'><B>[victim] has been stunned with the [src.name] by [user]!</B></span>")
				logTheThing("combat", user, victim, "stuns [constructTarget(victim,"combat")] with the [src.name] at [log_loc(victim)].")
				JOB_XP(victim, "Clown", 3)
				else
					flick(flick_baton_active, src)
					playsound(src, "sound/impact_sounds/Energy_Hit_3.ogg", 50, 1, -1)

			else
				logTheThing("debug", user, null, "<b>Convair880</b>: stun baton ([src.type]) do_stun() was called with an invalid argument ([type]), aborting. Last touched by: [src.fingerprintslast ? "[src.fingerprintslast]" : "*null*"]")
				return

		// Target setup. User might not be a mob (Beepsky), but the victim needs to be one.
		var/mob/dude_to_stun
		if (stun_who == 1 && user && ismob(user))
			dude_to_stun = user
		else
			dude_to_stun = victim

		// Stun the target mob.
		if (dude_to_stun.bioHolder && dude_to_stun.bioHolder.HasEffect("resist_electric"))
			boutput(dude_to_stun, "<span class='notice'>Thankfully, electricity doesn't do much to you in your current state.</span>")
		else
			dude_to_stun.do_disorient(src.disorient_stamina_damage, weakened = src.stun_normal_weakened * 10, disorient = 60)

			if (isliving(dude_to_stun))
				var/mob/living/L = dude_to_stun
				L.Virus_ShockCure(33)
				L.shock_cyberheart(33)

		src.process_charges(-1, user)

		// Some after attack stuff.
		if (user && ismob(user))
			user.lastattacked = dude_to_stun
			dude_to_stun.lastattacker = user
			dude_to_stun.lastattackertime = world.time

		src.update_icon()
		return

	attack_self(mob/user as mob)
		src.add_fingerprint(user)

		if (!src?.cell?.charge || src.cell.charge - src.cost_normal <= 0 && !(src.is_active))
			boutput(user, "<span class='alert'>The [src.name] doesn't have enough power to be turned on.</span>")
			return

		src.regulate_charge()
		src.is_active = !src.is_active

		if (src.can_stun() == 1 && user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50))
			src.do_stun(user, user, "failed", 1)
			JOB_XP(user, "Clown", 2)
			return

		if (src.is_active)
			boutput(user, "<span class='notice'>The [src.name] is now on.</span>")
			playsound(src, "sparks", 75, 1, -1)
		else
			boutput(user, "<span class='notice'>The [src.name] is now off.</span>")
			playsound(src, "sparks", 75, 1, -1)

		src.update_icon()
		user.update_inhands()

		return

	attack(mob/M as mob, mob/user as mob)
		src.add_fingerprint(user)
		src.regulate_charge()

		if(check_target_immunity( M ))
			user.show_message("<span class='alert'>[M] seems to be warded from attacks!</span>")
			return

		if (src.can_stun() == 1 && user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50))
			src.do_stun(user, M, "failed", 1)
			JOB_XP(user, "Clown", 1)
			return

		switch (user.a_intent)
			if ("harm")
				if (!src.is_active || (src.is_active && src.can_stun() == 0))
					playsound(src, "swing_hit", 50, 1, -1)
					..()
				else
					src.do_stun(user, M, "failed_harm", 1)

			else
				if (!src.is_active || (src.is_active && src.can_stun() == 0))
					src.do_stun(user, M, "failed_stun", 1)
				else
					src.do_stun(user, M, "stun", 2)

		return

	attackby(obj/item/b as obj, mob/user as mob)
		if (can_swap_cell && istype(b, /obj/item/ammo/power_cell/))
			var/obj/item/ammo/power_cell/pcell = b
			src.log_cellswap(user, pcell) //if (!src.rechargeable)
			if (istype(pcell, /obj/item/ammo/power_cell/self_charging) && !(src in processing_items)) // Again, we want dynamic updates here (Convair880).
				processing_items.Add(src)
			if (src.cell)
				if (pcell.swap(src))
					user.visible_message("<span class='alert'>[user] swaps [src]'s power cell.</span>")
			else
				src.cell = pcell
				user.drop_item()
				pcell.set_loc(src)
				user.visible_message("<span class='alert'>[user] swaps [src]'s power cell.</span>")
		else
			..()

	proc/log_cellswap(var/mob/user as mob, var/obj/item/ammo/power_cell/C)
		if (!user || !src || !istype(src) || !C || !istype(C))
			return

		logTheThing("combat", user, null, "swaps the power cell (<b>Cell type:</b> <i>[C.type]</i>) of [src] at [log_loc(user)].")
		return

	intent_switch_trigger(var/mob/user)
		src.do_flip_stuff(user, user.a_intent)

	attack_hand(var/mob/user)
		if (src.flipped && user.a_intent != INTENT_HARM)
			user.show_text("You flip \the [src] the right way around as you grab it.")
			src.flipped = false
			src.update_icon()
			user.update_inhands()
		else if (user.a_intent == INTENT_HARM)
			src.do_flip_stuff(user, INTENT_HARM)
		..()

	proc/do_flip_stuff(var/mob/user, var/intent)
		if (intent == INTENT_HARM)
			if (src.flipped) //swapping hands triggers the intent switch too, so we dont wanna spam that
				return
			src.flipped = true
			animate(src, transform = turn(matrix(), 120), time = 0.07 SECONDS) //turn partially
			animate(transform = turn(matrix(), 240), time = 0.07 SECONDS) //turn the rest of the way
			animate(transform = turn(matrix(), 180), time = 0.04 SECONDS) //finish up at the right spot
			src.transform = null //clear it before updating icon
			src.update_icon()
			user.update_inhands()
			user.show_text("<B>You flip \the [src] and grab it by the head! [src.is_active ? "It seems pretty unsafe to hold it like this while it's on!" : "At least its off!"]</B>", "red")
		else //not already flipped
			if (!src.flipped) //swapping hands triggers the intent switch too, so we dont wanna spam that
				return
			src.flipped = false
			animate(src, transform = turn(matrix(), 120), time = 0.07 SECONDS) //turn partially
			animate(transform = turn(matrix(), 240), time = 0.07 SECONDS) //turn the rest of the way
			animate(transform = turn(matrix(), 180), time = 0.04 SECONDS) //finish up at the right spot
			src.transform = null //clear it before updating icon
			src.update_icon()
			user.update_inhands()
			user.show_text("<B>You flip \the [src] and grab it by the base!", "red")

	dropped(mob/user)
		if (src.flipped)
			src.flipped = false
			src.update_icon()
			user.update_inhands()
		..()

/////////////////////////////////////////////// Subtypes //////////////////////////////////////////////////////

/obj/item/baton/secbot
	uses_charges = 0

/obj/item/baton/beepsky
	name = "securitron stun baton"
	desc = "A stun baton that's been modified to be used more effectively by security robots. There's a small parallel port on the bottom of the handle."
	can_swap_cell = 0
	cell_type = /obj/item/ammo/power_cell

	charge(var/amt)
		return -1 //no

/obj/item/baton/cane
	name = "stun cane"
	desc = "A stun baton built into the casing of a cane."
	icon_state = "stuncane"
	item_state = "cane"
	icon_on = "stuncane_active"
	icon_off = "stuncane"
	item_on = "cane"
	item_off = "cane"
	cell_type = /obj/item/ammo/power_cell
	mats = list("MET-3"=10, "CON-2"=10, "gem"=1, "gold"=1)

/obj/item/baton/ntso
	name = "extendable stun baton"
	desc = "An extendable stun baton for NT Security Operatives in sleek NanoTrasen blue."
	icon_state = "ntso_baton-c"
	item_state = "ntso-baton-c"
	force = 7
	mats = list("MET-3"=10, "CON-2"=10, "POW-1"=5)
	icon_on = "ntso-baton-a-1"
	icon_off = "ntso-baton-c"
	var/icon_off_open = "ntso-baton-a-0"
	item_on = "ntso-baton-a"
	item_off = "ntso-baton-c"
	var/item_off_open = "ntso-baton-d"
	flick_baton_active = "ntso-baton-a-1"
	w_class = W_CLASS_SMALL	//2 when closed, 4 when extended
	can_swap_cell = 0
	is_active = FALSE
	// stamina_based_stun_amount = 110
	cost_normal = 25 // Cost in PU. Doesn't apply to cyborgs.
	cell_type = /obj/item/ammo/power_cell/self_charging/ntso_baton
	item_function_flags = 0
	//bascially overriding is_active, but it's kinda hacky in that they both are used jointly
	var/state = CLOSED_AND_OFF

	New()
		..()
		src.setItemSpecial(/datum/item_special/spark/ntso) //override spark of parent

	//change for later for more interestings whatsits
	// can_stun(var/requires_electricity = 0, var/amount = 1, var/mob/user)
	// 	..(requires_electricity, amount, user)
	// 	if (state == CLOSED_AND_OFF || state == OPEN_AND_OFF)
	// 		return 0

	attack_self(mob/user as mob)
		src.add_fingerprint(user)
		//never should happen but w/e

		src.regulate_charge()
		//make it harder for them clowns...
		if (src.can_stun() == 1 && user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50))
			src.do_stun(user, user, "failed", 1)
			JOB_XP(user, "Clown", 2)
			return

		//move to next state
		switch (src.state)
			if (CLOSED_AND_OFF)		//move to open/on state
				if (!src.cell.charge || src.cell.charge - src.cost_normal <= 0) //ugly copy pasted code to move to next state if its depowered, cleanest solution i could think of
					boutput(user, "<span class='alert'>The [src.name] doesn't have enough power to be turned on.</span>")
					src.state = OPEN_AND_OFF
					src.is_active = FALSE
					src.w_class = W_CLASS_BULKY
					src.force = 7
					playsound(src, "sound/misc/lightswitch.ogg", 75, 1, -1)
					boutput(user, "<span class='notice'>The [src.name] is now open and unpowered.</span>")
					src.update_icon()
					user.update_inhands()
					return

				//this is the stuff that normally happens
				src.state = OPEN_AND_ON
				src.is_active = TRUE
				boutput(user, "<span class='notice'>The [src.name] is now open and on.</span>")
				src.w_class = W_CLASS_BULKY
				src.force = 7
				playsound(src, "sparks", 75, 1, -1)
			if (OPEN_AND_ON)		//move to open/off state
				src.state = OPEN_AND_OFF
				src.is_active = FALSE
				src.w_class = W_CLASS_BULKY
				src.force = 7
				playsound(src, "sound/misc/lightswitch.ogg", 75, 1, -1)
				boutput(user, "<span class='notice'>The [src.name] is now open and unpowered.</span>")
				// playsound(src, "sparks", 75, 1, -1)
			if (OPEN_AND_OFF)		//move to closed/off state
				src.state = CLOSED_AND_OFF
				src.is_active = FALSE
				src.w_class = W_CLASS_SMALL
				src.force = 1
				boutput(user, "<span class='notice'>The [src.name] is now closed.</span>")
				playsound(src, "sparks", 75, 1, -1)

		src.update_icon()
		user.update_inhands()

		return

	update_icon()
		if (!src || !istype(src))
			return
		switch (src.state)
			if (CLOSED_AND_OFF)
				src.set_icon_state(src.icon_off)
				src.item_state = src.item_off
			if (OPEN_AND_ON)
				src.set_icon_state(src.icon_on)
				src.item_state = src.item_on
			if (OPEN_AND_OFF)
				src.set_icon_state(src.icon_off_open)
				src.item_state = src.item_off_open
		return

	throw_impact(atom/A, datum/thrown_thing/thr)
		if(isliving(A))
			if (src.state == OPEN_AND_ON && src.can_stun())
				src.do_stun(usr, A, "stun")
				return
		..()

	emp_act()
		if (src.uses_charges != 0)
			if (state == OPEN_AND_ON)
				state = OPEN_AND_OFF
			src.is_active = FALSE
			usr.show_text("The [src.name] is now open and unpowered.", "blue")
			src.process_charges(-INFINITY)

		return

#undef CLOSED_AND_OFF
#undef OPEN_AND_ON
#undef OPEN_AND_OFF
