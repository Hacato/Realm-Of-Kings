-- Seafarer Deckhand Pietro
function c77777922.initial_effect(c)
	-- Link summon: 2 WATER Zombie or Warrior monsters
	c:EnableReviveLimit()
	Link.AddProcedure(c, c77777922.sumfilter, 2)

	-- Special summon from deck when link summoned (ONCE PER TURN)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(77777922, 0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1, 77777922)
	e1:SetCondition(c77777922.hspcon)
	e1:SetTarget(c77777922.hsptg)
	e1:SetOperation(c77777922.hspop)
	c:RegisterEffect(e1)

	-- Set from either player's graveyard (ONCE PER TURN)
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(77777922, 1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCountLimit(1)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetTarget(c77777922.settg)
	e2:SetOperation(c77777922.setop)
	c:RegisterEffect(e2)
end

-- Link material filter: 2 WATER Zombie or Warrior monsters
function c77777922.sumfilter(c, lc, sumtype, tp)
	return c:IsAttribute(ATTRIBUTE_WATER, lc, sumtype, tp) 
		and c:IsRace(RACE_WARRIOR + RACE_ZOMBIE, lc, sumtype, tp)
end

-- Condition: Card was Link Summoned
function c77777922.hspcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- Filter: "Seafarer" monsters that can be special summoned
function c77777922.hspfilter(c, e, tp)
	return c:IsSetCard(0x999) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false, POS_FACEUP)
end

-- Target check for special summon
function c77777922.hsptg(e, tp, eg, ep, ev, re, r, rp, chk)
	local zone = e:GetHandler():GetLinkedZone(tp)
	if chk == 0 then
		return zone > 0 and Duel.IsExistingMatchingCard(c77777922.hspfilter, tp, LOCATION_DECK, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_DECK)
end

-- Operation: Special summon from deck to linked zone
function c77777922.hspop(e, tp, eg, ep, ev, re, r, rp)
	local zone = e:GetHandler():GetLinkedZone(tp)
	if zone <= 0 then return end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, c77777922.hspfilter, tp, LOCATION_DECK, 0, 1, 1, nil, e, tp)
	if g:GetCount() > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP, zone)
	end
end

-- Filter: S/T in either player's graveyard that can be set
function c77777922.setfilter(c, tp)
	return c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSSetable(true) and (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp, LOCATION_SZONE) > 0)
end

-- Target check for set effect (targets from EITHER player's GY)
function c77777922.settg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and c77777922.setfilter(chkc, tp) end
	if chk == 0 then return Duel.IsExistingTarget(c77777922.setfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, nil, tp) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
	local g = Duel.SelectTarget(tp, c77777922.setfilter, tp, LOCATION_GRAVE, LOCATION_GRAVE, 1, 1, nil, tp)
	Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, g, 1, 0, 0)
end

-- Operation: Set S/T from graveyard on your field, cannot activate this turn
function c77777922.setop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and (tc:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp, LOCATION_SZONE) > 0) then
		if Duel.SSet(tp, tc) ~= 0 then
			-- Set card cannot trigger its effects this turn
			local e1 = Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CANNOT_TRIGGER)
			e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
			tc:RegisterEffect(e1)
		end
		Duel.ConfirmCards(1 - tp, tc)
	end
end