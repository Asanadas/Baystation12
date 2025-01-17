/obj/item/device/suit_cooling_unit
	name = "portable cooling unit"
	desc = "A large portable heat sink with liquid cooled radiator packaged into a modified backpack."
	w_class = ITEM_SIZE_LARGE
	icon = 'icons/obj/suitcooler.dmi'
	icon_state = "suitcooler0"
	item_state = "coolingpack"
	slot_flags = SLOT_BACK

	//copied from tank.dm
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 5.0
	throwforce = 10.0
	throw_speed = 1
	throw_range = 4
	action_button_name = "Toggle Heatsink"

	matter = list(MATERIAL_ALUMINIUM = 15000, MATERIAL_GLASS = 3500)
	origin_tech = list(TECH_MAGNET = 2, TECH_MATERIAL = 2)

	var/on = 0								//is it turned on?
	var/cover_open = 0						//is the cover open?
	var/obj/item/cell/cell
	var/max_cooling = 12					// in degrees per second - probably don't need to mess with heat capacity here
	var/charge_consumption = 2 KILOWATTS	// energy usage at full power
	var/thermostat = T20C

/obj/item/device/suit_cooling_unit/ui_action_click()
	toggle(usr)

/obj/item/device/suit_cooling_unit/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	cell = new/obj/item/cell/high()		// 10K rated cell.
	cell.forceMove(src)

/obj/item/device/suit_cooling_unit/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/device/suit_cooling_unit/Process()
	if (!on || !cell)
		return

	if (!is_in_slot())
		return

	var/mob/living/carbon/human/H = loc

	var/temp_adj = min(H.bodytemperature - thermostat, max_cooling)

	if (temp_adj < 0.5)	//only cools, doesn't heat, also we don't need extreme precision
		return

	var/charge_usage = (temp_adj/max_cooling)*charge_consumption

	H.bodytemperature -= temp_adj

	cell.use(charge_usage * CELLRATE)
	update_icon()

	if(cell.charge <= 0)
		turn_off(1)

// Checks whether the cooling unit is being worn on the back/suit slot.
// That way you can't carry it in your hands while it's running to cool yourself down.
/obj/item/device/suit_cooling_unit/proc/is_in_slot()
	var/mob/living/carbon/human/H = loc
	if(!istype(H))
		return 0

	return (H.back == src) || (H.s_store == src)

/obj/item/device/suit_cooling_unit/proc/turn_on()
	if(!cell)
		return
	if(cell.charge <= 0)
		return

	on = 1
	update_icon()

/obj/item/device/suit_cooling_unit/proc/turn_off(failed)
	if(failed) visible_message("\The [src] clicks and whines as it powers down.")
	on = 0
	update_icon()

/obj/item/device/suit_cooling_unit/attack_self(mob/user)
	if(cover_open && cell)
		if(ishuman(user))
			user.put_in_hands(cell)
		else
			cell.dropInto(loc)

		cell.add_fingerprint(user)
		cell.update_icon()

		to_chat(user, "You remove \the [src.cell].")
		src.cell = null
		update_icon()
		return

	toggle(user)

/obj/item/device/suit_cooling_unit/proc/toggle(mob/user)
	if(on)
		turn_off()
	else
		turn_on()
	to_chat(user, "<span class='notice'>You switch \the [src] [on ? "on" : "off"].</span>")

/obj/item/device/suit_cooling_unit/attackby(obj/item/W as obj, mob/user as mob)
	if(isScrewdriver(W))
		if(cover_open)
			cover_open = 0
			to_chat(user, "You screw the panel into place.")
		else
			cover_open = 1
			to_chat(user, "You unscrew the panel.")
		playsound(src, 'sound/items/Screwdriver.ogg', 50, 1)
		update_icon()
		return

	if (istype(W, /obj/item/cell))
		if(cover_open)
			if(cell)
				to_chat(user, "There is a [cell] already installed here.")
			else
				if(!user.unEquip(W, src))
					return
				cell = W
				to_chat(user, "You insert the [cell].")
		update_icon()
		return

	return ..()

/obj/item/device/suit_cooling_unit/on_update_icon()
	overlays.Cut()
	if (cover_open)
		if (cell)
			icon_state = "suitcooler1"
		else
			icon_state = "suitcooler2"
		return

	icon_state = "suitcooler0"

	if(!cell || !on)
		return

	switch(round(cell.percent()))
		if(86 to INFINITY)
			overlays.Add("battery-0")
		if(69 to 85)
			overlays.Add("battery-1")
		if(52 to 68)
			overlays.Add("battery-2")
		if(35 to 51)
			overlays.Add("battery-3")
		if(18 to 34)
			overlays.Add("battery-4")
		if(-INFINITY to 17)
			overlays.Add("battery-5")


/obj/item/device/suit_cooling_unit/examine(mob/user, distance)
	. = ..()
	if(distance >= 1)
		return

	if (on)
		to_chat(user, "It's switched on and running.")
	else
		to_chat(user, "It is switched off.")

	if (cover_open)
		to_chat(user, "The panel is open.")

	if (cell)
		to_chat(user, "The charge meter reads [round(cell.percent())]%.")
