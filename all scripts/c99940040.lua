-- NGNL Jibril
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
	
	-- Pendulum Effect: Add NGNL Spell/Trap when NGNL monster effect activates
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	-- Monster Effect: Shuffle opponent's card(s)
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 1))
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_HAND)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.tdcon)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
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

-- Add Spell/Trap when NGNL monster effect activates
function s.thcon(e, tp, eg, ep, ev, re, r, rp)
	local rc = re:GetHandler()
	return rp == tp and rc:IsSetCard(0x994) and rc:IsType(TYPE_MONSTER)
end

function s.thfilter(c)
	return c:IsSetCard(0x994) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk == 0 then return Duel.IsExistingTarget(s.thfilter, tp, LOCATION_GRAVE, 0, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
	local g = Duel.SelectTarget(tp, s.thfilter, tp, LOCATION_GRAVE, 0, 1, 1, nil)
	Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, nil, 2, tp, LOCATION_DECK)
end

function s.thop(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoHand(tc, nil, REASON_EFFECT) > 0 
		and tc:IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp, tc)
		Duel.DiscardDeck(tp, 2, REASON_EFFECT)
	end
end

-- Shuffle opponent's card(s) condition: Opponent added card(s) except during their Draw Phase
function s.tdcon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(Card.IsControler, 1, nil, 1-tp) then return false end
	local ph = Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer() ~= 1-tp or ph ~= PHASE_DRAW
end

function s.tdtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToDeck() end
	local lp = Duel.GetFieldCard(tp, LOCATION_PZONE, 0)
	local rp = Duel.GetFieldCard(tp, LOCATION_PZONE, 1)
	local both_ngnl = lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994)
	local ct = both_ngnl and 2 or 1
	
	if chk == 0 then return Duel.IsExistingTarget(Card.IsAbleToDeck, tp, 0, LOCATION_ONFIELD, 1, nil) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
	local g = Duel.SelectTarget(tp, Card.IsAbleToDeck, tp, 0, LOCATION_ONFIELD, 1, ct, nil)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, g, #g, 0, 0)
end

function s.tdop(e, tp, eg, ep, ev, re, r, rp)
	local g = Duel.GetTargetCards(e)
	if #g > 0 then
		Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
	end
end