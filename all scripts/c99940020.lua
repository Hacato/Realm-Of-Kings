-- NGNL Shiro
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
	
	-- Pendulum Effect: Roll die to increase scale
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1)
	e2:SetTarget(s.dietg)
	e2:SetOperation(s.dieop)
	c:RegisterEffect(e2)
	
	-- Monster Effect: Mill 1, opponent discards when they add to hand
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.discon)
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
end

s.listed_series = {0x994}
s.roll_dice = true

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

-- Die roll effect target
function s.scfilter(c)
	return c:IsSetCard(0x994) and c:IsFaceup()
end

function s.dietg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_PZONE) and s.scfilter(chkc) end
	if chk == 0 then return Duel.IsExistingTarget(s.scfilter, tp, LOCATION_PZONE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
	Duel.SelectTarget(tp, s.scfilter, tp, LOCATION_PZONE, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_DICE, nil, 0, tp, 1)
end

function s.dieop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local d = Duel.TossDice(tp, 1)
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LSCALE)
		e1:SetValue(d)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2 = e1:Clone()
		e2:SetCode(EFFECT_UPDATE_RSCALE)
		tc:RegisterEffect(e2)
	end
end

-- Discard effect condition: Opponent added card(s) except during their Draw Phase
function s.discon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(Card.IsControler, 1, nil, 1-tp) then return false end
	local ph = Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer() ~= 1-tp or ph ~= PHASE_DRAW
end

function s.distg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDiscardDeck(tp, 1) end
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 1, tp, LOCATION_DECK)
	Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, 1-tp, 1)
end

function s.disop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.DiscardDeck(tp, 1, REASON_EFFECT) > 0 then
		-- Check if both Pendulum Zones have NGNL cards
		local lp = Duel.GetFieldCard(tp, LOCATION_PZONE, 0)
		local rp = Duel.GetFieldCard(tp, LOCATION_PZONE, 1)
		local discard_count = 1
		if lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994) then
			discard_count = 2
		end
		
		local g = Duel.GetFieldGroup(tp, 0, LOCATION_HAND)
		if #g > 0 then
			local sg = g:RandomSelect(1-tp, math.min(discard_count, #g))
			Duel.SendtoGrave(sg, REASON_EFFECT+REASON_DISCARD)
		end
	end
end