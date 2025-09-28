-- Rise Of The Dovakin
-- Field Spell
-- scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: optionally shuffle up to 6 banished "Dovakin" into the Deck, opponent gains 500 LP if you do
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetCategory(CATEGORY_TODECK+CATEGORY_RECOVER)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetTarget(s.acttg)
	e0:SetOperation(s.actop)
	c:RegisterEffect(e0)

	-- (1) Once per turn: discard 1, send 2 "Dovakin" monsters from Deck to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.gycost)
	e1:SetTarget(s.gytg)
	e1:SetOperation(s.gyop)
	c:RegisterEffect(e1)

	-- (2) Once per turn: Negate opponent's monster effect in hand by banishing 1 "Dovakin" from Deck, then banish that monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

-- FILTERS
function s.dovakin(c)
	return c:IsSetCard(0x2411)
end
function s.dovakinMonster(c)
	return c:IsSetCard(0x2411) and c:IsType(TYPE_MONSTER)
end

-- Activate: allow activation always, shuffle if you want and if available
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end  -- Always allow activation!
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,1-tp,500)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.dovakin,tp,LOCATION_REMOVED,0,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3) or "Shuffle up to 6 banished 'Dovakin' cards into your Deck?") then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=g:Select(tp,1,6,nil)
		if #sg>0 then
			Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			Duel.BreakEffect()
			Duel.Recover(1-tp,500,REASON_EFFECT)
		end
	end
end

-- (1) Discard cost
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
-- (1) Send 2 "Dovakin" monsters to GY
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dovakinMonster,tp,LOCATION_DECK,0,2,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,30459350) then return end -- Macro Cosmos lock check
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.dovakinMonster,tp,LOCATION_DECK,0,2,2,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- (2) Negate opponent's monster in hand
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not re:IsActiveType(TYPE_MONSTER) then return false end
	local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
	return loc==LOCATION_HAND and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dovakin,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.dovakin,tp,LOCATION_DECK,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,re:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,re:GetHandler(),1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if rc and rc:IsRelateToEffect(re) then
			Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
		end
	end
end