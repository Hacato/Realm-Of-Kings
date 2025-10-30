--Fate Ascended Ruler, Jeanne d'Arc
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Cannot be Normal Summoned/Set, must be Special Summoned by "Fate Ruler, Jeanne d'Arc"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--Effect 1: Add "Fate Ruler, Jeanne d'Arc" from Deck, shuffle this card back
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--Effect 2: Place Relic Counter when "Fate" monster(s) added to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.ctcon)
	e2:SetTarget(s.cttg)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
	--Effect 3: Negate targeting and grant immunity
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_NEGATE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_BECOME_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
	--Effect 4: Place Relic Counter when this card leaves the field
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_COUNTER)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCondition(s.ct2con)
	e4:SetOperation(s.ct2op)
	c:RegisterEffect(e4)
end
s.listed_names={800000079}
s.listed_series={0x989}
s.counter_place_list={0x1997}

--Must be Special Summoned by "Fate Ruler, Jeanne d'Arc"
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsCode(800000079)
end

--Effect 1: Add "Fate Ruler, Jeanne d'Arc" from Deck, shuffle this card back
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
end
function s.thfilter(c)
	return c:IsCode(800000079) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and e:GetHandler():IsAbleToDeck() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
		Duel.ConfirmCards(1-tp,g)
		if c:IsRelateToEffect(e) then
			Duel.BreakEffect()
			Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

--Effect 2: Place Relic Counter when "Fate" monster(s) added to hand
function s.ctfilter(c,tp)
	return c:IsSetCard(0x989) and c:IsMonster() and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK+LOCATION_GRAVE)
end
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_FZONE,0,1,nil) end
	local g=eg:Filter(s.ctfilter,nil,tp)
	Duel.SetTargetCard(g)
end
function s.fieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x989) and c:IsType(TYPE_FIELD) and c:IsCanAddCounter(0x1997,1)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e):Filter(s.ctfilter,nil,tp)
	if #g>0 then
		local ct=0
		for tc in aux.Next(g) do
			if tc:IsPublic() then
				ct=ct+1
			else
				Duel.ConfirmCards(1-tp,tc)
				ct=ct+1
			end
		end
		if ct>0 then
			local fc=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_FZONE,0,nil):GetFirst()
			if fc then
				fc:AddCounter(0x1997,1)
			end
		end
	end
end

--Effect 3: Negate targeting and grant immunity
function s.negfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsSetCard(0x989) and c:IsMonster() and c:IsLocation(LOCATION_MZONE)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.negfilter,1,e:GetHandler(),tp) and rp==1-tp
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.negfilter,e:GetHandler(),tp)
	if Duel.NegateEffect(ev) and #g>0 then
		local tc=g:GetFirst()
		while tc do
			--Register flag effect to mark monster as immune
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,4))
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_IMMUNE_EFFECT)
			e1:SetValue(s.efilter)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			e1:SetOwnerPlayer(tp)
			tc:RegisterEffect(e1)
			tc=g:GetNext()
		end
	end
end
function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end

--Effect 4: Place Relic Counter when this card leaves the field
function s.ct2con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP)
end
function s.ct2op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_FZONE,0,nil)
	if #g>0 then
		local tc=g:GetFirst()
		tc:AddCounter(0x1997,1)
	end
end