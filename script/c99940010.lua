-- NGNL Sora
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
	
	-- Pendulum Effect: Coin toss search or mill
	local e3 = Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id, 0))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.cointg)
	e3:SetOperation(s.coinop)
	c:RegisterEffect(e3)
	
	-- Monster Effect: Draw 2 when opponent adds to hand
	local e4 = Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id, 1))
	e4:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_HAND)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.drcon)
	e4:SetTarget(s.drtg)
	e4:SetOperation(s.drop)
	c:RegisterEffect(e4)
end

s.listed_series = {0x994}
s.toss_coin = true

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

-- Coin toss effect target
function s.thfilter(c)
	return c:IsSetCard(0x994) and c:IsAbleToHand()
end

function s.cointg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsExistingMatchingCard(s.thfilter, tp, LOCATION_DECK, 0, 1, nil) end
	Duel.SetOperationInfo(0, CATEGORY_COIN, nil, 0, tp, 1)
end

function s.coinop(e, tp, eg, ep, ev, re, r, rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	-- Player calls heads (1) or tails (0)
	local call = Duel.SelectOption(tp, 60, 61) -- 60=Heads, 61=Tails
	local res = Duel.TossCoin(tp, 1)
	if call ~= res then
		-- Called it right: Add 1 NGNL card
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
		local g = Duel.SelectMatchingCard(tp, s.thfilter, tp, LOCATION_DECK, 0, 1, 1, nil)
		if #g > 0 then
			Duel.SendtoHand(g, nil, REASON_EFFECT)
			Duel.ConfirmCards(1-tp, g)
		end
	else
		-- Called it wrong: Mill 1
		Duel.DiscardDeck(tp, 1, REASON_EFFECT)
	end
end

-- Draw effect condition: Opponent added card(s) except during their Draw Phase
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
	if not eg:IsExists(Card.IsControler, 1, nil, 1-tp) then return false end
	local ph = Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer() ~= 1-tp or ph ~= PHASE_DRAW
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return Duel.IsPlayerCanDraw(tp, 2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 2)
	Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 2, tp, LOCATION_HAND)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
	local p, d = Duel.GetChainInfo(0, CHAININFO_TARGET_PLAYER, CHAININFO_TARGET_PARAM)
	if Duel.Draw(p, d, REASON_EFFECT) > 0 then
		-- Check if both Pendulum Zones have NGNL cards
		local lp = Duel.GetFieldCard(tp, LOCATION_PZONE, 0)
		local rp = Duel.GetFieldCard(tp, LOCATION_PZONE, 1)
		local shuffle_count = 2
		if lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994) then
			shuffle_count = 1
		end
		
		Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TODECK)
		local g = Duel.SelectMatchingCard(tp, Card.IsAbleToShuffleIntoDeck, tp, LOCATION_HAND, 0, shuffle_count, shuffle_count, nil)
		if #g > 0 then
			Duel.SendtoDeck(g, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
		end
	end
end