#ifdef ENABLE_ARTEMIS
/datum/galactic_object/planet/random
	name = "Randomized Planet"
	body_path_map = /obj/background_star/galactic_object/planet/random
	body_path_ship = /obj/background_star/galactic_object/planet/large/random
	sector = "A"
	navigable = 1
	var/color = null
	var/destination_name = null
	var/icon_state = null

	New(datum/galaxy/G)
		galactic_x = rand()*2+1 //19?
		galactic_y = rand()*2+1 //19?
		scale = rand()*0.5+ 0.75
		color = pick("#fffb00", "#FF5D06", "#009ae7", "#03c53d", "#9b59b6", "#272e30", "#FF69B4", "#633221", "#ffffff")
		icon_state = weighted_pick(list("planet_1"=10,"planet_2"=3,"planet_3"=2))

		if(prob(10))
			navigable = 0

		if(G && length(G.available_planets))
			destination_name = pick(G.available_planets)
			G.available_planets -= destination_name

			SPAWN_DBG(1 SECOND)
				for(var/turf/T in landmarks[LANDMARK_PLANETS])
					if(landmarks[LANDMARK_PLANETS][T] == src.destination_name)
						var/area/map_gen/planet/A = get_area(T)
						var/r = hex2num(copytext(color, 2, 4))
						var/g = hex2num(copytext(color, 4, 6))
						var/b = hex2num(copytext(color, 6))
						var/hsv = rgb2hsv(r,g,b)
						var/value = clamp((log(rand())*0.675)+0.997,0,1)
						A.colorize_planet(hsv2rgb( hsv[1], hsv[2], value*100 ))
						break

		generate_name()
		..()


	proc/generate_name()
		. = ""
		if (prob(50))
			. += pick_string("station_name.txt", "greek")
		else
			. += pick_string("station_name.txt", "militaryLetters")
		. += " "

		if (prob(30))
			. += pick_string("station_name.txt", "romanNum")
		else
			. += "[rand(2, 99)]"

		src.name = .

/obj/background_star/galactic_object/planet/random
	name = "F1X-M3"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
	icon_state = "planet_1"

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/dat = {"<span class='alert'><b>DON'T <i>FUCKING</i> TOUCH ME.</b></span>"}

		var/turf_total = 0
		var/list/biome_distro = list("Jungle"=0, "Grassland"=0, "Desert"=0, "Mountains"=0, "Water"=0, "Other"=0)
		var/key
		if(src.my_ship_body?.landing_zones)
			var/area/map_gen/planet/A = get_area(src.my_ship_body.landing_zones[1])
			var/biome_name
			for(key in A.biome_turfs)
				turf_total += length(A.biome_turfs[key])
				biome_name = "Other"
				switch(key)
					if(/datum/biome/jungle)
						biome_name="Jungle"
					if(/datum/biome/jungle/deep)
						biome_name="Jungle"
					if(/datum/biome/wasteland)
						biome_name="Desert"
					if(/datum/biome/mountain)
						biome_name="Mountains"
					if(/datum/biome/water)
						biome_name="Water"
					if(/datum/biome/plains)
						biome_name="Grassland"
				biome_distro[biome_name] += length(A.biome_turfs[key])
		else
			//PsuedoRandom Generation Based on Galactic X/Y so reproducable
			for(var/i in 1 to 15)
				if(round(src.master.galactic_y) % i == 0) continue
				key = biome_distro[round((src.master.galactic_x * i) % length(biome_distro))+ 1]
				biome_distro[key] += abs(src.master.galactic_x)
				turf_total += abs(src.master.galactic_x)
			for(var/i in 1 to 15)
				if(round(src.master.galactic_x) % i == 0) continue
				key = biome_distro[round((src.master.galactic_y * i) % length(biome_distro))+ 1]
				biome_distro[key] += abs(src.master.galactic_y)
				turf_total += abs(src.master.galactic_y)

		for(key in biome_distro)
			biome_distro[key] = round(biome_distro[key]/turf_total*100)
			. += "<BR/>"
			if(biome_distro[key] >= 5)
				. += "[key]: [biome_distro[key]]%"
			else
				. += "[key]: <5%"

		pilot << browse("<HEAD><TITLE>[name]</TITLE></HEAD><TT>[dat][.]</TT>", "window=artemis_scan")

		return

	on_load()
		var/datum/galactic_object/planet/random/R = master
		color = R.color
		name = R.name
		icon_state = R.icon_state
		if(scale)
			REMOVE_FLAG(appearance_flags, PIXEL_SCALE)


/obj/background_star/galactic_object/planet/large/random
	name = "F1X-M3"
	icon = 'icons/misc/artemis/galactic_object_ship.dmi'
	icon_state = "generic"
	destination_name = "3rr0r"

	on_load()
		var/datum/galactic_object/planet/random/R = master
		destination_name = R.destination_name
		color = R.color
		name = R.name
		icon_state = R.icon_state

// Space Station / Abzu

/datum/galactic_object/station
	name = "SS13"
	body_path_map = /obj/background_star/galactic_object/station
	body_path_ship = /obj/background_star/galactic_object/large/station
	sector = "A"
	navigable = 1
	galactic_x = 0.01
	galactic_y = 0.05

/obj/background_star/galactic_object/station
	name = "SS13"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
#ifdef UNDERWATER_MAP
	icon_state = "abzu"
#else
	icon_state = "station"
#endif

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/dat = {"<span class='alert'><b>Home sweet home.  For some definition of sweet and some definition of home.</b></span>"}

		pilot << browse("<HEAD><TITLE>[station_name()]</TITLE></HEAD><TT>[dat]</TT>", "window=artemis_scan")

		return

/obj/background_star/galactic_object/large/station
	icon = 'icons/misc/artemis/galactic_object_ship.dmi'
	icon_state = "station"

	New()
		..()
		for_by_tcl(L, /obj/lrteleporter)
			if(L.z == Z_LEVEL_STATION)
				if(!src.landing_zones) src.landing_zones = list()
				src.landing_zones["SS13"] = get_turf(L)
				return

	on_load()
		var/datum/galactic_object/R = master
		destination_name = R.name

// Stars

/datum/galactic_object/star
	name = "Star"
	body_path_map = /obj/background_star/galactic_object/star
	body_path_ship = /obj/background_star/galactic_object/large/star
	sector = "A"
	navigable = 0
	galactic_x = 0.2
	galactic_y = 0.05

	random
		body_path_map = /obj/background_star/galactic_object/star/random
		body_path_ship = /obj/background_star/galactic_object/large/star/random
		var/color = null

		New()
			galactic_x = rand()*2-1 //19?
			galactic_y = rand()*2-1 //19?
			scale = rand()*0.5+ 0.90
			color = pick("#fffb00", "#FF5D06", "#009ae7", "#9b59b6", "#FF69B4", "#ffffff")
			..()

/obj/background_star/galactic_object/star
	name = "Star"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
	icon_state = "star"

	New()
		..()
		//animate_wave(src, 1)
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/dat = {"<span class='alert'><b>Hot Hot Hot Hot Hot Hot</b></span>"}

		pilot << browse("<HEAD><TITLE>Star</TITLE></HEAD><TT>[dat]</TT>", "window=artemis_scan")

		return

	animate_stars()
		..()
		// This is where black hole shit should happen... suck 'em in... and SPIT 'em out
		var/datum/galactic_object/G = master
		if(src.has_ship_body && G)
			var/squared_pixel_distance = ((src.actual_x)**2 + (src.actual_y)**2)
			var/obj/artemis/ship = src.my_ship

			if(squared_pixel_distance < 32)
				if(!ON_COOLDOWN(src.my_ship, "hot_star", 5 SECONDS))
					SPAWN_DBG(0)
						var/area = get_area(src.my_ship.controls)
						for(var/mob/M in area)
							M.temperature_expose(null, 5778, CELL_VOLUME)
							if(isliving(M))
								var/mob/living/H = M
								H.update_burning(5)
			else if(squared_pixel_distance < 2600 )
				var/theta = arctan(src.actual_y, src.actual_x)
				theta += ship.ship_angle
				var/gravity = lerp(0.75,0.25,squared_pixel_distance/2600)
				var/new_mag = sqrt(max(ship.vel_mag**2 + gravity**2 + 2*ship.vel_mag*gravity*cos(theta-ship.vel_angle),1)) // avoid sqrt(0)
				new_mag = min(ship.max_speed,new_mag)
				var/arctan_result
				if(new_mag) //check for div/0
					arctan_result = (theta == ship.vel_angle) ? 0 : arctan(((gravity*sin(theta-ship.vel_angle))/(ship.vel_mag + gravity*cos(theta-ship.vel_angle))))
				var/new_angle = ship.vel_angle + arctan_result
				ship.vel_mag = new_mag
				ship.vel_angle = new_angle
				ship.update_my_stuff()

	random
		on_load()
			var/datum/galactic_object/star/random/R = master
			color = R.color
			name = R.name
			if(scale)
				REMOVE_FLAG(appearance_flags, PIXEL_SCALE)

/obj/background_star/galactic_object/large/star
	name = "Star"
	icon = 'icons/misc/artemis/galactic_object_ship.dmi'
	icon_state = "star"

	New()
		..()
		//animate_wave(src, 2)

	animate_stars()
		..()

	Crossed(O)
		. = ..()
		if (isliving(O))
			var/mob/living/M = O
			if (!M.is_heat_resistant())
				SPAWN_DBG(1 SECOND)
					M.visible_message("<span class='alert'><b>[M]</b> burns away into ash! Stars are quite warm!</span>",\
					"<span class='alert'><b>You burn away into ash! Stars are hot afterall!</b></span>")
					M.firegib()

	random
		on_load()
			var/datum/galactic_object/star/random/R = master
			color = R.color
			name = R.name

// Black Hole

/datum/galactic_object/bhole
	name = "Star"
	body_path_map = /obj/background_star/galactic_object/bhole
	body_path_ship = /obj/background_star/galactic_object/large/bhole
	sector = "A"
	navigable = 1
	galactic_x = -0.2
	galactic_y = 0.2

/obj/background_star/galactic_object/bhole
	name = "Black Hole"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
	icon_state = "bhole"

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/dat = {"<span class='alert'><b>Oh... look... a black hole.  Neat!</b></span>"}

		pilot << browse("<HEAD><TITLE>Star</TITLE></HEAD><TT>[dat]</TT>", "window=artemis_scan")

		return

	animate_stars()
		..()

		// This is where black hole shit should happen... suck 'em in... and SPIT 'em out
		var/datum/galactic_object/G = master
		if(src.has_ship_body && G)
			var/squared_pixel_distance = ((src.actual_x)**2 + (src.actual_y)**2)
			var/obj/artemis/ship = src.my_ship

			if(squared_pixel_distance < 32)
				if(!ON_COOLDOWN(src.my_ship, "blackhole", 5 SECONDS))
					SPAWN_DBG(0)
						var/old_mag = ship.vel_mag
						var/old_angle = ship.vel_angle
						ship.engine_ok = FALSE
						ship.vel_mag = 300
						ship.vel_angle += rand()*90 - (45)
						ship.accelerating = 1
						ship.update_my_stuff()
						sleep(5 SECONDS)
						ship.vel_mag = old_mag * 2
						ship.vel_angle = old_angle
						ship.update_my_stuff()
						sleep(2 SECONDS)
						ship.accelerating = 0
						ship.engine_ok = TRUE
			else if(squared_pixel_distance < 2600 ) //1600
				var/theta = arctan(src.actual_y, src.actual_x)
				theta += ship.ship_angle
				var/gravity = lerp(0.75,0.25,squared_pixel_distance/2600)
				var/new_mag = sqrt(ship.vel_mag**2 + gravity**2 + 2*ship.vel_mag*gravity*cos(theta-ship.vel_angle))
				new_mag = min(ship.max_speed,new_mag)
				var/arctan_result
				if(new_mag) //check for div/0
					arctan_result = (theta == ship.vel_angle) ? 0 : arctan(((gravity*sin(theta-ship.vel_angle))/(ship.vel_mag + gravity*cos(theta-ship.vel_angle))))
				var/new_angle = ship.vel_angle + arctan_result
				ship.vel_mag = new_mag
				ship.vel_angle = new_angle
				ship.update_my_stuff()

/obj/background_star/galactic_object/large/bhole
	name = "Black Hole"
	icon = 'icons/misc/artemis/galactic_object_ship.dmi'
	icon_state = "bhole"

// Asteroid

/datum/galactic_object/asteroid
	name = "Asteroid"
	body_path_map = /obj/background_star/galactic_object/asteroid
	body_path_ship = /obj/background_star/galactic_object/large/asteroid
	galactic_x = 0.5
	galactic_y = 0.5
	sector = "A"
	navigable = 1  // FALSE
	var/datum/mining_encounter/MC
	var/rarity_mod = 0
	var/encounter_generated = FALSE
	var/obj/magnet_target_marker/asteroid/marker
	var/variant

/obj/background_star/galactic_object/asteroid
	name = "Asteroid"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
	icon_state = "ast_group_1"

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/datum/galactic_object/asteroid/M = master
		var/dat = {"<span class='alert'><b>Softest of Rocks</b></span>"}

		// TODO Action-Bar for Mining Scan.... ???
		if(!M.encounter_generated)
			generate_mining_asteroid()

		// Need to Install Mining Scanner..... ???
		if(pilot && M.marker && M.encounter_generated)
			mining_scan(M.marker.magnetic_center, pilot, M.marker.scan_range)

		pilot << browse("<HEAD><TITLE>Asteroid</TITLE></HEAD><TT>[dat]</TT>", "window=fixme_planet")

		return

	proc/generate_mining_asteroid()
		var/datum/galactic_object/asteroid/M = master

		if(!M.MC)
			M.MC = mining_controls.select_encounter(M.rarity_mod)

		if(!M.marker)
			M.marker = GALAXY.asteroids.get_available_marker()

		if(M.MC && M.marker)
			M.MC.generate(M.marker)
			M.encounter_generated = TRUE
			if(my_ship_body)
				var/obj/background_star/galactic_object/large/asteroid/A = my_ship_body
				A.set_destination()
		else
			boutput(usr, "Uh oh, something's gotten really fucked up with the asteroid system. Please report this to a coder! (ERROR: NO ENCOUNTER)")

	on_unload()
		var/datum/galactic_object/asteroid/M = master
		if(M.marker && !M.marker.check_for_unacceptable_content())
			GALAXY.asteroids.return_marker(M.marker)
			M.MC = null
			M.marker = null

/obj/background_star/galactic_object/large/asteroid
	name = "Asteroid"
	icon = 'icons/misc/galactic_objects_large.dmi'
	icon_state = "generic"
	destination_name = "Asteroid"

	on_load()
		..()
		set_destination()

	proc/set_destination()
		var/datum/galactic_object/asteroid/M = master
		if(!M.marker) return
		if(M.encounter_generated)
			for(var/turf/T in landmarks[LANDMARK_PLANETS])
				if(landmarks[LANDMARK_PLANETS][T] == M.marker.name)
					if(!landing_zones) landing_zones = list()
					src.landing_zones["Asteroid"] = T
					T.ReplaceWith(/turf/simulated/floor/plating/airless/asteroid, FALSE, TRUE, FALSE, TRUE)


/datum/galactic_object/test
	name = "F1X-M3"
	body_path_map = /obj/background_star/galactic_object/test
	body_path_ship = /obj/background_star/galactic_object/large/test
	galactic_x = 10
	galactic_y = 20
	sector = "A"
	navigable = 1

/obj/background_star/galactic_object/test
	name = "F1X-M3"
	icon = 'icons/misc/galactic_objects.dmi'
	icon_state = "generic"

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		var/dat = {"<span class='alert'><b>DON'T <i>FUCKING</i> TOUCH ME.</b></span>"}

		pilot << browse("<HEAD><TITLE>HEY FUCKWAD!</TITLE></HEAD><TT>[dat]</TT>", "window=fixme_planet")

		animate(src, transform = matrix()*2, alpha = 0, time = 5)
		animate(src, transform = matrix(), alpha = 255, time = 5)
		return

/obj/background_star/galactic_object/large/test
	name = "F1X-M3"
	icon = 'icons/misc/galactic_objects_large.dmi'
	icon_state = "generic"
	destination_name = "F1X-M3"

/datum/galactic_object/eyesenhower
	name = "eyesenhower"
	//loud = 1
	body_path_map = /obj/background_star/galactic_object/eyesenhower_map
	body_path_ship = /obj/background_star/galactic_object/large/eyesenhower_ship
	galactic_x = 0
	galactic_y = 20
	sector = "A"
	navigable = 1
	var/intro_played = 0

/obj/background_star/galactic_object/eyesenhower_map
	name = "Eyesenhower"
	icon = 'icons/misc/artemis/galactic_object_map.dmi'
	icon_state = "eh_idle_closed"

	New()
		..()
		flags |= HAS_ARTEMIS_SCAN

	on_load()
		//src.icon_state = "eh_moon_idle"
		//src.overlays += src
		src.overlays += icon('icons/misc/artemis/galactic_object_map.dmi',"eh_moon_idle")
		var/datum/galactic_object/eyesenhower/E = master
		if(!istype(E))
			return
		if(E.intro_played)
			src.icon_state = "eh_idle_open"
		else
			src.icon_state = "eh_idle_closed"

	artemis_scan(var/mob/pilot, var/obj/artemis/ship)
		boutput(pilot,"fuck")
		flick("arjuna_thruster_back_l",ship)
		return

/obj/background_star/galactic_object/large/eyesenhower_ship
	name = "Eyesenhower"
	icon = 'icons/misc/artemis/galactic_object_ship.dmi'
	icon_state = "eyesenhower"

	on_load()
		var/datum/galactic_object/eyesenhower/E = master
		if(!istype(E))
			return
		if(!E.intro_played)
			flick("eh_intro",src.my_map_body)
			E.intro_played = 1
			src.my_map_body.icon_state = "eh_idle_open"

#endif
