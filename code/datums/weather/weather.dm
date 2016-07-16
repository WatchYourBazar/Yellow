//The effects of weather occur across an entire z-level. For instance, lavaland has periodic ash storms that scorch most unprotected creatures.

#define STARTUP_STAGE 1
#define MAIN_STAGE 2
#define WIND_DOWN_STAGE 3
#define END_STAGE 4

/datum/weather
	var/name = "space wind"
	var/desc = "Heavy gusts of wind blanket the area, periodically knocking down anyone caught in the open."

	var/telegraph_message = "<span class='warning'>The wind begins to pick up.</span>" //The message displayed in chat to foreshadow the weather's beginning
	var/telegraph_duration = 300 //In deciseconds, how long from the beginning of the telegraph until the weather begins
	var/telegraph_sound //The sound file played to everyone on an affected z-level
	var/telegraph_overlay //The overlay applied to all tiles on the z-level

	var/weather_message = "<span class='userdanger'>The wind begins to blow ferociously!</span>" //Displayed in chat once the weather begins in earnest
	var/weather_duration = 1200 //In deciseconds, how long the weather lasts once it begins
	var/weather_duration_lower = 1200 //See above - this is the lowest possible duration
	var/weather_duration_upper = 1500 //See above - this is the highest possible duration
	var/weather_sound
	var/weather_overlay

	var/end_message = "<span class='danger'>The wind relents its assault.</span>" //Displayed once the wather is over
	var/end_duration = 300 //In deciseconds, how long the "wind-down" graphic will appear before vanishing entirely
	var/end_sound
	var/end_overlay

	var/area_type = /area/space //Types of area to affect
	var/list/impacted_areas = list() //Areas to be affected by the weather, calculated when the weather begins
	var/list/target_zs = list(ZLEVEL_STATION) //The z-level to affect

	var/overlay_layer = AREA_LAYER //Since it's above everything else, this is the layer used by default. TURF_LAYER is below mobs and walls if you need to use that.
	var/aesthetic = FALSE //If the weather has no purpose other than looks
	var/immunity_type = "storm" //Used by mobs to prevent them from being affected by the weather

	var/stage = END_STAGE //The stage of the weather, from 1-4

	var/telegraph_outdoors_only = 0

	var/probability = FALSE //Percent chance to happen if there are other possible weathers on the z-level

/datum/weather/New()
	..()
	SSweather.existing_weather |= src

/datum/weather/Destroy()
	SSweather.existing_weather -= src
	..()

/datum/weather/proc/telegraph()
	if(stage == STARTUP_STAGE)
		return
	stage = STARTUP_STAGE
	for(var/V in get_areas(area_type))
		var/area/A = V
		if(A.z in target_zs)
			impacted_areas |= A
	weather_duration = rand(weather_duration_lower, weather_duration_upper)
	update_areas()
	for(var/V in player_list)
		var/mob/M = V
		if(M.z in target_zs)
			if(telegraph_outdoors_only)
				var/area/A = get_area(M)
				if(!A.outdoors)
					continue
			if(telegraph_message)
				M.text2tab(telegraph_message)
			if(telegraph_sound)
				M << sound(telegraph_sound)
	addtimer(src, "start", telegraph_duration)

/datum/weather/proc/start()
	if(stage >= MAIN_STAGE)
		return
	stage = MAIN_STAGE
	update_areas()
	for(var/V in player_list)
		var/mob/M = V
		if(M.z in target_zs)
			if(telegraph_outdoors_only)
				var/area/A = get_area(M)
				if(!A.outdoors)
					continue
			if(weather_message)
				M.text2tab(weather_message)
			if(weather_sound)
				M << sound(weather_sound)
	SSweather.processing.Add(src)
	addtimer(src, "wind_down", weather_duration)

/datum/weather/proc/wind_down()
	if(stage >= WIND_DOWN_STAGE)
		return
	stage = WIND_DOWN_STAGE
	update_areas()
	for(var/V in player_list)
		var/mob/M = V
		if(M.z in target_zs)
			if(telegraph_outdoors_only)
				var/area/A = get_area(M)
				if(!A.outdoors)
					continue
			if(end_message)
				M.text2tab(end_message)
			if(end_sound)
				M << sound(end_sound)
	SSweather.processing.Remove(src)
	addtimer(src, "end", end_duration)

/datum/weather/proc/end()
	if(stage == END_STAGE)
		return
	stage = END_STAGE
	update_areas()

/datum/weather/proc/impact(mob/living/L) //What effect does this weather have on the hapless mob?
	return

/datum/weather/proc/update_areas()
	for(var/V in impacted_areas)
		var/area/N = V
		switch(stage)
			if(STARTUP_STAGE)
				N.weather_overlay = image(icon = 'icons/effects/weather_effects.dmi',icon_state = telegraph_overlay, layer = overlay_layer)
			if(MAIN_STAGE)
				N.weather_overlay = image(icon = 'icons/effects/weather_effects.dmi',icon_state = weather_overlay, layer = overlay_layer)
			if(WIND_DOWN_STAGE)
				N.weather_overlay = image(icon = 'icons/effects/weather_effects.dmi',icon_state = end_overlay,layer = overlay_layer)
			if(END_STAGE)
				N.weather_overlay = null
		N.updateicon()