-- NGNL Stephanie Dola
local s, id = GetID()
function s.initial_effect(c)
	-- Pendulum Summon
	Pendulum.AddProcedure(c)
	
	-- Pendulum Effect: Set Scale equal to hand count when placed
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_MOVE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCondition(s.sccon)
	e1:SetOperation(s.scop)
	c:RegisterEffect(e1)
	
	-- Pendulum Effect: Negate activation and place NGNL card
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_PZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetCountLimit(1, id)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
	
	-- Monster Effect: Shuffle monster and Special Summon
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series = {0x994}

-- Check if card was just placed in Pendulum Zone
function s.sccon(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	return c:IsPreviousLocation(LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_EXTRA+LOCATION_REMOVED) 
		and c:IsLocation(LOCATION_PZONE)
end

-- Set the Pendulum Scale to current hand count
function s.scop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local ct = Duel.GetFieldGroupCount(tp, LOCATION_HAND, 0)
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LSCALE)
	e1:SetValue(ct)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
	c:RegisterEffect(e1)
	local e2 = e1:Clone()
	e2:SetCode(EFFECT_UPDATE_RSCALE)
	c:RegisterEffect(e2)
end

-- Negate effect
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
	return rp == 1-tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsAbleToDeckAsCost() end
	Duel.SendtoDeck(e:GetHandler(), nil, SEQ_DECKSHUFFLE, REASON_COST)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return true end
	Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

function s.penfilter(c)
	return c:IsSetCard(0x994) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.NegateActivation(ev) then
		local g = Duel.GetMatchingGroup(s.penfilter, tp, LOCATION_EXTRA, 0, nil)
		if #g > 0 and Duel.CheckPendulumZones(tp) 
			and Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TOFIELD)
			local sg = g:Select(tp, 1, 1, nil)
			if #sg > 0 then
				Duel.MoveToField(sg:GetFirst(), tp, tp, LOCATION_PZONE, POS_FACEUP, true)
			end
		end
	end
end

-- Special Summon effect condition: Opponent added card(s) except during their Draw Phase
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(Card.IsControler, 1, nil, 1-tp) then return false end
	local ph = Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer() ~= 1-tp or ph ~= PHASE_DRAW
end

function s.tdfilter(c)
	return c:IsSetCard(0x994) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeck() and c:IsFaceup()
end

function s.tdpfilter(c)
	return c:IsSetCard(0x994) and c:IsAbleToDeck()
end

function s.spfilter(c, e, tp, code)
	return c:IsSetCard(0x994) and c:IsType(TYPE_MONSTER) and not c:IsCode(code)
		and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then
		local lp = Duel.GetFieldCard(tp, LOCATION_PZONE, 0)
		local rp = Duel.GetFieldCard(tp, LOCATION_PZONE, 1)
		local both_ngnl = lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994)
		
		if both_ngnl then
			return Duel.IsExistingMatchingCard(s.tdpfilter, tp, LOCATION_PZONE, 0, 1, nil)
				and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
				and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND+LOCATION_DECK, 0, 1, nil, e, tp, 0)
		else
			return Duel.IsExistingMatchingCard(s.tdfilter, tp, LOCATION_MZONE, 0, 1, nil)
				and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
				and Duel.IsExistingMatchingCard(s.spfilter, tp, LOCATION_HAND+LOCATION_DECK, 0, 1, nil, e, tp, 0)
		end
	end
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_MZONE+LOCATION_PZONE)
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_HAND+LOCATION_DECK)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
	local lp = Duel.GetFieldCard(tp, LOCATION_PZONE, 0)
	local rp = Duel.GetFieldCard(tp, LOCATION_PZONE, 1)
	local both_ngnl = lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994)
	
	local g = nil
	if both_ngnl then
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
		g = Duel.SelectMatchingCard(tp, s.tdpfilter, tp, LOCATION_PZONE, 0, 1, 1, nil)
	else
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
		g = Duel.SelectMatchingCard(tp, s.tdfilter, tp, LOCATION_MZONE, 0, 1, 1, nil)
	end
	
	if #g > 0 then
		local tc = g:GetFirst()
		if Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 
			and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA)
			and Duel.GetLocationCount(tp, LOCATION_MZONE) > 0 then
			Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
			local sg = Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_HAND+LOCATION_DECK, 0, 1, 1, nil, e, tp, tc:GetCode())
			if #sg > 0 then
				Duel.SpecialSummon(sg, 0, tp, tp, false, false, POS_FACEUP)
			end
		end
	end
end