--Lavatos The ThunderLord Of The Dovakin
local s,id=GetID()
function s.initial_effect(c)
	-- Ritual: handled by your Ritual Spell (900000055). Don't call aux ritual helpers here.
	c:EnableReviveLimit()
	s.listed_names={900000055}
	s.listed_series={0x2411}

	-- Cannot be targeted by opponent's card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	-- Once per turn: send 1 Dovakin Extra Deck monster to GY; gain its ATK until end of next turn
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	-- Once per turn (Quick): when opponent activates an effect that would destroy/banish/send your field card(s),
	-- you may banish 1 Dovakin from YOUR Deck as cost to rewrite that effect so the original activator
	-- MUST add 1 Dovakin from THEIR Deck to their hand. (Dark Deal pattern)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.chcon)
	e3:SetCost(s.chcost)
	e3:SetOperation(s.chop)
	c:RegisterEffect(e3)
end

-- filter: Extra Deck Dovakin monsters to send to GY for ATK gain
function s.atkfilter(c)
	return c:IsSetCard(0x2411) and c:IsMonster() and c:IsAbleToGrave()
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.atkfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c or not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.atkfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g==0 then return end
	if Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
		local atk=g:GetFirst():GetBaseAttack() or 0
		if atk<0 then atk=0 end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		-- lasts until the end of the next turn
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
		c:RegisterEffect(e1)
	end
end

-- -------- Replacement (Dark Deal style) ----------
-- Condition: opponent activated something; it has a destroy/remove/tograve category,
-- and (if it targets) it targets your card(s) OR it's a non-targeting board effect.
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	if rp~=1-tp then return false end
	if not re:IsActivated() then return false end
	-- Only consider effects that have those categories
	if not (re:IsHasCategory(CATEGORY_DESTROY) or re:IsHasCategory(CATEGORY_REMOVE) or re:IsHasCategory(CATEGORY_TOGRAVE)) then
		return false
	end
	-- If it targets, require it to target at least one of your on-field cards (defensive case).
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	if tg then
		if not tg:IsExists(function(c) return c:IsControler(tp) and c:IsOnField() end,1,nil) then
			-- it targets, but not your cards -> skip
			return false
		end
	end
	-- Also require that YOU have at least one Dovakin in YOUR deck to pay as cost (fail-safe).
	return Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x2411) and c:IsMonster() and c:IsAbleToRemoveAsCost() end, tp, LOCATION_DECK, 0, 1, nil)
end

-- Cost: banish 1 Dovakin from YOUR deck as cost.
-- Also require opponent actually has a Dovakin in THEIR deck (so the rewrite won't force a fizzle).
function s.chcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local you_can = Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x2411) and c:IsMonster() and c:IsAbleToRemoveAsCost() end, tp, LOCATION_DECK, 0, 1, nil)
		local opp_has = Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x2411) and c:IsAbleToHand() end, 1-tp, LOCATION_DECK, 0, 1, nil)
		return you_can and opp_has
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp, function(c) return c:IsSetCard(0x2411) and c:IsMonster() and c:IsAbleToRemoveAsCost() end, tp, LOCATION_DECK, 0, 1, 1, nil)
	if #g>0 then Duel.Remove(g,POS_FACEUP,REASON_COST) end
end

-- Operation: rewrite the chain (Dark Deal pattern) — only done if both sides had valid cards (chcost ensured that)
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	-- Clear original targets and replace the chain operation
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)
	Duel.ChangeChainOperation(ev,s.repop)
end

-- New operation: force the original activator (opponent) to add 1 Dovakin from THEIR deck to THEIR hand (mandatory if they have one)
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local p=1-tp -- the original activator (opponent relative to Lavatos' controller)
	local sg=Duel.GetMatchingGroup(function(c) return c:IsSetCard(0x2411) and c:IsAbleToHand() end, p, LOCATION_DECK, 0, nil)
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_ATOHAND)
		local sc=sg:Select(p,1,1,nil):GetFirst()
		if sc then
			Duel.SendtoHand(sc,p,REASON_EFFECT)
			Duel.ConfirmCards(1-p,sc) -- show to Lavatos' controller
		end
	end
	-- if opponent has no Dovakin in deck, nothing happens (we prevented this situation with chcost)
end
