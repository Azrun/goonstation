/// The following is based on GenerateMining.dm

var/planetZLevel = null
var/list/planetModifiers = list()
var/list/planetModifiersUsed = list()//Assoc list, type:times used
var/list/planet_seeds = list()

#if ENABLE_ARTEMIS
/proc/makePlanetLevel()
	//var/list/turf/planetZ = list()
	var/startTime = world.timeofday
	if(!planetZLevel)
		boutput(world, "<span class='alert'>Skipping Planet Generation!</span>")
		return
	else
		boutput(world, "<span class='alert'>Generating Planet Level ...</span>")

	// SEED zee Planets!!!!
	for(var/area/map_gen/planet/A in by_type[/area/map_gen])
		if(!planet_seeds[A.name])
			planet_seeds[A.name] = list("height"=GALAXY.Rand.xor_rand(1,50000), "humidity"=GALAXY.Rand.xor_rand(1,50000), "heat"=GALAXY.Rand.xor_rand(1,50000))

		var/seed = planet_seeds[A.name]
		A.generate_perlin_noise_terrain(list(seed["height"], seed["humidity"], seed["heat"]))

		if(A.allow_prefab)
			var/list/area_turfs = get_area_turfs(A)
			var/num_to_place = PLANET_NUMPREFABS + GALAXY.Rand.xor_rand(0, PLANET_NUMPREFABSEXTRA)
			for (var/n = 1, n <= num_to_place, n++)
				game_start_countdown?.update_status("Setting up planet level...\n(Prefab [n]/[num_to_place])")
				var/datum/generatorPlanetPrefab/M = pickPlanetPrefab()
				if (M)
					var/maxX = (world.maxx - M.prefabSizeX - PLANET_MAPBORDER)
					var/maxY = (world.maxy - M.prefabSizeY - PLANET_MAPBORDER)
					var/stop = 0
					var/count= 0
					var/maxTries = (M.required ? 200 : 33)
					while (!stop && count < maxTries) //Kinda brute forcing it. Dumb but whatever.
						var/turf/target = locate(GALAXY.Rand.xor_rand(1+PLANET_MAPBORDER, maxX), GALAXY.Rand.xor_rand(1+PLANET_MAPBORDER,maxY), planetZLevel)
						target = GALAXY.Rand.xor_pick(area_turfs)
						//var/area/A = get_area(target)
						var/ret = M.applyTo(target)
						if (!ret)
							logTheThing("debug", null, null, "Prefab placement #[n] [M.type] failed due to blocked area. [target] @ [showCoords(target.x, target.y, target.z)]")
						else
							logTheThing("debug", null, null, "Prefab placement #[n] [M.type][M.required?" (REQUIRED)":""] succeeded. [target] @ [showCoords(target.x, target.y, target.z)]")
							stop = 1
							if(istype(A,/area/map_gen/planet))
								var/area/map_gen/planet/P = A
								P.prefabs |= ret
						count++
						if (count >= 33)
							logTheThing("debug", null, null, "Prefab placement #[n] [M.type] failed due to maximum tries [maxTries][M.required?" WARNING: REQUIRED FAILED":""]. [target] @ [showCoords(target.x, target.y, target.z)]")
				else break

	for(var/area/map_gen/planet/A in by_type[/area/map_gen])
		if(!A.allow_prefab)
			var/area/map_gen/planet/parent_area = get_area_by_type(A.parent_type)
			parent_area.biome_turfs += A.biome_turfs
			parent_area.overlays += A.overlays
			for(var/turf/T in A)
				new parent_area.type(T)
		else
			for(var/datum/loadedProperties/prefab in A.prefabs)
				var/list/turf/prefab_turfs = block(locate(prefab.sourceX, prefab.sourceY, prefab.sourceZ),locate(prefab.maxX, prefab.maxY, prefab.maxZ))
				var/list/turf/regen_turfs = list()
				for(var/turf/variableTurf/T in prefab_turfs)
					regen_turfs += T
					if(istype(T.loc, /area/space)) //space...
						new A.type(T)
				if(length(regen_turfs))
					A.map_generator.generate_terrain(regen_turfs, reuse_seed=TRUE)

	// // remove temporary areas
	var/area/A
	var/turf/AT
	var/turf/west_turf
	for (AT in get_area_turfs(/area/noGenerate))
		if(AT.z != planetZLevel) continue
		if(!istype(AT, /turf/space)) continue
		west_turf = get_step(AT, WEST)
		while(west_turf.x > 0)
			if(istype(west_turf.loc, /area/map_gen/planet))
				break

			west_turf = get_step(west_turf, WEST)
		A = get_area(west_turf)
		new A.type(AT)

	for (AT in get_area_turfs(/area/allowGenerate))
		if(AT.z != planetZLevel) continue
		if(!istype(AT, /turf/space) && !istype(AT, /turf/map_gen)) continue
		west_turf = get_step(AT, WEST)
		while(west_turf.x > 0)
			if(istype(west_turf.loc, /area/map_gen/planet))
				break

			west_turf = get_step(west_turf, WEST)
		A = get_area(west_turf)
		new A.type(AT)

	boutput(world, "<span class='alert'>Generated Planet Level in [((world.timeofday - startTime)/10)] seconds!")

/proc/pickPlanetPrefab()
	var/list/eligible = list()
	var/list/required = list()

	for(var/datum/generatorPlanetPrefab/M in planetModifiers)
		if(M.type in planetModifiersUsed)
			if(M.required) continue
			if(M.maxNum != -1)
				if(planetModifiersUsed[M.type] >= M.maxNum)
					continue
				else
					eligible.Add(M)
					eligible[M] = M.probability
			else
				eligible.Add(M)
				eligible[M] = M.probability
		else
			eligible.Add(M)
			eligible[M] = M.probability
			if(M.required) required.Add(M)

	if(required.len)
		var/datum/generatorPlanetPrefab/P = required[1]
		planetModifiersUsed.Add(P.type)
		planetModifiersUsed[P.type] = 1
		return P
	else
		if(eligible.len)
			var/datum/generatorPlanetPrefab/P = GALAXY.Rand.xor_weighted_pick(eligible)
			if(P.type in planetModifiersUsed)
				planetModifiersUsed[P.type] = (planetModifiersUsed[P.type] + 1)
			else
				planetModifiersUsed.Add(P.type)
				planetModifiersUsed[P.type] = 1
			return P
		else return null

#define DEFINE_PLANET(_PATH, _NAME) \
	/area/map_gen/planet/_PATH{name=_NAME};\
	/area/map_gen/planet/_PATH/no_prefab{allow_prefab = FALSE};

/area/map_gen/planet
	name = "planet generation area"
	var/map_generator_path = /datum/map_generator/jungle_generator
	var/list/turf/biome_turfs = list()
	var/list/datum/loadedProperties/prefabs = list()
	var/allow_prefab = TRUE
	var/generated = FALSE

	generate_perlin_noise_terrain(list/seed_list)
		if(generated)
			return
		if(src.map_generator_path)
			map_generator = new map_generator_path()
		if(seed_list)
			map_generator.set_seed(seed_list)
		map_generator.generate_terrain(get_area_turfs(src), reuse_seed=TRUE)
		generated = TRUE

	proc/colorize_planet(color)
		src.ambient_light = color
		if(src.ambient_light)
			var/image/I = new /image/ambient
			I.color = src.ambient_light
			overlays += I

	store_biome(turf/T, datum/biome/B)
		if(!biome_turfs[B])
			biome_turfs[B] = list()
		biome_turfs[B] |= T

	proc/clear_biomes()
		biome_turfs = list()

DEFINE_PLANET(alpha, "Alpha")
DEFINE_PLANET(beta, "Beta")
DEFINE_PLANET(charlie, "Charlie")
DEFINE_PLANET(delta, "Delta")
DEFINE_PLANET(echo, "Echo")
DEFINE_PLANET(foxtrot, "Foxtrot")
DEFINE_PLANET(gamma, "Gamma")
DEFINE_PLANET(hotel, "Hotel")
DEFINE_PLANET(indigo, "Indigo")

ABSTRACT_TYPE(/datum/generatorPlanetPrefab)
/datum/generatorPlanetPrefab
	var/probability = 0
	var/maxNum = 0
	var/prefabPath = ""
	var/prefabSizeX = 5
	var/prefabSizeY = 5
	var/required = 0   //If 1 we will try to always place thing thing no matter what. Required prefabs will only ever be placed once.
	var/std_prefab_path
	var/underwater
	var/list/required_biomes // ensure area has these biomes somewhere...

	proc/applyTo(var/turf/target)
		var/adjustX = target.x
		var/adjustY = target.y

		 //Move prefabs backwards if they would end up outside the map.
		if((adjustX + prefabSizeX) > (world.maxx - PLANET_MAPBORDER))
			adjustX -= ((adjustX + prefabSizeX) - (world.maxx - PLANET_MAPBORDER))

		if((adjustY + prefabSizeY) > (world.maxy - PLANET_MAPBORDER))
			adjustY -= ((adjustY + prefabSizeY) - (world.maxy - PLANET_MAPBORDER))

		var/turf/T = locate(adjustX, adjustY, target.z)

		if(!check_biome_requirements(T))
			return

		for(var/x=0, x<prefabSizeX; x++)
			for(var/y=0, y<prefabSizeY; y++)
				var/turf/L = locate(T.x+x, T.y+y, T.z)

				var/area/map_gen/planet/P = get_area(L)
				if(L?.loc && !(istype(P) && P.allow_prefab))
					return
				if(T.density)
					return

		var/area_type = get_area(T)
		var/loaded = file2text(prefabPath)
		if(T && loaded)
			var/dmm_suite/D = new/dmm_suite()
			var/datum/loadedProperties/props = D.read_map(loaded, T.x, T.y, T.z, prefabPath, DMM_OVERWRITE_MOBS | DMM_OVERWRITE_OBJS)
			if(prefabSizeX != props.maxX - props.sourceX + 1 || prefabSizeY != props.maxY - props.sourceY + 1)
				CRASH("size of prefab [prefabPath] is incorrect ([prefabSizeX]x[prefabSizeY] != [props.maxX - props.sourceX + 1]x[props.maxY - props.sourceY + 1])")
			convertSpace(T, prefabSizeX, prefabSizeY, area_type)
			return props
		else return

	proc/check_biome_requirements(turf/T)
		. = TRUE
		var/area/map_gen/planet/A = get_area(T)
		if(length(required_biomes) && istype(A))
			for(var/biome in A.biome_turfs)
				if(!(biome in required_biomes))
					. = FALSE
					break

	proc/convertSpace(turf/start, prefabSizeX, prefabSizeY, area/prev_area)
		//var/list/areas_to_revert = list(/area/noGenerate, /area/allowGenerate)
		var/child_path = "[prev_area.type]/no_prefab"
		var/list/turf/turfs = block(locate(start.x, start.y, start.z), locate(start.x+prefabSizeX-1, start.y+prefabSizeY-1, start.z))
		for(var/turf/T in turfs)
			//if( T.loc.type in areas_to_revert)
			if(istype(T.loc, /area/noGenerate))
				new child_path(T)
			else if(istype(T.loc, /area/allowGenerate))
				new prev_area.type(T)


	tomb // small little tomb
		maxNum = 1
		probability = 20
		prefabPath = "assets/maps/prefabs/prefab_tomb.dmm"
		prefabSizeX = 13
		prefabSizeY = 10

	vault
		maxNum = 1
		probability = 25
		prefabPath = "assets/maps/prefabs/prefab_vault.dmm"
		prefabSizeX = 7
		prefabSizeY = 7

	bear_trap
		maxNum = 1
		probability = 25
		prefabPath = "assets/maps/prefabs/prefab_planet_bear_den.dmm"
		prefabSizeX = 15
		prefabSizeY = 15

	tomato_den
		maxNum = 1
		probability = 25
		prefabPath = "assets/maps/prefabs/prefab_planet_tomato_den.dmm"
		prefabSizeX = 13
		prefabSizeY = 10

	corn_n_weed
		maxNum = 1
		probability = 25
		prefabPath = "assets/maps/prefabs/prefab_corn_and_weed.dmm"
		prefabSizeX = 15
		prefabSizeY = 16

	organic_organs
		maxNum = 1
		probability = 25
		prefabPath = "assets/maps/prefabs/prefab_organic_organs.dmm"
		prefabSizeX = 15
		prefabSizeY = 15


/obj/landmark/artemis_planets
	name = "zlevel"
	icon_state = "x3"
	add_to_landmarks = FALSE

	init()
		if(!planetZLevel)
			planetZLevel = src.z
		..()
#endif
