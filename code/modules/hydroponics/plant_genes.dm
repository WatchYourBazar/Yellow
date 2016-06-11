/datum/plant_gene
	var/name

/datum/plant_gene/proc/get_name() // Used for manipulator display and gene disk name.
	return name

/datum/plant_gene/proc/can_add(obj/item/seeds/S)
	return !istype(S, /obj/item/seeds/sample) // Samples can't accept new genes

/datum/plant_gene/proc/Copy()
	return new type




// Core plant genes store 5 main variables: lifespan, endurance, production, yield, potency
/datum/plant_gene/core
	var/value

/datum/plant_gene/core/get_name()
	return "[name] [value]"

/datum/plant_gene/core/proc/apply_stat(obj/item/seeds/S)
	return

/datum/plant_gene/core/New(var/i = null)
	..()
	if(!isnull(i))
		value = i

/datum/plant_gene/core/Copy()
	var/datum/plant_gene/core/C = ..()
	C.value = value
	return C

/datum/plant_gene/core/can_add(obj/item/seeds/S)
	if(!..())
		return FALSE
	return S.get_gene(src.type)

/datum/plant_gene/core/lifespan
	name = "Lifespan"
	value = 25

/datum/plant_gene/core/lifespan/apply_stat(obj/item/seeds/S)
	S.lifespan = value


/datum/plant_gene/core/endurance
	name = "Endurance"
	value = 15

/datum/plant_gene/core/endurance/apply_stat(obj/item/seeds/S)
	S.endurance = value


/datum/plant_gene/core/production
	name = "Production Speed"
	value = 6

/datum/plant_gene/core/production/apply_stat(obj/item/seeds/S)
	S.production = value


/datum/plant_gene/core/yield
	name = "Yield"
	value = 3

/datum/plant_gene/core/yield/apply_stat(obj/item/seeds/S)
	S.yield = value


/datum/plant_gene/core/potency
	name = "Potency"
	value = 10

/datum/plant_gene/core/potency/apply_stat(obj/item/seeds/S)
	S.potency = value


// Reagent genes store reagent ID and reagent ratio. Amount of reagent in the plant = 1 + (potency * rate)
/datum/plant_gene/reagent
	name = "Nutriment"
	var/reagent_id = "nutriment"
	var/rate = 0.04

/datum/plant_gene/reagent/get_name()
	return "[name] production [rate*100]%"

/datum/plant_gene/reagent/proc/set_reagent(reag_id)
	reagent_id = reag_id
	name = "UNKNOWN"

	var/datum/reagent/R = chemical_reagents_list[reag_id]
	if(R && R.id == reagent_id)
		name = R.name

/datum/plant_gene/reagent/New(reag_id = null, reag_rate = 0)
	..()
	if(reag_id && reag_rate)
		set_reagent(reag_id)
		rate = reag_rate

/datum/plant_gene/reagent/Copy()
	var/datum/plant_gene/reagent/G = ..()
	G.name = name
	G.reagent_id = reagent_id
	G.rate = rate
	return G

/datum/plant_gene/reagent/can_add(obj/item/seeds/S)
	if(!..())
		return FALSE
	for(var/datum/plant_gene/reagent/R in S.genes)
		if(R.reagent_id == reagent_id)
			return FALSE
	return TRUE


// Various traits affecting the product. Each must be somehow useful.
/datum/plant_gene/trait
	var/rate = 0.05
	var/examine_line = ""
	var/list/origin_tech = null
	var/trait_id // must be set and equal for any two traits of the same type

/datum/plant_gene/trait/Copy()
	var/datum/plant_gene/trait/G = ..()
	G.rate = rate
	return G

/datum/plant_gene/trait/can_add(obj/item/seeds/S)
	if(!..())
		return FALSE

	for(var/datum/plant_gene/trait/R in S.genes)
		if(trait_id && R.trait_id == trait_id)
			return FALSE
		if(type == R.type)
			return FALSE
	return TRUE

/datum/plant_gene/trait/proc/on_new(obj/item/weapon/reagent_containers/food/snacks/grown/G, newloc)
	if(origin_tech) // This ugly code segment adds RnD tech levels to resulting plants.
		if(G.origin_tech)
			var/list/tech = params2list(G.origin_tech)
			for(var/t in origin_tech)
				if(t in tech)
					tech[t] = max(tech[t], origin_tech[t])
				else
					tech[t] = origin_tech[t]
			G.origin_tech = list2params(tech)
		else
			G.origin_tech = list2params(origin_tech)
	return

/datum/plant_gene/trait/proc/on_consume(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/target)
	return
/datum/plant_gene/trait/proc/on_cross(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	return
/datum/plant_gene/trait/proc/on_slip(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/target)
	return
/datum/plant_gene/trait/proc/on_squash(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	return



/datum/plant_gene/trait/squash
	// Allows the plant to be squashed when thrown or slipped on, leaving a colored mess and trash type item behind.
	// Also splashes everything in target turf with reagents and applies other trait effects (teleporting, etc) to the target by on_squash.
	// For code, see grown.dm
	name = "Liquid Contents"
	examine_line = "<span class='info'>It has a lot of liquid contents inside.</span>"
	origin_tech = list("bio" = 5)

/*/datum/plant_gene/trait/squash/on_slip(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/target)
	G.squash(target)*/


/datum/plant_gene/trait/slip
	// Makes plant slippery, unless it has a grown-type trash. Then the trash gets slippery.
	// Applies other trait effects (teleporting, etc) to the target by on_slip.
	name = "Slippery Skin"
	rate = 0.1
	examine_line = "<span class='info'>It has a very slippery skin.</span>"

/datum/plant_gene/trait/slip/on_cross(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	if(iscarbon(target))
		var/obj/item/seeds/seed = G.seed
		var/mob/living/carbon/M = target

		var/stun_len = seed.potency * rate * 0.8
		if(istype(G) && ispath(G.trash, /obj/item/weapon/grown))
			return

		if(!istype(G, /obj/item/weapon/grown/bananapeel) && (!G.reagents || !G.reagents.has_reagent("lube")))
			stun_len /= 3

		var/stun = min(stun_len, 7)
		var/weaken = min(stun_len, 7)

		if(M.slip(stun, weaken, G))
			for(var/datum/plant_gene/trait/T in seed.genes)
				T.on_slip(src, M)

/datum/plant_gene/trait/cell_charge
	// Cell recharging trait. Charges all mob's power cells to (potency*rate)% mark when eaten.
	// Generates sparks on squash.
	// Small (potency*rate*5) chance to shock squish or slip target for (potency*rate*5) damage.
	// Multiplies max charge by (rate*1000) when used in potato power cells.
	name = "Electrical Activity"
	rate = 0.2
	origin_tech = list("powerstorage" = 5)

/datum/plant_gene/trait/cell_charge/on_slip(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/C)
	var/power = G.seed.potency*rate
	if(prob(power))
		C.electrocute_act(round(power), G, 1, 1)

/datum/plant_gene/trait/cell_charge/on_squash(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		var/power = G.seed.potency*rate
		if(prob(power))
			C.electrocute_act(round(power), G, 1, 1)

/datum/plant_gene/trait/cell_charge/on_consume(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/target)
	if(!G.reagents.total_volume)
		var/batteries_recharged = 0
		for(var/obj/item/weapon/stock_parts/cell/C in target.GetAllContents())
			var/newcharge = min(G.seed.potency*0.01*C.maxcharge, C.maxcharge)
			if(C.charge < newcharge)
				C.charge = newcharge
				if(isobj(C.loc))
					var/obj/O = C.loc
					O.update_icon() //update power meters and such
				C.update_icon()
				batteries_recharged = 1
		if(batteries_recharged)
			target.text2tab("<span class='notice'>Your batteries are recharged!</span>")



/datum/plant_gene/trait/glow
	// Makes plant glow. Makes plant in tray glow too.
	// Adds potency*rate luminosity to products.
	name = "Bioluminescence"
	rate = 0.1
	examine_line = "<span class='info'>It emits a soft glow.</span>"
	trait_id = "glow"

/datum/plant_gene/trait/glow/proc/get_lum(obj/item/seeds/S)
	return round(S.potency*rate)

/datum/plant_gene/trait/glow/on_new(obj/item/weapon/reagent_containers/food/snacks/grown/G, newloc)
	..()
	if(ismob(newloc))
		G.pickup(newloc)//adjusts the lighting on the mob
	else
		G.SetLuminosity(get_lum(G.seed))

/datum/plant_gene/trait/glow/berry
	name = "Strong Bioluminescence"
	rate = 0.2


/datum/plant_gene/trait/teleport
	// Makes plant teleport people when squashed or slipped on.
	// Teleport radius is calculated as max(round(potency*rate), 1)
	name = "Bluespace Activity"
	rate = 0.1
	origin_tech = list("bluespace" = 5)

/datum/plant_gene/trait/teleport/on_squash(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	if(isliving(target))
		var/teleport_radius = max(round(G.seed.potency / 10), 1)
		var/turf/T = get_turf(target)
		new /obj/effect/decal/cleanable/molten_item(T) //Leave a pile of goo behind for dramatic effect...
		do_teleport(target, T, teleport_radius)

/datum/plant_gene/trait/teleport/on_slip(obj/item/weapon/reagent_containers/food/snacks/grown/G, mob/living/carbon/C)
	var/teleport_radius = max(round(G.seed.potency / 10), 1)
	var/turf/T = get_turf(C)
	C.text2tab("<span class='warning'>You slip through spacetime!</span>")
	do_teleport(C, T, teleport_radius)
	if(prob(50))
		do_teleport(G, T, teleport_radius)
	else
		new /obj/effect/decal/cleanable/molten_item(T) //Leave a pile of goo behind for dramatic effect...
		qdel(G)


/datum/plant_gene/trait/noreact
	// Makes plant reagents not react until squashed.
	name = "Separated Chemicals"

/datum/plant_gene/trait/noreact/on_new(obj/item/weapon/reagent_containers/food/snacks/grown/G, newloc)
	..()
	G.reagents.set_reacting(FALSE)

/datum/plant_gene/trait/noreact/on_squash(obj/item/weapon/reagent_containers/food/snacks/grown/G, atom/target)
	G.reagents.set_reacting(TRUE)
	G.reagents.handle_reactions()


/datum/plant_gene/trait/maxchem
	// 2x to max reagents volume.
	name = "Densified Chemicals"
	rate = 2

/datum/plant_gene/trait/maxchem/on_new(obj/item/weapon/reagent_containers/food/snacks/grown/G, newloc)
	..()
	G.reagents.maximum_volume *= rate
