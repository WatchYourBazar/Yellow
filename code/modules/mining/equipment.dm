/****************Explorer's Suit**************************/

/obj/item/clothing/suit/hooded/explorer
	name = "explorer suit"
	desc = "An armoured suit for exploring harsh environments."
	icon_state = "explorer"
	item_state = "explorer"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	cold_protection = CHEST|GROIN|LEGS|ARMS
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|ARMS
	hooded = 1
	hoodtype = /obj/item/clothing/head/explorer
	armor = list(melee = 30, bullet = 20, laser = 20, energy = 20, bomb = 50, bio = 100, rad = 50)
	allowed = list(/obj/item/device/flashlight,/obj/item/weapon/tank/internals, /obj/item/weapon/resonator, /obj/item/device/mining_scanner, /obj/item/device/t_scanner/adv_mining_scanner, /obj/item/weapon/gun/energy/kinetic_accelerator, /obj/item/weapon/pickaxe)

/obj/item/clothing/head/explorer
	name = "explorer hood"
	desc = "An armoured hood for exploring harsh environments."
	icon_state = "explorer"
	body_parts_covered = HEAD
	flags = NODROP
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS
	min_cold_protection_temperature = FIRE_HELM_MIN_TEMP_PROTECT
	max_heat_protection_temperature = FIRE_HELM_MAX_TEMP_PROTECT
	armor = list(melee = 30, bullet = 20, laser = 20, energy = 20, bomb = 50, bio = 100, rad = 50)

/obj/item/clothing/mask/gas/explorer
	name = "explorer gas mask"
	desc = "A military-grade gas mask that can be connected to an air supply."
	icon_state = "gas_mining"
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | MASKINTERNALS
	visor_flags_inv = HIDEFACIALHAIR
	visor_flags_cover = MASKCOVERSMOUTH
	actions_types = list(/datum/action/item_action/adjust)
	armor = list(melee = 10, bullet = 5, laser = 5, energy = 5, bomb = 0, bio = 50, rad = 0)

/obj/item/clothing/mask/gas/explorer/attack_self(mob/user)
	adjustmask(user)

/obj/item/clothing/mask/gas/explorer/adjustmask(user)
	..()
	w_class = mask_adjusted ? 3 : 2

/obj/item/clothing/mask/gas/explorer/folded/New()
	..()
	adjustmask()


/**********************Mining Equipment Vendor Items**************************/

/**********************Jaunter**********************/

/obj/item/device/wormhole_jaunter
	name = "wormhole jaunter"
	desc = "A single use device harnessing outdated wormhole technology, Nanotrasen has since turned its eyes to blue space for more accurate teleportation. The wormholes it creates are unpleasant to travel through, to say the least.\nThanks to modifications provided by the Free Golems, this jaunter can be worn on the belt to provide protection from chasms."
	icon = 'icons/obj/mining.dmi'
	icon_state = "Jaunter"
	item_state = "electronic"
	throwforce = 0
	w_class = 2
	throw_speed = 3
	throw_range = 5
	origin_tech = "bluespace=2"
	slot_flags = SLOT_BELT

/obj/item/device/wormhole_jaunter/attack_self(mob/user)
	user.visible_message("<span class='notice'>[user.name] activates the [src.name]!</span>")
	feedback_add_details("jaunter", "U") // user activated
	activate(user)

/obj/item/device/wormhole_jaunter/proc/turf_check(mob/user)
	var/turf/device_turf = get_turf(user)
	if(!device_turf||device_turf.z==2||device_turf.z>=7)
		user.text2tab("<span class='notice'>You're having difficulties getting the [src.name] to work.</span>")
		return FALSE
	return TRUE

/obj/item/device/wormhole_jaunter/proc/get_destinations(mob/user)
	var/list/destinations = list()

	if(isgolem(user))
		for(var/obj/item/device/radio/beacon/B in world)
			var/turf/T = get_turf(B)
			if(istype(T.loc, /area/ruin/powered/golem_ship))
				destinations += B

	// In the event golem beacon is destroyed, send to station instead
	if(destinations.len)
		return destinations

	for(var/obj/item/device/radio/beacon/B in world)
		var/turf/T = get_turf(B)
		if(T.z == ZLEVEL_STATION)
			destinations += B

	return destinations

/obj/item/device/wormhole_jaunter/proc/activate(mob/user)
	if(!turf_check(user))
		return

	var/list/L = get_destinations(user)
	if(!L.len)
		user.text2tab("<span class='notice'>The [src.name] found no beacons in the world to anchor a wormhole to.</span>")
		return
	var/chosen_beacon = pick(L)
	var/obj/effect/portal/wormhole/jaunt_tunnel/J = new /obj/effect/portal/wormhole/jaunt_tunnel(get_turf(src), chosen_beacon, lifespan=100)
	J.target = chosen_beacon
	try_move_adjacent(J)
	playsound(src,'sound/effects/sparks4.ogg',50,1)
	qdel(src)

/obj/item/device/wormhole_jaunter/emp_act(power)
	var/triggered = FALSE

	if(usr.get_item_by_slot(slot_belt) == src)
		if(power == 1)
			triggered = TRUE
		else if(power == 2 && prob(50))
			triggered = TRUE

	if(triggered)
		usr.visible_message("<span class='warning'>The [src] overloads and activates!</span>")
		feedback_add_details("jaunter","E") // EMP accidental activation
		activate(usr)

/obj/item/device/wormhole_jaunter/proc/chasm_react(mob/user)
	if(user.get_item_by_slot(slot_belt) == src)
		user.text2tab("Your [src] activates, saving you from the chasm!</span>")
		feedback_add_details("jaunter","C") // chasm automatic activation
		activate(user)
	else
		user.text2tab("The [src] is not attached to your belt, preventing it from saving you from the chasm. RIP.</span>")


/obj/effect/portal/wormhole/jaunt_tunnel
	name = "jaunt tunnel"
	icon = 'icons/effects/effects.dmi'
	icon_state = "bhole3"
	desc = "A stable hole in the universe made by a wormhole jaunter. Turbulent doesn't even begin to describe how rough passage through one of these is, but at least it will always get you somewhere near a beacon."

/obj/effect/portal/wormhole/jaunt_tunnel/teleport(atom/movable/M)
	if(istype(M, /obj/effect))
		return

	if(istype(M, /atom/movable))
		if(do_teleport(M, target, 6))
			// KERPLUNK
			playsound(M,'sound/weapons/resonator_blast.ogg',50,1)
			if(iscarbon(M))
				var/mob/living/carbon/L = M
				L.Weaken(3)
				if(ishuman(L))
					shake_camera(L, 20, 1)
					spawn(20)
						if(L)
							L.vomit(20)

/**********************Resonator**********************/

/obj/item/weapon/resonator
	name = "resonator"
	icon = 'icons/obj/mining.dmi'
	icon_state = "resonator"
	item_state = "resonator"
	desc = "A handheld device that creates small fields of energy that resonate until they detonate, crushing rock. It can also be activated without a target to create a field at the user's location, to act as a delayed time trap. It's more effective in a vacuum."
	w_class = 3
	force = 15
	throwforce = 10
	var/cooldown = 0
	var/fieldsactive = 0
	var/burst_time = 30
	var/fieldlimit = 4
	origin_tech = "magnets=3;engineering=3"

/obj/item/weapon/resonator/upgraded
	name = "upgraded resonator"
	desc = "An upgraded version of the resonator that can produce more fields at once."
	icon_state = "resonator_u"
	item_state = "resonator_u"
	origin_tech = "materials=4;powerstorage=3;engineering=3;magnets=3"
	fieldlimit = 6

/obj/item/weapon/resonator/proc/CreateResonance(target, creator)
	var/turf/T = get_turf(target)
	if(locate(/obj/effect/resonance) in T)
		return
	if(fieldsactive < fieldlimit)
		playsound(src,'sound/weapons/resonator_fire.ogg',50,1)
		new /obj/effect/resonance(T, creator, burst_time)
		fieldsactive++
		spawn(burst_time)
			fieldsactive--

/obj/item/weapon/resonator/attack_self(mob/user)
	if(burst_time == 50)
		burst_time = 30
		user.text2tab("<span class='info'>You set the resonator's fields to detonate after 3 seconds.</span>")
	else
		burst_time = 50
		user.text2tab("<span class='info'>You set the resonator's fields to detonate after 5 seconds.</span>")

/obj/item/weapon/resonator/afterattack(atom/target, mob/user, proximity_flag)
	if(proximity_flag)
		if(!check_allowed_items(target, 1)) return
		CreateResonance(target, user)

/obj/effect/resonance
	name = "resonance field"
	desc = "A resonating field that significantly damages anything inside of it when the field eventually ruptures."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield1"
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = 0
	var/resonance_damage = 20

/obj/effect/resonance/New(loc, var/creator = null, var/timetoburst)
	var/turf/proj_turf = get_turf(src)
	if(!istype(proj_turf))
		return
	if(istype(proj_turf, /turf/closed/mineral))
		var/turf/closed/mineral/M = proj_turf
		spawn(timetoburst)
			playsound(src,'sound/weapons/resonator_blast.ogg',50,1)
			M.gets_drilled(creator)
			qdel(src)
	else
		var/datum/gas_mixture/environment = proj_turf.return_air()
		var/pressure = environment.return_pressure()
		if(pressure < 50)
			name = "strong resonance field"
			resonance_damage = 60
		spawn(timetoburst)
			playsound(src,'sound/weapons/resonator_blast.ogg',50,1)
			if(creator)
				for(var/mob/living/L in src.loc)
					add_logs(creator, L, "used a resonator field on", "resonator")
					L.text2tab("<span class='danger'>The [src.name] ruptured with you in it!</span>")
					L.adjustBruteLoss(resonance_damage)
			else
				for(var/mob/living/L in src.loc)
					L.text2tab("<span class='danger'>The [src.name] ruptured with you in it!</span>")
					L.adjustBruteLoss(resonance_damage)
			qdel(src)

/**********************Facehugger toy**********************/

/obj/item/clothing/mask/facehugger/toy
	item_state = "facehugger_inactive"
	desc = "A toy often used to play pranks on other miners by putting it in their beds. It takes a bit to recharge after latching onto something."
	throwforce = 0
	real = 0
	sterile = 1
	tint = 3 //Makes it feel more authentic when it latches on

/obj/item/clothing/mask/facehugger/toy/Die()
	return

/**********************Lazarus Injector**********************/

/obj/item/weapon/lazarus_injector
	name = "lazarus injector"
	desc = "An injector with a cocktail of nanomachines and chemicals, this device can seemingly raise animals from the dead, making them become friendly to the user. Unfortunately, the process is useless on higher forms of life and incredibly costly, so these were hidden in storage until an executive thought they'd be great motivation for some of their employees."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "lazarus_hypo"
	item_state = "hypo"
	throwforce = 0
	w_class = 2
	throw_speed = 3
	throw_range = 5
	var/loaded = 1
	var/malfunctioning = 0
	var/revive_type = SENTIENCE_ORGANIC //So you can't revive boss monsters or robots with it
	origin_tech = "biotech=4;magnets=6"

/obj/item/weapon/lazarus_injector/afterattack(atom/target, mob/user, proximity_flag)
	if(!loaded)
		return
	if(istype(target, /mob/living) && proximity_flag)
		if(istype(target, /mob/living/simple_animal))
			var/mob/living/simple_animal/M = target
			if(M.sentience_type != revive_type)
				user.text2tab("<span class='info'>[src] does not work on this sort of creature.</span>")
				return
			if(M.stat == DEAD)
				M.faction = list("neutral")
				M.revive(full_heal = 1, admin_revive = 1)
				if(istype(target, /mob/living/simple_animal/hostile))
					var/mob/living/simple_animal/hostile/H = M
					if(malfunctioning)
						H.faction |= list("lazarus", "\ref[user]")
						H.robust_searching = 1
						H.friends += user
						H.attack_same = 1
						log_game("[user] has revived hostile mob [target] with a malfunctioning lazarus injector")
					else
						H.attack_same = 0
				loaded = 0
				user.visible_message("<span class='notice'>[user] injects [M] with [src], reviving it.</span>")
				feedback_add_details("lazarus_injector", "[M.type]")
				playsound(src,'sound/effects/refill.ogg',50,1)
				icon_state = "lazarus_empty"
				return
			else
				user.text2tab("<span class='info'>[src] is only effective on the dead.</span>")
				return
		else
			user.text2tab("<span class='info'>[src] is only effective on lesser beings.</span>")
			return

/obj/item/weapon/lazarus_injector/emp_act()
	if(!malfunctioning)
		malfunctioning = 1

/obj/item/weapon/lazarus_injector/examine(mob/user)
	..()
	if(!loaded)
		user.text2tab("<span class='info'>[src] is empty.</span>")
	if(malfunctioning)
		user.text2tab("<span class='info'>The display on [src] seems to be flickering.</span>")

/**********************Mining Scanners**********************/

/obj/item/device/mining_scanner
	desc = "A scanner that checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. Wear material scanners for optimal results."
	name = "manual mining scanner"
	icon_state = "mining1"
	item_state = "analyzer"
	w_class = 2
	flags = CONDUCT
	slot_flags = SLOT_BELT
	var/cooldown = 0
	origin_tech = "engineering=1;magnets=1"

/obj/item/device/mining_scanner/attack_self(mob/user)
	if(!user.client)
		return
	if(!cooldown)
		cooldown = 1
		spawn(40)
			cooldown = 0
		var/list/mobs = list()
		mobs |= user
		mineral_scan_pulse(mobs, get_turf(user))


//Debug item to identify all ore spread quickly
/obj/item/device/mining_scanner/admin

/obj/item/device/mining_scanner/admin/attack_self(mob/user)
	for(var/turf/closed/mineral/M in world)
		if(M.scan_state)
			M.icon_state = M.scan_state
	qdel(src)

/obj/item/device/t_scanner/adv_mining_scanner
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. Wear meson scanners for optimal results. This one has an extended range."
	name = "advanced automatic mining scanner"
	icon_state = "mining0"
	item_state = "analyzer"
	w_class = 2
	flags = CONDUCT
	slot_flags = SLOT_BELT
	var/cooldown = 35
	var/on_cooldown = 0
	var/range = 7
	var/meson = TRUE
	origin_tech = "engineering=3;magnets=3"

/obj/item/device/t_scanner/adv_mining_scanner/material
	meson = FALSE
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. Wear material scanners for optimal results. This one has an extended range."

/obj/item/device/t_scanner/adv_mining_scanner/lesser
	name = "automatic mining scanner"
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. Wear meson scanners for optimal results."
	range = 4
	cooldown = 50

/obj/item/device/t_scanner/adv_mining_scanner/lesser/material
	desc = "A scanner that automatically checks surrounding rock for useful minerals; it can also be used to stop gibtonite detonations. Wear material scanners for optimal results."
	meson = FALSE

/obj/item/device/t_scanner/adv_mining_scanner/scan()
	if(!on_cooldown)
		on_cooldown = 1
		spawn(cooldown)
			on_cooldown = 0
		var/turf/t = get_turf(src)
		var/list/mobs = recursive_mob_check(t, 1,0,0)
		if(!mobs.len)
			return
		if(meson)
			mineral_scan_pulse(mobs, t, range)
		else
			mineral_scan_pulse_material(mobs, t, range)

//For use with mesons
/proc/mineral_scan_pulse(list/mobs, turf/T, range = world.view)
	var/list/minerals = list()
	for(var/turf/closed/mineral/M in range(range, T))
		if(M.scan_state)
			minerals += M
	if(minerals.len)
		for(var/mob/user in mobs)
			if(user.client)
				var/client/C = user.client
				for(var/turf/closed/mineral/M in minerals)
					var/turf/F = get_turf(M)
					var/image/I = image('icons/turf/smoothrocks.dmi', loc = F, icon_state = M.scan_state, layer = FLASH_LAYER)
					C.images += I
					spawn(30)
						if(C)
							C.images -= I

//For use with material scanners
/proc/mineral_scan_pulse_material(list/mobs, turf/T, range = world.view)
	var/list/minerals = list()
	for(var/turf/closed/mineral/M in range(range, T))
		if(M.scan_state)
			minerals += M
	if(minerals.len)
		for(var/turf/closed/mineral/M in minerals)
			var/obj/effect/overlay/temp/mining_overlay/C = PoolOrNew(/obj/effect/overlay/temp/mining_overlay, M)
			C.icon_state = M.scan_state

/obj/effect/overlay/temp/mining_overlay
	layer = FLASH_LAYER
	icon = 'icons/turf/smoothrocks.dmi'
	anchored = 1
	mouse_opacity = 0
	duration = 30
	pixel_x = -4
	pixel_y = -4


/**********************Xeno Warning Sign**********************/
/obj/structure/sign/xeno_warning_mining
	name = "DANGEROUS ALIEN LIFE"
	desc = "A sign that warns would be travellers of hostile alien life in the vicinity."
	icon = 'icons/obj/mining.dmi'
	icon_state = "xeno_warning"

/******************Hardsuit Jetpack Upgrade*******************/
/obj/item/hardsuit_jetpack
	name = "hardsuit jetpack upgrade"
	icon_state = "jetpack_upgrade"
	desc = "A modular, compact set of thrusters designed to integrate with a hardsuit. It is fueled by a tank inserted into the suit's storage compartment."


/obj/item/hardsuit_jetpack/afterattack(var/obj/item/clothing/suit/space/hardsuit/S, mob/user)
	..()
	if(!istype(S))
		user.text2tab("<span class='warning'>This upgrade can only be applied to a hardsuit.</span>")
	else if(S.jetpack)
		user.text2tab("<span class='warning'>[S] already has a jetpack installed.</span>")
	else if(S == user.get_item_by_slot(slot_wear_suit)) //Make sure the player is not wearing the suit before applying the upgrade.
		user.text2tab("<span class='warning'>You cannot install the upgrade to [S] while wearing it.</span>")
	else
		S.jetpack = new /obj/item/weapon/tank/jetpack/suit(S)
		user.text2tab("<span class='notice'>You successfully install the jetpack into [S].</span>")
		qdel(src)

/*********************Hivelord stabilizer****************/

/obj/item/weapon/hivelordstabilizer
	name = "stabilizing serum"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle19"
	desc = "Inject certain types of monster organs with this stabilizer to preserve their healing powers indefinitely."
	w_class = 1
	origin_tech = "biotech=3"

/obj/item/weapon/hivelordstabilizer/afterattack(obj/item/organ/M, mob/user)
	var/obj/item/organ/hivelord_core/C = M
	if(!istype(C, /obj/item/organ/hivelord_core))
		user.text2tab("<span class='warning'>The stabilizer only works on certain types of monster organs, generally regenerative in nature.</span>")
		return ..()
	C.preserved = 1
	feedback_add_details("hivelord_core", "[C.type]|stabilizer") // preserved
	user.text2tab("<span class='notice'>You inject the [M] with the stabilizer. It will no longer go inert.</span>")
	qdel(src)
