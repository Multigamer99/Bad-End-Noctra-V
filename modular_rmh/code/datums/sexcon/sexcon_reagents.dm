/datum/reagent/consumable/ethanol/beer/emberwine
    name = "Emberwine"
    boozepwr = 10
    taste_description = "searing sweetness"
    taste_mult = 0.5
    quality = DRINK_VERYGOOD
    metabolization_rate = 0.02 * REAGENTS_METABOLISM
    overdose_threshold = 16
    addiction_threshold = 24
    var/addiction_permanent = TRUE
    color = "#721a46"

/datum/reagent/consumable/ethanol/beer/emberwine/on_mob_metabolize(mob/living/carbon/human/C)
    ..()
    SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, 5)

/datum/reagent/consumable/ethanol/beer/emberwine/on_mob_end_metabolize(mob/living/carbon/human/C)
    ..()
    SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, -5)

/datum/reagent/consumable/ethanol/beer/emberwine/on_mob_life(mob/living/carbon/human/C)
    var/high_message = pick(
        "Your stomach feels hot.",
        "Your skin feels prickly to the touch.",
        "Your loins throb involuntarily.",
        "Your heart beats irregularly.",
        "You feel cold sweat running down your neck.",)

    switch(current_cycle)
        if(0 to 19)
            current_cycle++
            return

        if(20)
            to_chat(C, "<span class='aphrodisiac'>You feel a warm glow spreading through your stomach.</span>")

        if(21 to 25)
            SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, 5)

        if(26 to INFINITY)
            C.apply_status_effect(/datum/status_effect/debuff/emberwine)

            if(prob(8))
                if(C.silent || !C.can_speak())
                    C.emote("sexmoangag_org", forced = TRUE)
                else
                    C.emote("sexmoanlight", forced = TRUE)

                to_chat(C, "<span class='love_high'>[high_message]</span>")

                if(istype(C.wear_armor, /obj/item/clothing))
                    var/obj/item/clothing/CL = C.wear_armor

                    switch(CL.armor_class)
                        if(3)
                            C.Immobilize(30)
                            C.set_blurriness(5)
                            to_chat(C, "<span class='warning'>Your armor chaffs uncomfortably against your skin and makes it difficult to breathe.</span>")

                        if(2)
                            C.Immobilize(15)
                            C.set_blurriness(2)
                            to_chat(C, "<span class='warning'>Your armor chaffs uncomfortably against your skin.</span>")

    return ..()

/datum/reagent/consumable/ethanol/beer/emberwine/overdose_start(mob/living/carbon/human/C)
    if(current_cycle < 20)
        current_cycle = 20
        to_chat(C, "<span class='aphrodisiac'>You feel a warm glow spreading through your stomach.</span>")
        sleep(10)

    to_chat(C, "<span class='aphrodisiac'>The glow in your stomach spreads, rushing to your head and warming your face.</span>")
    metabolization_rate = 0.1 * REAGENTS_METABOLISM
    SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, 10)

    if(C.silent || !C.can_speak())
        C.emote("sexmoangag_org", forced = TRUE)
    else
        C.emote("sexmoanlight", forced = TRUE)

/datum/reagent/consumable/ethanol/beer/emberwine/overdose_process(mob/living/carbon/human/C)
    if(prob(5))
        if(C.silent || !C.can_speak())
            C.emote("sexmoangag_org", forced = TRUE)
        else
            C.emote("sexmoanmed", forced = TRUE)

        SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, 5)

/datum/reagent/consumable/ethanol/beer/emberwine/addiction_act_stage3(mob/living/carbon/human/C)
    SEND_SIGNAL(C, COMSIG_SEX_ADJUST_AROUSAL, 5)

    if(prob(20))
        to_chat(C, span_danger("I have an intense craving for Emberwine."))

    var/mob/living/carbon/human/H = C
    if(!istype(H.charflaw, /datum/charflaw/addiction/lovefiend))
        H.charflaw = new /datum/charflaw/addiction/lovefiend(H)

/datum/reagent/consumable/ethanol/beer/emberwine/addiction_act_stage4(mob/living/carbon/human/C)
    SEND_SIGNAL(C, COMSIG_SEX_SET_AROUSAL, 40)

    if(prob(10))
        to_chat(C, span_boldannounce("The feeling in your loins has subsided to a dull ache. I NEED TO scratch the itch..."))
