var/datum/event_controller/random_events

/datum/event_controller
	var/events_enabled = TRUE
	var/announce_events = TRUE

	var/list/major_events = list()
	var/major_events_begin = 30 MINUTES // 30m
	var/time_between_major_events_lower = 11 MINUTES  // 11m
	var/time_between_major_events_upper = 20 MINUTES // 20m
	var/major_events_enabled = TRUE
	var/major_event_cycle_count = 0

	var/list/minor_events = list()
	var/minor_events_begin = 10 MINUTES // 10m
	var/time_between_minor_events_lower = 400 SECONDS // roughly 8m
	var/time_between_minor_events_upper = 800 SECONDS // roughly 14m
	var/minor_events_enabled = TRUE
	var/minor_event_cycle_count = 0

	var/list/antag_spawn_events = list()
#ifdef RP_MODE
	var/alive_antags_threshold = 0.04
#else
	var/alive_antags_threshold = 0.1
#endif
	var/list/player_spawn_events = list()
	var/dead_players_threshold = 0.3
	var/spawn_events_begin = 23 MINUTES
	var/time_between_spawn_events_lower = 8 MINUTES
	var/time_between_spawn_events_upper = 12 MINUTES

	var/major_event_timer = 0
	var/minor_event_timer = 0

	var/next_major_event = 0
	var/next_minor_event = 0
	var/next_spawn_event = 0

	var/time_lock = 1
	var/list/special_events = list()
	var/minimum_population = 15 // Minimum amount of players connected for event to occur

	var/datum/storyteller/active_storyteller

	var/list/queued_events

	var/start_events_enabled = FALSE
	var/list/start_events = list()
	var/list/datum/random_event/delayed_start = list()

	New()
		..()

		for (var/X in concrete_typesof(/datum/random_event/major))
			var/datum/random_event/RE = new X
			major_events += RE

		for (var/X in concrete_typesof(/datum/random_event/major/antag)+concrete_typesof(/datum/random_event/major/player_spawn/antag))
			var/datum/random_event/RE = new X
			antag_spawn_events += RE

		for (var/X in concrete_typesof(/datum/random_event/major/player_spawn)-concrete_typesof(/datum/random_event/major/player_spawn/antag))
			var/datum/random_event/RE = new X
			player_spawn_events += RE

		for (var/X in concrete_typesof(/datum/random_event/minor))
			var/datum/random_event/RE = new X
			minor_events += RE

		for (var/X in concrete_typesof(/datum/random_event/special))
			var/datum/random_event/RE = new X
			special_events += RE

		for (var/X in concrete_typesof(/datum/random_event/start))
			var/datum/random_event/RE = new X
			start_events += RE

		queued_events = list("major"=list(),"minor"=list(),"special_events"=list(),"spawn"=list())

		src.active_storyteller = new/datum/storyteller/basic()
		src.active_storyteller.set_active(src)

	proc/process()
		if( !events_enabled )
			return

		// prevent random events near round end
		if (emergency_shuttle.location > SHUTTLE_LOC_STATION || current_state == GAME_STATE_FINISHED)
			return

		if (ticker.round_elapsed_ticks == 0)
			roundstart_events()

		active_storyteller.process()

	proc/do_random_event(var/list/event_bank, var/source = null)
		if (!event_bank || length(event_bank) < 1)
			logTheThing(LOG_DEBUG, null, "<b>Random Events:</b> do_random_event proc was passed a bad event bank")
			return
		if (!ticker?.mode?.do_random_events)
			logTheThing(LOG_DEBUG, null, "<b>Random Events:</b> Random events are turned off on this game mode.")
			return
		var/list/eligible = list()
		var/list/weights = list()
		for (var/datum/random_event/RE in event_bank)
			if (RE.is_event_available( ignore_time_lock = (source=="spawn_antag") ))
				eligible += RE
				weights += RE.weight
		if (length(eligible) > 0)
			var/datum/random_event/this = weightedprob(eligible, weights)
			this.event_effect(source)
		else
			logTheThing(LOG_DEBUG, null, "<b>Random Events:</b> do_random_event couldn't find any eligible events")

	proc/roundstart_events()
		for(var/datum/random_event/RE in delayed_start)
			var/source = delayed_start[RE]
			SPAWN(0) RE.event_effect(source)

	proc/force_event(var/string,var/reason)
		if (!string)
			return
		if (!reason)
			reason = "coded instance (undefined)"

		var/list/allevents = major_events | minor_events | special_events
		for (var/datum/random_event/RE in allevents)
			if (RE.name == string)
				RE.event_effect(reason)
				break

	///////////////////
	// CONFIGURATION //
	///////////////////

	proc/event_config()
		var/dat = "<html><body><title>Random Events Controller</title>"
		dat += "<b><u>Random Event Controls: </u></b><HR>"
		dat += "<b><u><a href='byond://?src=\ref[src];Storyteller=1'>Storyteller:</a></u></b> [active_storyteller.name]<br>"

		if (current_state <= GAME_STATE_PREGAME)
			dat += "<b>Random Events begin at: <a href='byond://?src=\ref[src];EventBegin=1'>[round(major_events_begin / 600)] minutes</a><br>"
			dat += "<b>Minor Events begin at: <a href='byond://?src=\ref[src];MEventBegin=1'>[round(minor_events_begin / 600)] minutes</a><br>"
			dat += "<b>Spawn Events begin at: <a href='byond://?src=\ref[src];MEventBegin=1'>[round(spawn_events_begin / 600)] minutes</a><br>"
		else
			dat += "Next major random event at [round(next_major_event / 600)] minutes into the round.<br>"
			dat += "Next minor event at [round(next_minor_event / 600)] minutes into the round.<br>"
			dat += "Next spawn event at [round(next_spawn_event / 600)] minutes into the round.<br>"

		dat += "<b><a href='byond://?src=\ref[src];Storyteller=1'>Storyteller:</a></b> [active_storyteller.name]<br>"
		dat += "<b><a href='byond://?src=\ref[src];EnableEvents=1'>Random Events Enabled:</a></b> [events_enabled ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];EnableMajorEvents=1'>Major Events Enabled:</a></b> [major_events_enabled ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];EnableMinorEvents=1'>Minor Events Enabled:</a></b> [minor_events_enabled ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];AnnounceEvents=1'>Announce Events to Station:</a></b> [announce_events ? "Yes" : "No"]<br>"
		dat += "<b><a href='byond://?src=\ref[src];TimeLocks=1'>Time Locking:</a></b> [time_lock ? "Yes" : "No"]<br>"
		dat += "<b>Minimum Population for Events: <a href='byond://?src=\ref[src];MinPop=1'>[minimum_population] players</a><br>"
		dat += "<b>Time Between Events:</b> <a href='byond://?src=\ref[src];TimeLower=1'>[round(time_between_major_events_lower / 600)]m</a> /"
		dat += " <a href='byond://?src=\ref[src];TimeUpper=1'>[round(time_between_major_events_upper / 600)]m</a><br>"
		dat += "<b>Time Between Minor Events:</b> <a href='byond://?src=\ref[src];MTimeLower=1'>[round(time_between_minor_events_lower / 600)]m</a> /"
		dat += " <a href='byond://?src=\ref[src];MTimeUpper=1'>[round(time_between_minor_events_upper / 600)]m</a>"
		dat += "<HR>"

		dat += "<b><u>Normal Random Events</u></b><BR>"
		for(var/datum/random_event/RE in major_events)
			dat += "<a href='byond://?src=\ref[src];TriggerEvent=\ref[RE]'><b>[RE.name]</b></a>"
			dat += " <small><a href='byond://?src=\ref[src];DisableEvent=\ref[RE]'>([RE.disabled ? "Disabled" : "Enabled"])</a>"
			dat += "<a href='byond://?src=\ref[src];ScheduleEvent=\ref[RE]'><i>Schedule</i></a>"
			if (RE.is_event_available())
				dat += " (Active)"
			dat += "<br></small>"
		dat += "<BR>"

		dat += "<b><u>Minor Random Events</u></b><BR>"
		for(var/datum/random_event/RE in minor_events)
			dat += "<a href='byond://?src=\ref[src];TriggerMEvent=\ref[RE]'><b>[RE.name]</b></a>"
			dat += " <small><a href='byond://?src=\ref[src];DisableMEvent=\ref[RE]'>([RE.disabled ? "Disabled" : "Enabled"])</a>"
			dat += "<a href='byond://?src=\ref[src];ScheduleMEvent=\ref[RE]'><i>Schedule</i></a>"
			if (RE.is_event_available())
				dat += " (Active)"
			dat += "<br></small>"
		dat += "<BR>"

		dat += "<b><u>Gimmick Events</u></b><BR>"
		for(var/datum/random_event/RE in special_events)
			dat += "<a href='byond://?src=\ref[src];TriggerSEvent=\ref[RE]'><b>[RE.name]</b></a>"
			dat += "<a href='byond://?src=\ref[src];ScheduleSEvent=\ref[RE]'><i>Schedule</i></a>"
			dat += "<br></small>"

		if(length(start_events))
			dat += "<BR>"
			dat += "<b><u>Round Start Events</u></b><BR>"
			for(var/datum/random_event/RE in start_events)
				dat += "<a href='byond://?src=\ref[src];TriggerStartEvent=\ref[RE]'><b>[RE.name]</b></a><br>"

		dat += "<HR>"
		dat += "</body></html>"
		usr.Browse(dat,"window=reconfig;size=450x450")

	Topic(href, href_list[])
		//So we have not had any validation on the admin random events panel since its inception. Argh. /Spy
		var/datum/random_event/RE
		if(usr?.client && !usr.client.holder) {boutput(usr, "<h3 class='admin'>Only administrators may use this command.</span>"); return}
		if (href_list["TriggerEvent"] || href_list["TriggerMEvent"] || href_list["TriggerSEvent"] || href_list["TriggerStartEvent"])

			if(href_list["TriggerEvent"])
				RE = locate(href_list["TriggerEvent"]) in major_events
			else if(href_list["TriggerMEvent"])
				RE = locate(href_list["TriggerMEvent"]) in minor_events
			else if(href_list["TriggerSEvent"])
				RE = locate(href_list["TriggerSEvent"]) in special_events
			else if(href_list["TriggerStartEvent"])
				RE = locate(href_list["TriggerStartEvent"]) in start_events

			if (!istype(RE,/datum/random_event/))
				return
			var/choice = alert("Trigger a [RE.name] event?","Random Events","Yes","No")
			if (choice == "Yes")
				if (RE.customization_available)
					if (RE.always_custom || alert("Random or custom variables?","[RE.name]","Random","Custom") == "Custom")
						RE.admin_call(key_name(usr, 1))
					else
						RE.event_effect("Triggered by [key_name(usr)]")
				else
					RE.event_effect("Triggered by [key_name(usr)]")

		if (href_list["ScheduleEvent"] || href_list["ScheduleMEvent"] || href_list["ScheduleSEvent"] || href_list["ScheduleStartEvent"])
			var/queue_string
			if(href_list["ScheduleEvent"])
				RE = locate(href_list["ScheduleEvent"]) in major_events
				queue_string = "major"
			else if(href_list["ScheduleMEvent"])
				RE = locate(href_list["ScheduleMEvent"]) in minor_events
				queue_string = "minor"
			else if(href_list["ScheduleSEvent"])
				RE = locate(href_list["ScheduleSEvent"]) in special_events
				queue_string = "special_events"
			if (!istype(RE,/datum/random_event/))
				return
			if(RE.always_custom)
				return

			var/schedule_time = input("When should '[RE.name]' be called? (Minute)","Random Events",minimum_population) as num
			if(schedule_time MINUTES <= ticker.round_elapsed_ticks)
				boutput(usr, SPAN_ALERT("Well that doesn't even make sense. That already happened!"))
				return

			src.queued_events[queue_string]["[RE.name]_[schedule_time]_[usr]"] += list(RE,schedule_time MINUTES)


		else if(href_list["DisableEvent"])
			RE = locate(href_list["DisableEvent"]) in major_events
			if (!istype(RE,/datum/random_event/))
				return
			RE.disabled = !RE.disabled
			message_admins("Admin [key_name(usr)] switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing(LOG_ADMIN, usr, "switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing(LOG_DIARY, usr, "switched [RE.name] event [RE.disabled ? "Off" : "On"]", "admin")

		else if(href_list["DisableMEvent"])
			RE = locate(href_list["DisableMEvent"]) in minor_events
			if (!istype(RE,/datum/random_event/))
				return
			RE.disabled = !RE.disabled
			message_admins("Admin [key_name(usr)] switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing(LOG_ADMIN, usr, "switched [RE.name] event [RE.disabled ? "Off" : "On"]")
			logTheThing(LOG_DIARY, usr, "switched [RE.name] event [RE.disabled ? "Off" : "On"]", "admin")

		else if(href_list["MinPop"])
			var/new_min = input("How many players need to be connected before events will occur?","Random Events",minimum_population) as num
			if (new_min == minimum_population) return

			if (new_min < 1)
				boutput(usr, SPAN_ALERT("Well that doesn't even make sense."))
				return
			else
				minimum_population = new_min

			message_admins("Admin [key_name(usr)] set the minimum population for events to [minimum_population]")
			logTheThing(LOG_ADMIN, usr, "set the minimum population for events to [minimum_population]")
			logTheThing(LOG_DIARY, usr, "set the minimum population for events to [minimum_population]", "admin")

		else if(href_list["EventBegin"])
			var/time = input("How many minutes into the round until events begin?","Random Events") as num
			major_events_begin = time * 600

			message_admins("Admin [key_name(usr)] set random events to begin at [time] minutes")
			logTheThing(LOG_ADMIN, usr, "set random events to begin at [time] minutes")
			logTheThing(LOG_DIARY, usr, "set random events to begin at [time] minutes", "admin")

		else if(href_list["MEventBegin"])
			var/time = input("How many minutes into the round until minor events begin?","Random Events") as num
			minor_events_begin = time * 600

			message_admins("Admin [key_name(usr)] set minor events to begin at [time] minutes")
			logTheThing(LOG_ADMIN, usr, "set minor events to begin at [time] minutes")
			logTheThing(LOG_DIARY, usr, "set minor events to begin at [time] minutes", "admin")

		else if(href_list["Storyteller"])
			var/datum/storyteller/new_teller = tgui_input_list(usr,"Choose Storyteller", "Storyteller", concrete_typesof(/datum/storyteller))
			if(new_teller)
				active_storyteller = new new_teller()
				active_storyteller.set_active(src)

		else if(href_list["EnableEvents"])
			events_enabled = !events_enabled
			message_admins("Admin [key_name(usr)] [events_enabled ? "enabled" : "disabled"] random events")
			logTheThing(LOG_ADMIN, usr, "[events_enabled ? "enabled" : "disabled"] random events")
			logTheThing(LOG_DIARY, usr, "[events_enabled ? "enabled" : "disabled"] random events", "admin")

		else if(href_list["EnableMajorEvents"])
			major_events_enabled = !major_events_enabled
			message_admins("Admin [key_name(usr)] [major_events_enabled ? "enabled" : "disabled"] random major events")
			logTheThing(LOG_ADMIN, usr, "[major_events_enabled ? "enabled" : "disabled"] random major events")
			logTheThing(LOG_DIARY, usr, "[major_events_enabled ? "enabled" : "disabled"] random major events", "admin")


		else if(href_list["EnableMinorEvents"])
			minor_events_enabled = !minor_events_enabled
			message_admins("Admin [key_name(usr)] [minor_events_enabled ? "enabled" : "disabled"] minor events")
			logTheThing(LOG_ADMIN, usr, "[minor_events_enabled ? "enabled" : "disabled"] minor events")
			logTheThing(LOG_DIARY, usr, "[minor_events_enabled ? "enabled" : "disabled"] minor events", "admin")

		else if(href_list["AnnounceEvents"])
			announce_events = !announce_events
			message_admins("Admin [key_name(usr)] [announce_events ? "enabled" : "disabled"] random event announcements")
			logTheThing(LOG_ADMIN, usr, "[announce_events ? "enabled" : "disabled"] random event announcements")
			logTheThing(LOG_DIARY, usr, "[announce_events ? "enabled" : "disabled"] random event announcements", "admin")

		else if(href_list["TimeLocks"])
			time_lock = !time_lock
			message_admins("Admin [key_name(usr)] [time_lock ? "enabled" : "disabled"] random event time locks")
			logTheThing(LOG_ADMIN, usr, "[time_lock ? "enabled" : "disabled"] random event time locks")
			logTheThing(LOG_DIARY, usr, "[time_lock ? "enabled" : "disabled"] random event time locks", "admin")

		else if(href_list["TimeLower"])
			var/time = input("Set the lower bound to how many minutes?","Random Events") as num
			if (time < 1)
				boutput(usr, SPAN_ALERT("The fuck is that supposed to mean???? Knock it off!"))
				return

			time *= 600
			if (time > time_between_major_events_upper)
				boutput(usr, SPAN_ALERT("You cannot set the lower bound higher than the upper bound."))
			else
				time_between_major_events_lower = time
				message_admins("Admin [key_name(usr)] set event lower interval bound to [time_between_major_events_lower / 600] minutes")
				logTheThing(LOG_ADMIN, usr, "set event lower interval bound to [time_between_major_events_lower / 600] minutes")
				logTheThing(LOG_DIARY, usr, "set event lower interval bound to [time_between_major_events_lower / 600] minutes", "admin")

		else if(href_list["TimeUpper"])
			var/time = input("Set the upper bound to how many minutes?","Random Events") as num
			if (time > 100)
				boutput(usr, SPAN_ALERT("That's a bit much."))
				return

			time *= 600
			if (time < time_between_major_events_lower)
				boutput(usr, SPAN_ALERT("You cannot set the upper bound lower than the lower bound."))
			else
				time_between_major_events_upper = time
			message_admins("Admin [key_name(usr)] set event upper interval bound to [time_between_major_events_upper / 600] minutes")
			logTheThing(LOG_ADMIN, usr, "set event upper interval bound to [time_between_major_events_upper / 600] minutes")
			logTheThing(LOG_DIARY, usr, "set event upper interval bound to [time_between_major_events_upper / 600] minutes", "admin")

		else if(href_list["MTimeLower"])
			var/time = input("Set the lower bound to how many minutes?","Random Events") as num
			if (time < 1)
				boutput(usr, SPAN_ALERT("The fuck is that supposed to mean???? Knock it off!"))
				return

			time *= 600
			if (time > time_between_minor_events_upper)
				boutput(usr, SPAN_ALERT("You cannot set the lower bound higher than the upper bound."))
			else
				time_between_minor_events_lower = time
			message_admins("Admin [key_name(usr)] set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes")
			logTheThing(LOG_ADMIN, usr, "set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes")
			logTheThing(LOG_DIARY, usr, "set minor event lower interval bound to [time_between_minor_events_lower / 600] minutes", "admin")

		else if(href_list["MTimeUpper"])
			var/time = input("Set the upper bound to how many minutes?","Random Events") as num
			if (time > 100)
				boutput(usr, SPAN_ALERT("That's a bit much."))
				return

			time *= 600
			if (time < time_between_minor_events_lower)
				boutput(usr, SPAN_ALERT("You cannot set the upper bound lower than the lower bound."))
			else
				time_between_minor_events_upper = time
			message_admins("Admin [key_name(usr)] set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes")
			logTheThing(LOG_ADMIN, usr, "set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes")
			logTheThing(LOG_DIARY, usr, "set minor event upper interval bound to [time_between_minor_events_upper / 600] minutes", "admin")

		src.event_config()
