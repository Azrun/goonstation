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
		vampire
			material = "bone"

		birdbird
			name = "Squawk"

