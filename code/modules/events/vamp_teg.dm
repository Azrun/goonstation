/datum/random_event/major/vampire_teg
	name = "Vampire TEG"
	required_elapsed_round_time = 40 MINUTES
	weight = 50
	var/obj/machinery/power/generatorTemp/generator
	var/list/circulators_to_relube
	var/event_active
	var/target_grump

#ifdef RP_MODE
	disabled = 1
#endif

	is_event_available(var/ignore_time_lock = 0)
		. = ..()
		if(.)
			generator = locate(/obj/machinery/power/generatorTemp) in machine_registry[MACHINES_POWER]
			if( !generator || generator.grump < 100 )
				. = FALSE

	event_effect(var/source,var/turf/T,var/delay,var/duration)
		..()
		var/list/spooky_sounds = list("sound/ambience/nature/Wind_Cold1.ogg", "sound/ambience/nature/Wind_Cold2.ogg", "sound/ambience/nature/Wind_Cold3.ogg","sound/ambience/nature/Cave_Bugs.ogg", "sound/ambience/nature/Glacier_DeepRumbling1.ogg", "sound/effects/bones_break.ogg",	"sound/effects/gust.ogg", "sound/effects/static_horror.ogg", "sound/effects/blood.ogg")
		var/list/area/stationAreas = get_accessible_station_areas()

		if(!generator)
			generator = locate(/obj/machinery/power/generatorTemp) in machine_registry[MACHINES_POWER]
		if (!generator || generator.disposed || generator.z != Z_LEVEL_STATION )
			message_admins("The Vampire TEG event failed to find TEG!")
			return

		var/list/obj/machinery/station_switches = list()
		for(var/area_key as() in stationAreas)
			var/obj/machinery/light_switch/S
			var/area/SA = stationAreas[area_key]
			S = locate(/obj/machinery/light_switch) in SA?.machines
			if(S)
				station_switches += S

		event_active = TRUE
		target_grump =  max(generator.grump-50, 50)
		generator.grump += 100
		var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
		smoke.set_up(1, 0, generator.loc)
		smoke.attach(generator)
		smoke.start()
		playsound(generator, pick(spooky_sounds), 30, 0, -1)

		src.circulators_to_relube = list(generator.circ1, generator.circ2)
		for(var/obj/machinery/atmospherics/binary/circulatorTemp/C in circulators_to_relube)
			C.reagents.add_reagent("black_goop", 10)
			C.reagents.add_reagent("black_goop", 10)

		// Delayed Warning
		SPAWN_DBG(rand(10 SECONDS, 50 SECONDS))
			if(event_active)
				command_alert("Reports indicate that the engine on-board [station_name()] is behaving unusually. Stationwide power failures may occur or worse.", "Engine Warning")
			sleep(30 SECONDS)
			if(event_active)
				command_alert("Onsite Engineers inform us a sympathetic connection exists between the furances and the engine. Considering burning something it might enjoy food, people, weed, we are grasping at straws here. ", "Engine Suggestion")

		// FAILURE EVENT
		SPAWN_DBG(2 MINUTES) //rand( 7 MINUTES, 9 MINUTES )
			if(event_active)
				event_active = FALSE
				for (var/obj/machinery/light_switch/L as() in station_switches)
					if(L.on && prob(50))
						elecflash(L)
						L.attack_hand(null)
				generator.transformation_mngr.transform_to_type(/datum/teg_transformation/vampire)

		SPAWN_DBG(0)
			var/area/A = get_area(generator)
			var/obj/machinery/teg_light_switch = locate(/obj/machinery/light_switch) in A.machines

			if(teg_light_switch)
				elecflash(teg_light_switch)
				teg_light_switch.attack_hand(null)

			while(event_active)
				//Bail on event if something happened to TEG
				if(!generator || generator.disposed)
					event_active = FALSE
					return

				//Check for success!
				if(generator.grump < target_grump)
					event_active = FALSE
					return

				if(prob(50))
					playsound(generator, pick(spooky_sounds), 30, 0, -1)
					switch(rand(1,5))
						if(1)
							animate_flash_color_fill_inherit(pick(generator,generator.circ1,generator.circ2),"#e13333",2, 2 SECONDS)
						if(2)
							animate_levitate(pick(generator,generator.circ1,generator.circ2), 1, 50, random_side = FALSE)
						if(3)
							//Turn off light switches
							for (var/obj/machinery/light_switch/L as() in station_switches)
								if(L.on && prob(5))
									elecflash(L)
									L.attack_hand(null)
						if(4)
							//Electrify Doors
							for_by_tcl(D, /obj/machinery/door/airlock)
								if (D.z == Z_LEVEL_STATION && D.powered() && prob(5))
									if (D.secondsElectrified == 0)
										elecflash(D)
										D.secondsElectrified = -1
										SPAWN_DBG(10 SECONDS)
											if (D)
												D.secondsElectrified = 0
						if(5)
							//Reduced APC EMP
							var/obj/machinery/power/apc/apc
							A = pick(stationAreas)
							apc = stationAreas[A].area_apc
							if(apc && apc.powered() && (apc.lighting || apc.equipment || apc.environ ) )
								elecflash(apc, radius=1)
								if(apc.cell)
									apc.cell.charge -= 500
									if (apc.cell.charge < 0)
										apc.cell.charge = 0
								apc.lighting = 0
								apc.equipment = 0
								apc.environ = 0
								SPAWN_DBG(20 SECONDS)
									apc.equipment = 3
									apc.environ = 3

				for(var/obj/machinery/atmospherics/binary/circulatorTemp/C in circulators_to_relube)
					if( !C.reagents.has_reagent("black_goop") && (C.reagents.total_volume > (C.reagents.maximum_volume/10) ))
						circulators_to_relube -= C
						target_grump += 25

				sleep(rand(5.8 SECONDS, rand(25 SECONDS)))


datum/teg_transformation/vampire
	mat_id = "bone"
	required_reagents = list("vampire_serum"=5) /// TODO Azrun - REMOVE PRIOR TO UNDRAFT, For zee testing
	var/datum/abilityHolder/vampire/abilityHolder
	var/list/datum/targetable/vampire/abilities = list()
	var/health = 150

	proc/attach_hud()
		. = FALSE

	disposing()
		actions.stop_all(abilityHolder.owner)
		abilityHolder.owner = null
		qdel(abilityHolder)
		. = ..()

	on_transform(obj/machinery/power/generatorTemp/teg)
		. = ..()
		abilityHolder = new /datum/abilityHolder/vampire(src)
		abilityHolder.owner = teg
		abilityHolder.addAbility(/datum/targetable/vampire/blood_steal)
		for(var/datum/targetable/vampire/A in abilityHolder.abilities)
			abilities[A.name] = A
		RegisterSignal(src.teg, COMSIG_ATOM_HITBY_PROJ, .proc/projectile_collide)
		RegisterSignal(src.teg, COMSIG_ATTACKBY, .proc/attackby)

		var/image/mask = image('icons/obj/clothing/item_masks.dmi', "death")
		mask.appearance_flags = RESET_COLOR | RESET_ALPHA
		mask.color = "#b10000"
		mask.alpha = 240
		teg.UpdateOverlays(mask, "mask")
		var/volume = src.teg.circ1.reagents.total_volume
		src.teg.circ1.reagents.remove_any(volume)
		src.teg.circ1.reagents.add_reagent("blood", volume)
		vampify(src.teg.circ1)
		volume = src.teg.circ2.reagents.total_volume
		src.teg.circ2.reagents.remove_any(volume)
		src.teg.circ2.reagents.add_reagent("blood", volume)
		vampify(src.teg.circ2)
		vampify(src.teg)

	proc/vampify(obj/O)
		animate_levitate(O, -1, 50, random_side = FALSE)
		O.color = "#bd1335"
		animate_flash_color_fill_inherit(O,"#e13333",-1, 2 SECONDS)

	on_revert()
		var/datum/reagents/leaked
		teg.UpdateOverlays(null, "mask")
		UnregisterSignal(src.teg, COMSIG_ATOM_HITBY_PROJ)
		UnregisterSignal(src.teg, COMSIG_ATTACKBY)
		var/volume = src.teg.circ1.reagents.total_volume
		if(volume)
			leaked = src.teg.circ1.reagents.remove_any_to(volume)
			leaked.reaction(get_step(src.teg.circ1, SOUTH))
		volume = src.teg.circ2.reagents.total_volume
		if(volume)
			leaked = src.teg.circ2.reagents.remove_any_to(volume)
			leaked.reaction(get_step(src.teg.circ2, SOUTH))
		animate(src.teg)
		animate(src.teg.circ1)
		animate(src.teg.circ2)
		. = ..()

	on_grump()
		var/mob/living/carbon/human/H
		var/list/mob/living/carbon/targets = list()

		if(prob(50)) // Azrun LOWER THIS ZOMG
			for(var/mob/living/carbon/M in orange(5, teg))
				if(M.blood_volume >= 0 && !M.traitHolder.hasTrait("training_chaplain"))
					targets += M

		if(length(targets))
			if(prob(30))
				if( !ON_COOLDOWN(src.teg,"blood", 30 SECONDS) )
					playsound(src.teg, "sound/effects/blood.ogg", rand(10,20), 0, -1)

			var/mob/living/carbon/target = pick(targets)

			if(target in abilityHolder.ghouls)
				H = target
				if(	abilityHolder.points > 100 && target.blood_volume < 50 && !ON_COOLDOWN(src.teg,"heal", 120 SECONDS) )
					enthrall(H)
			else
				if(isalive(target))
					if( !ON_COOLDOWN(target,"teg_glare", 30 SECONDS) )
						glare(target)

					if(!abilities["Blood Steal"].actions.hasAction(src.teg, "vamp_blood_suck_ranged") && !ON_COOLDOWN(src.teg,"vamp_blood_suck_ranged", 10 SECONDS))
						actions.start(new/datum/action/bar/private/icon/vamp_ranged_blood_suc(src.teg,abilityHolder, target, abilities["Blood Steal"]), src.teg)

			if(ishuman(target))
				H = target
				if(isdead(H) && abilityHolder.points > 100 && !ON_COOLDOWN(src.teg,"enthrall",30 SECONDS))
					enthrall(H)

		if(prob(10))
			var/list/responses = list("I hunger! Bring us food so we may eat!", "Blood... I needs it.", "I HUNGER!", "Summon them here so we may feast!")
			say_ghoul(pick(responses))

		if(prob(20) && abilityHolder.points > 100)
			var/datum/reagents/reagents = pick(src.teg.circ1.reagents, src.teg.circ2.reagents)
			var/transfer_volume = clamp(reagents.maximum_volume - reagents.total_volume, 0, abilityHolder.points - 100)

			if(transfer_volume)
				transfer_volume = rand(0, transfer_volume)
				reagents.add_reagent("blood",transfer_volume)
				abilityHolder.deductPoints(transfer_volume)
				src.teg.grump -= 10
			else
				reagents.remove_any_to(100)
				make_cleanable(/obj/decal/cleanable/blood,get_step(src.teg, SOUTH))
				src.teg.efficiency_controller += 5
				SPAWN_DBG(45 SECONDS)
					if(src.teg?.active_form == src)
						src.teg?.efficiency_controller -= 5
		else
			switch(rand(1,3))
				if(1)
					var/list/stationAreas = get_accessible_station_areas()
					var/area/A = stationAreas[pick(stationAreas)]
					A?.area_apc?.emp_act()

		checkhealth()
		return TRUE

	proc/checkhealth()
		for(var/obj/machinery/atmospherics/binary/circulatorTemp/C in list(src.teg?.circ1,src.teg?.circ2))
			if(C.reagents)
				if(C.reagents.has_reagent("water_holy", 5))
					src.health -= 5
					C.reagents.remove_reagent("water_holy", 8)
					if (!(locate(/datum/effects/system/steam_spread) in C.loc))
						playsound(C.loc, "sound/effects/bubbles3.ogg", 80, 1, -3, pitch=0.7)
						var/datum/effects/system/steam_spread/steam = unpool(/datum/effects/system/steam_spread)
						steam.set_up(1, 0, get_turf(C))
						steam.attach(C)
						steam.start(clear_holder=1)

		if(health <= 0) // thou haft defeated the beast
			on_revert()

	proc/attackby(obj/T, obj/item/I as obj, mob/user as mob)
		var/force = I.force
		if(istype(I,/obj/item/storage/bible) && user.traitHolder.hasTrait("training_chaplain"))
			force = 60

		switch (force)
			if (0 to 19)
				force = force / 4
			if (20 to 39)
				force = force / 5
			if (40 to 59)
				force = force / 6
			if (60 to INFINITY)
				force = force / 7
		health -= force

	proc/projectile_collide(owner, obj/projectile/P)
		if (("vamp" in P.special_data))
			var/bitesize = 10
			var/mob/living/carbon/victim = P.special_data["victim"]
			var/datum/abilityHolder/vampire/vampire = P.special_data["vamp"]
			if (vampire == abilityHolder && P.max_range == PROJ_INFINITE_RANGE)
				P.travelled = 0
				P.max_range = 4
				P.special_data.len = 0 // clear special data so normal on_end() wont trigger
				vampire.vamp_blood += bitesize
				vampire.addPoints(bitesize)
				vampire.tally_bite(victim,bitesize)
				if (victim.blood_volume < bitesize)
					victim.blood_volume = 0
				else
					victim.blood_volume -= bitesize

	proc/say_ghoul(var/message)
		var/name = src.teg.name
		var/alt_name = " (VAMPIRE)"

		if (!message || !length(src.abilityHolder.ghouls) )
			return

		var/rendered = "<span class='game ghoulsay'><span class='prefix'>GHOULSPEAK:</span> <span class='name'>[name]<span class='text-normal'>[alt_name]</span></span> <span class='message'>[message]</span></span>"
		for (var/mob/M in src.abilityHolder.ghouls)
			boutput(M, rendered)

	proc/glare(mob/living/carbon/target)
		var/obj/O = src.teg
		if (!target || !ismob(target))
			return 1

		if (get_dist(src.teg, target) > 3)
			return 1

		if (isdead(target))
			return 1

		O.visible_message("<span class='alert'><B>[O] emits a blinding flash at [target]!</B></span>")
		var/obj/itemspecialeffect/glare/E = unpool(/obj/itemspecialeffect/glare)
		E.color = "#FFFFFF"
		E.setup(O.loc)
		playsound(O.loc,"sound/effects/glare.ogg", 50, 1, pitch = 1, extrarange = -4)

		SPAWN_DBG(1 DECI SECOND)
			var/obj/itemspecialeffect/glare/EE = unpool(/obj/itemspecialeffect/glare)
			EE.color = "#FFFFFF"
			EE.setup(target.loc)
			playsound(target.loc,"sound/effects/glare.ogg", 50, 1, pitch = 0.8, extrarange = -4)

		target.apply_flash(30, rand(1,5), stamina_damage = 350)

	proc/enthrall(mob/living/carbon/human/target)
		var/datum/abilityHolder/vampire/H = src.abilityHolder
		if(istype(target))
			if (!istype(target.mutantrace, /datum/mutantrace/vamp_zombie))
				if (!target.mind && !target.client)
					if (target.ghost && target.ghost.client && !(target.ghost.mind && target.ghost.mind.dnr))
						var/mob/dead/ghost = target.ghost
						ghost.show_text("<span class='red'>You feel yourself torn away from the afterlife and back into your body!</span>")
						if(ghost.mind)
							ghost.mind.transfer_to(target)
						else if (ghost.client)
							target.client = ghost.client
						else if (ghost.key)
							target.key = ghost.key

					else if (target.last_client) //if all fails, lets try this
						for (var/client/C in clients)
							if (C == target.last_client && C.mob && isobserver(C.mob))
								if(C.mob && C.mob.mind)
									C.mob.mind.transfer_to(target)
								else
									target.client = C
								break

				if (!target.client)
					return

				target.full_heal()

				target.real_name = "zombie [target.real_name]"
				if (target.mind)
					target.mind.special_role = "vampthrall"
					target.mind.master = src.teg
					if (!(target.mind in ticker.mode.Agimmicks))
						ticker.mode.Agimmicks += target.mind

				src.abilityHolder.ghouls += target

				target.set_mutantrace(/datum/mutantrace/vamp_zombie)
				var/datum/abilityHolder/vampiric_zombie/VZ = target.get_ability_holder(/datum/abilityHolder/vampiric_zombie)
				if (VZ && istype(VZ))
					VZ.master = H

				boutput(target, __red("<b>You awaken filled with purpose - you must serve your master \"vampire\", [src.teg]!</B>"))
				boutput(target, __red("<b>You are bound to the [src.teg]. It hungers for blood! You must be protect it and feed it!</B>"))
				SHOW_MINDSLAVE_TIPS(target)
			else
				target.full_heal()

			if (target in H.ghouls)
				//and add blood!
				var/datum/mutantrace/vamp_zombie/V = target.mutantrace
				if (V)
					V.blood_points += 200

				H.blood_tracking_output(100)
				H.deductPoints(100)