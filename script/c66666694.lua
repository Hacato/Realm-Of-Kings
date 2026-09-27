-- Seafarer Undead Brawler McCallister
function c66666694.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x999),1,99)
	c:EnableReviveLimit()

	-- Set Card effect
	local e2 = Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetDescription(aux.Stringid(66666694, 0))
	e2:SetCountLimit(1)
	e2:SetTarget(c66666694.target)
	e2:SetOperation(c66666694.operation)
	c:RegisterEffect(e2)

	-- Special summon effect when destroyed
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(66666694, 1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetTarget(c66666694.sptg)
	e3:SetOperation(c66666694.spop)
	c:RegisterEffect(e3)
end

function c66666694.filter(c)
	return c:IsDestructable() and c:IsType(TYPE_SPELL + TYPE_TRAP)
end

function c66666694.filter2(c)
	return c:IsType(TYPE_SPELL + TYPE_TRAP) and c:IsAbleToChangeControler()
end

function c66666694.target(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		return Duel.IsExistingMatchingCard(c66666694.filter2, tp, 0, LOCATION_HAND, 1, nil)
			and Duel.IsExistingMatchingCard(c66666694.filter, tp, LOCATION_ONFIELD, 0, 1, nil)
	end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, nil, 1, tp, LOCATION_ONFIELD)
	Duel.SetOperationInfo(0, CATEGORY_CONTROL, nil, 1, 0, 0)
end

function c66666694.operation(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g2 = Duel.SelectTarget(tp, c66666694.filter, tp, LOCATION_ONFIELD, 0, 1, 1, nil)
	if Duel.Destroy(g2, REASON_EFFECT) ~= 0 then
		Duel.BreakEffect()
		local g = Duel.GetFieldGroup(tp, 0, LOCATION_HAND)
		if g:GetCount() > 0 then
			local tg = g:Filter(Card.IsType, nil, TYPE_SPELL + TYPE_TRAP)
			Duel.ConfirmCards(tp, tg)
			if tg:GetCount() > 0 then
				Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_CONTROL)
				local hg = tg:Select(tp, 1, 1, nil)
				local tc = hg:GetFirst()
				Duel.MoveToField(tc, tp, tp, LOCATION_SZONE, POS_FACEDOWN, true)
				Duel.ChangePosition(tc, POS_FACEDOWN)
				Duel.ConfirmCards(1 - tp, tc)
			end
			Duel.ShuffleHand(1 - tp)
		end
	end
end

function c66666694.spfilter(c, e, tp)
	return c:IsSetCard(0x999) and not c:IsCode(66666694) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function c66666694.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and c66666694.spfilter(chkc, e, tp) end
	if chk == 0 then
		return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
			and Duel.IsExistingTarget(c66666694.spfilter, tp, LOCATION_GRAVE, 0, 1, nil, e, tp)
	end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_GRAVE)
end

function c66666694.spop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
	local g = Duel.SelectMatchingCard(tp, c66666694.spfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if g:GetCount() > 0 then
		Duel.SpecialSummon(g, 0, tp, tp, false, false, POS_FACEUP)
	end
end