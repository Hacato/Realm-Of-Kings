-- Seafarer Undead Unagi
function c66666696.initial_effect(c)
	--Synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x999),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	-- Cannot be destroyed by battle
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- Destroy own S/T and set from opponent's graveyard
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(66666696, 0))
	e2:SetCategory(CATEGORY_DESTROY + CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(c66666696.settg)
	e2:SetOperation(c66666696.setop)
	c:RegisterEffect(e2)

	-- ATK increase: 100 ATK for each S/T in your Spell/Trap Zone
	local e3 = Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(c66666696.atkval)
	c:RegisterEffect(e3)
end

-- ATK value calculation: 100 per S/T in Spell/Trap Zone
function c66666696.atkval(e, c)
	local tp = c:GetControler()
	local g = Duel.GetMatchingGroup(Card.IsType, tp, LOCATION_SZONE, 0, nil, TYPE_SPELL + TYPE_TRAP)
	return g:GetCount() * 100
end

-- Filter: Destructable S/T on your field
function c66666696.cstfilter(c)
	return c:IsDestructable() and c:IsType(TYPE_SPELL + TYPE_TRAP)
end

-- Filter: S/T in opponent's graveyard that can be set
function c66666696.setfilter(c, tp)
	return c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsSSetable(true) and (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp, LOCATION_SZONE) > 0)
end

-- Target check
function c66666696.settg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(c66666696.cstfilter, tp, LOCATION_ONFIELD, 0, 1, nil)
			and Duel.IsExistingMatchingCard(c66666696.setfilter, tp, 0, LOCATION_GRAVE, 1, nil, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, tp, LOCATION_ONFIELD)
	Duel.SetOperationInfo(0, CATEGORY_LEAVE_GRAVE, nil, 1, 0, 0)
end

-- Operation: Destroy 1 own S/T, then set 1 opponent's S/T from graveyard
function c66666696.setop(e, tp, eg, ep, ev, re, r, rp)
	-- Check if there's still a S/T to destroy
	if not Duel.IsExistingMatchingCard(c66666696.cstfilter, tp, LOCATION_ONFIELD, 0, 1, nil) then return end
	
	-- Select and destroy 1 own S/T
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local cst = Duel.SelectMatchingCard(tp, c66666696.cstfilter, tp, LOCATION_ONFIELD, 0, 1, 1, nil)
	
	-- If destruction was successful
	if Duel.Destroy(cst, REASON_EFFECT) ~= 0 then
		Duel.BreakEffect()
		
		-- Select and set 1 opponent's S/T from their graveyard
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SET)
		local g = Duel.SelectMatchingCard(tp, c66666696.setfilter, tp, 0, LOCATION_GRAVE, 1, 1, nil, tp)
		
		if g:GetCount() > 0 then
			local tc = g:GetFirst()
			-- Set the card on your side of the field
			Duel.SSet(tp, tc)
			-- Confirm to opponent
			Duel.ConfirmCards(1 - tp, tc)
		end
	end
end