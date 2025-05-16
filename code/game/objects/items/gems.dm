// Cut Gems
/obj/item/gem
	name = "random gem"
	desc = "If you find this, yell at coderbus"
	icon_state = "cut_rand"
	icon = 'icons/roguetown/items/gems.dmi'
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_MOUTH
	dropshrink = 0.8
	drop_sound = 'sound/items/gem.ogg'
	///I am leaving this here as a note. If you leave the price null on subtypes, you're eating the infinite recursion pill.
	///I dont care if its negative just DONT LEAVE IT 0
	sellprice = 0
	static_price = FALSE
	experimental_inhand = FALSE
	// qualityoflearn buff shit
	var/arcyne_potency = 20
	var/datum/attunement/attuned
	///For Mappers; gem_path = weight
	var/list/valid_gems = list()

/obj/item/gem/Initialize()
	. = ..()
	if(sellprice == 0)
		var/new_gem
		if(length(valid_gems))
			new_gem = pickweight(valid_gems)
		else
			new_gem = pick(subtypesof(/obj/item/gem))
			new new_gem(get_turf(src))
		return INITIALIZE_HINT_QDEL
	update_icon_state()

/obj/item/gem/update_icon_state()
	if(icon_state=="cut_rand")
		icon_state = "cut_[pick(1,2)]"
		return

/obj/item/gem/on_consume(mob/living/eater)
	. = ..()
	if(attuned)
		eater.mana_pool.adjust_attunement(attuned, 0.1)

/obj/item/gem/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -1,"sy" = 0,"nx" = 11,"ny" = 1,"wx" = 0,"wy" = 1,"ex" = 4,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 15,"sturn" = 0,"wturn" = 0,"eturn" = 39,"nflip" = 8,"sflip" = 0,"wflip" = 0,"eflip" = 8)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/gem/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	playsound(loc, pick('sound/items/gems (1).ogg','sound/items/gems (2).ogg'), 100, TRUE, -2)
	..()

/obj/item/gem/green
	name = "gemerald"
	desc = "Glints with verdant brilliance."
	color = "#00ff008c"
	icon_state = "cut_rand"
	sellprice = 44
	arcyne_potency = 7
	attuned = /datum/attunement/earth

/obj/item/gem/blue
	name = "blortz"
	desc = "Pale blue, like a frozen tear."
	color = "#00d9ff"
	icon_state = "cut_1"
	sellprice = 88
	arcyne_potency = 25
	attuned = /datum/attunement/blood

/obj/item/gem/yellow
	name = "toper"
	desc = "Its amber hues remind you of the sunset."
	color = "#e6a008"
	icon_state = "cut_1"
	sellprice = 25
	arcyne_potency = 5
	attuned = /datum/attunement/light

/obj/item/gem/violet
	name = "saffira"
	desc = "This gem is admired by many wizards."
	color = "#3700ff"
	icon_state = "cut_1"
	sellprice = 56
	arcyne_potency = 10
	attuned = /datum/attunement/electric

/obj/item/gem/diamond
	name = "dorpel"
	desc = "Beautifully pure, it demands respect."
	color = "#ddecec"
	icon_state = "cut_2"
	sellprice = 121
	arcyne_potency = 15
	attuned = /datum/attunement/aeromancy

/obj/item/gem/red
	name = "rubor"
	desc = "Glistening with unkempt rage."
	color = "#ff0000"
	icon_state = "cut_rand"
	sellprice = 100
	attuned = /datum/attunement/fire

/obj/item/gem/black
	name = "onyxa"
	desc = "Dark as nite."
	color = "#4f5158"
	icon_state = "cut_rand"
	sellprice = 76
	attuned = /datum/attunement/dark

/obj/item/gem/amethyst
	name = "amythortz"
	desc = "A deep lavender crystal, it surges with magical energy, yet it's artificial nature means it' worth little."
	color = "#5f1634"
	icon_state = "cut_rand"
	sellprice = 18
	arcyne_potency = 25
	attuned = /datum/attunement/arcyne

// Uncut Gems
/obj/item/uncut_gem
	name = "random uncut gem"
	desc = "If you find this, yell at coderbus"
	icon_state = "uncut_rand"
	icon = 'icons/roguetown/items/gems.dmi'
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_MOUTH
	dropshrink = 0.8
	drop_sound = 'sound/foley/dropsound/brick_drop.ogg'
	sellprice = 0
	static_price = FALSE
	experimental_inhand = FALSE
	///Uncut Gem Cut type
	var/obj/item/gem/gemtype
	///If cutting the gem failed and this is now a useless shard that can be sold for some money
	var/gemcutting_failure = FALSE
	///For Mappers; gem_path = weight
	var/list/valid_gems = list()

/obj/item/uncut_gem/New()
	. = ..()
	name = "uncut [gemtype:name]"
	desc = "[gemtype:desc]"
	color = "[gemtype:color]"
	sellprice = (ceil(gemtype:sellprice*(rand(0.5,0.75))))

/obj/item/uncut_gem/Initialize()
	. = ..()
	if(!gemtype)
		var/new_gem
		if(length(valid_gems))
			new_gem = pickweight(valid_gems)
		else
			new_gem = pick(subtypesof(/obj/item/uncut_gem))
		new new_gem(get_turf(src))
		return INITIALIZE_HINT_QDEL
	update_icon_state()

/obj/item/uncut_gem/update_icon_state()
	if(gemcutting_failure)
		name = "ruined [gemtype:name]"
		icon_state = "cutfail_[pick(1,2,3,4)]"
		sellprice = (ceil(gemtype:sellprice*(rand(0.1,0.5))))
		return
	if(icon_state=="uncut_rand")
		icon_state = "uncut_[pick(1,2,3,4,5)]"
		return

/obj/item/uncut_gem/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.4,"sx" = -1,"sy" = 0,"nx" = 11,"ny" = 1,"wx" = 0,"wy" = 1,"ex" = 4,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 15,"sturn" = 0,"wturn" = 0,"eturn" = 39,"nflip" = 8,"sflip" = 0,"wflip" = 0,"eflip" = 8)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/obj/item/uncut_gem/attackby(obj/item/W, mob/living/user, params)
	user.changeNext_move(CLICK_CD_MELEE)
	if(istype(W, /obj/item/weapon/chisel))
		if(src.gemcutting_failure==TRUE)
			to_chat(user,span_warning("This gem is a failure, I can't carve anything out of this..."))
			return FALSE
		var/list/offhand_types = typecacheof(list(/obj/item/weapon/hammer))
		var/item = user.get_inactive_held_item()
		if(user.used_intent.type == /datum/intent/chisel && is_type_in_typecache(item, offhand_types))
			var/skill_level = 0 // It makes sense, using both masonry and gemcutting skills to /chisel/ something
			skill_level += user.mind.get_skill_level(/datum/skill/craft/gemcutting)
			if(skill_level > SKILL_LEVEL_JOURNEYMAN)
				skill_level += round((user.mind.get_skill_level(/datum/skill/craft/masonry)*0.25),1)
			var/work_time = (4 SECONDS - (skill_level * 5))
			if(istype(W, /obj/item/weapon/chisel))
				var/obj/item/weapon/chisel/chisel = W
				work_time *= chisel.time_multiplier
			playsound(src.loc, pick('sound/combat/hits/onrock/onrock (1).ogg', 'sound/combat/hits/onrock/onrock (2).ogg', 'sound/combat/hits/onrock/onrock (3).ogg', 'sound/combat/hits/onrock/onrock (4).ogg'), 100)
			user.visible_message(span_info("[user] begins chiseling [src] into blocks."))
			if(do_after(user, work_time))
				var/total_gems_made = 0
				for(var/i in 1 to rand(1,ceil(skill_level*0.75))) // Get a random number of TOTAL cut gems to be made based upon your skill
					if(roll(1,20)<=(skill_level+10))
						new src.gemtype(get_turf(src.loc))
						total_gems_made++
						user.mind.add_sleep_experience(/datum/skill/craft/gemcutting, (user.STAINT*0.25))
					else
						var/obj/item/uncut_gem/failure_gem = new src.type(src.loc)
						failure_gem.gemcutting_failure = TRUE
						failure_gem.update_icon_state()
						user.mind.add_sleep_experience(/datum/skill/craft/gemcutting, (user.STAINT*0.45))
				if(prob(35))
					new /obj/effect/decal/cleanable/debris/glass(get_turf(src))
				if(total_gems_made > 0)
					playsound(src.loc, 'sound/items/gem.ogg', 100)
					to_chat(user,span_notice("I've chiseled [num2text(total_gems_made)] good [gemtype:name][total_gems_made > 1 ? "s" : ""]!"))
				else
					playsound(src.loc, 'sound/foley/hit_rock.ogg', 100)
					to_chat(user,span_warning("I ruined the [src.name]!"))
				qdel(src)
			return TRUE
	. = ..()

/obj/item/uncut_gem/green
	gemtype = /obj/item/gem/green

/obj/item/uncut_gem/blue
	gemtype = /obj/item/gem/blue

/obj/item/uncut_gem/yellow
	gemtype = /obj/item/gem/yellow

/obj/item/uncut_gem/violet
	gemtype = /obj/item/gem/violet

/obj/item/uncut_gem/diamond
	gemtype = /obj/item/gem/diamond

/obj/item/uncut_gem/red
	gemtype = /obj/item/gem/red

/obj/item/uncut_gem/black
	gemtype = /obj/item/gem/black

/obj/item/uncut_gem/amethyst
	gemtype = /obj/item/gem/amethyst

/// Riddle Of Steel
/obj/item/riddleofsteel
	name = "riddle of steel"
	icon_state = "ros"
	icon = 'icons/roguetown/items/gems.dmi'
	desc = "Flesh, mind."
	lefthand_file = 'icons/roguetown/onmob/lefthand.dmi'
	righthand_file = 'icons/roguetown/onmob/righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_MOUTH
	dropshrink = 0.4
	drop_sound = 'sound/items/gem.ogg'
	sellprice = 454

/obj/item/riddleofsteel/Initialize()
	. = ..()
	set_light(2, 2, 1, l_color = "#ff0d0d")
