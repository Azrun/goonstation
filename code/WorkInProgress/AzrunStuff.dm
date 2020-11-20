/datum/digital_filter
	var/list/a_coefficients //feedback (scalars for sumation of previous results)
	var/list/b_coefficients //feedforward (scalars for sumation of previous inputs)
	var/z_a[1]
	var/z_b[1]

	proc/init(list/feedback, list/feedforward)
		a_coefficients = feedback
		b_coefficients = feedforward
		z_a.len = length(a_coefficients)
		z_b.len = length(b_coefficients)

	proc/process(input)
		var/feedback_sum
		var/input_sum
		z_b[1] = input

		// Sum previous outputs
		for(var/i in 1 to length(src.a_coefficients))
			feedback_sum -= src.a_coefficients[i]*src.z_a[i]
			if(i>1) src.z_a[i] = src.z_a[i-1]

		// Sum inputs
		for(var/i in 1 to length(src.b_coefficients))
			input_sum += src.b_coefficients[i]*src.z_b[i]
			if(i>1) src.z_b[i] = src.z_b[i-1]
		. = feedback_sum + input_sum
		if(length(src.z_a)) src.z_a[1] = .

	window_average
		init(window_size)
			var/list/coeff_list = new()
			for(var/i in 1 to window_size)
				coeff_list += 1/window_size
			..(null, coeff_list)

	exponential_moving_average
		proc/init_basic(input_weight)
			var/input_weight_list[1]
			var/prev_output_weight_list[1]
			input_weight_list[1] = input_weight
			prev_output_weight_list[1] = -(1-input_weight)
			init(prev_output_weight_list,input_weight_list)

		proc/init_exponential_smoothing(sample_interval, time_const)
			init_basic(1.0 - ( eulers ** ( -sample_interval / time_const )))


/datum/teg_transformation_clock
	var/obj/machinery/power/generatorTemp/generator
	var/datum/teg_transformation/active_form
	var/static/list/possible_transformations

	New(teg)
		. = ..()
		generator = teg
		if(!possible_transformations)
			possible_transformations = list()
			for(var/T in childrentypesof(/datum/teg_transformation))
				var/datum/teg_transformation/TT = new T
				possible_transformations += TT

	disposing()
		. = ..()
		generator = null
		active_form = null

	proc/check_transformation()
		for(var/datum/teg_transformation/T as() in possible_transformations)
			if(active_form?.type == T.type) continue // Skip current form

			var/reagents_present = length(T.required_reagents)
			for(var/R as() in T.required_reagents)
				if( generator.circ1.reagents.get_reagent_amount(R) + generator.circ2.reagents.get_reagent_amount(R) >= T.required_reagents[R] )
				else
					reagents_present = FALSE
					break

			if(reagents_present)
				// Azrun TODO Remove reagents from circulator reagents

				// Azrun TODO Spawn delay transformation to allow for animations, audio, and such to play
				if(active_form)
					active_form.on_revert()
				active_form = new T.type
				active_form.on_transform(generator)
				return

ABSTRACT_TYPE(/datum/teg_transformation)
datum
	teg_transformation
		var/name = null
		var/id = null
		var/audio_clip
		var/visible_msg
		var/audible_msg
		var/teg_overlay
		var/circulator_overlay
		var/material
		var/list/required_reagents
		var/obj/machinery/power/generatorTemp/teg

		proc/on_grump()
			return FALSE

		proc/on_transform(obj/machinery/power/generatorTemp/teg)
			src.teg = teg
			if(src.material)
				teg.setMaterial(src.material)
				teg.circ1.setMaterial(src.material)
				teg.circ2.setMaterial(src.material)
			return

		proc/on_revert()
			src.teg.setMaterial(initial(src.material))
			src.teg.circ1.setMaterial(initial(src.material))
			src.teg.circ2.setMaterial(initial(src.material))
			qdel(src.teg.variant_clock.active_form)
			src.teg.variant_clock.active_form = null
			return

		default
			name = "Default"
			material = "steel"

		flock
			material = "gnesis"
			//material = "gnesisglass"
			required_reagents = list("flockdrone_fluid" = 10)
			var/obj/flock_structure/collector/teg/flock_gen
			var/bit_count = 0

			on_transform(obj/machinery/power/generatorTemp/teg)
				. = ..()
				// Azrun TODO Add cool flock sounds!
				flock_convert_turf(get_turf(teg.loc))
				SPAWN_DBG(0)
					radial_flock_conversion(flock_gen, 3)

				var/flock_to_join
				if(length(flocks))
					flock_to_join = pick(flocks)
				flock_gen = new(teg.loc, flock_to_join)
				flock_gen.assign_generator(teg)

				// Variant ONLY active while resource collector is present, revert if destroyed
				RegisterSignal(flock_gen, COMSIG_PARENT_PRE_DISPOSING, .proc/on_revert)

			on_revert()
				. = ..()
				// Azrun TODO Add sad flock sounds!
				qdel(flock_gen)
				flock_gen = null

			on_grump()
				if(!flock_gen)
					src.on_revert()
					return
				var/list/ejectables = list()

				if( bit_count ) // We have produced a flock bit, spew forth flockdrone fluid
					var/obj/decal/cleanable/flockdrone_debris/fluid/D
					for(var/datum/reagents/reagents in list(src.teg.circ1.reagents,src.teg.circ2.reagents))
						if(!reagents.total_volume) continue
						var/fluid_amount = reagents.get_reagent_amount("flockdrone_fluid")
						if(fluid_amount < 20) continue
						fluid_amount = min(reagents.get_reagent_amount("flockdrone_fluid"), 20)

						reagents.remove_reagent("flockdrone_fluid", fluid_amount)
						D = new /obj/decal/cleanable/flockdrone_debris/fluid()
						D.anchored = 0 //Unanchor the fluid so we can eject it
						ejectables += D
						break

				if(src.teg.grump > 100 && prob(10))
					// Decreases likelyhood of getting flock bits as more bits generated
					if(src.teg.lastgenlev > 10 && prob(clamp(100-(bit_count*20),2,95)))
						var/mob/living/critter/flock/bit/B
						B = new(F=flock_gen.flock)
						ejectables += B
						bit_count++
						src.teg.grump -= 100

					if(prob(50))
						var/cube_cnt = rand(0,2)
						for(var/i=1, i<cube_cnt, i++) //here im using the flockdronegibs proc to handle throwing things out randomly. in these for loops im just creating the objects (resource caches and flockdrone eggs) and adding them to the list (eject) which will get thrown about
							var/obj/item/flockcache/x = new(flock_gen.contents)
							x.resources = rand(1, clamp(src.teg.lastgenlev/4, 2, 50))
							ejectables += x
							src.teg.grump -= x.resources

				if(length(ejectables))
					handle_ejectables(teg.loc, ejectables)
				if(D)
					// Reachor fluid if it was ejected
					D.anchored = TRUE
					if(D.loc == teg.loc) qdel(D)

				return TRUE

		vampire
			material = "bone"

		birdbird
			name = "Squawk"


/obj/flock_structure/collector/teg
	var/obj/machinery/power/generatorTemp/teg
	health = 90

	proc/assign_generator(obj/machinery/power/generatorTemp/generator)
		teg = generator

	//Azrun TODO Add on_attack to electricute based on TEG power

	process()
		. = ..()
		src.poweruse -= clamp(teg.lastgenlev/4, 1, 50)

