--Aquamarine Physalia
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Material: 1 "Aquamarine" Fusion Monster + 1 "Aquamarine" monster
	Fusion.AddProcMix(c,true,true,s.ffilter1,s.ffilter2)
	
	--Quick Effect: Banish 1 "Aquamarine" card from GY; destroy 1 card opponent controls
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetCondition(s.descon)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	
	--Prevent opponent from activating monster effects in response if "Aquamarine Glaucus" is controlled
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.actlimitcon)
	e2:SetValue(s.actlimitval)
	c:RegisterEffect(e2)
end
s.listed_names={800000037} --Aquamarine Glaucus
s.listed_series={0x30cd} --Aquamarine

--Fusion material filters
function s.ffilter1(c)
	return c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION)
end
function s.ffilter2(c)
	return c:IsSetCard(0x30cd)
end

--Condition: Can only be used during Main Phase and not chaining to itself
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsMainPhase() then return false end
	--Check if this effect is already in the current chain
	local chain_count=Duel.GetCurrentChain()
	if chain_count>0 then
		for i=1,chain_count do
			local ce,cp=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
			if ce and cp==tp and ce:GetHandler():IsCode(id) and ce:GetDescription()==aux.Stringid(id,0) then
				return false
			end
		end
	end
	return true
end

--Cost: Banish 1 "Aquamarine" card from GY
function s.descostfilter(c)
	return c:IsSetCard(0x30cd) and c:IsAbleToRemove()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.descostfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.descostfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

--Target: 1 card opponent controls
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		--Check if effect can be used (based on number of Level 7+ "Aquamarine" monsters controlled)
		local ct=Duel.GetMatchingGroupCount(s.lvfilter,tp,LOCATION_MZONE,0,e:GetHandler())
		local used=e:GetHandler():GetFlagEffect(id)
		return ct>used and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	--Additional check to prevent overuse during resolution
	local ct=Duel.GetMatchingGroupCount(s.lvfilter,tp,LOCATION_MZONE,0,e:GetHandler())
	local used=e:GetHandler():GetFlagEffect(id)
	if ct<=used then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

--Filter for Level 7+ "Aquamarine" monsters (except "Aquamarine Physalia")
function s.lvfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and c:IsLevelAbove(7) and not c:IsCode(id)
end

--Operation: Destroy the targeted card and register effect usage
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	--Final check to ensure we don't exceed the limit
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ct=Duel.GetMatchingGroupCount(s.lvfilter,tp,LOCATION_MZONE,0,c)
	local used=c:GetFlagEffect(id)
	if ct<=used then return end
	
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
	--Register that this effect was used this turn
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

--Condition: "Aquamarine Glaucus" is controlled
function s.actlimitcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,800000037),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--Value: Cannot activate monster effects in response to this card's effect
function s.actlimitval(e,re,tp)
	if not (re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsMonster()) then return false end
	local chain_count=Duel.GetCurrentChain()
	if chain_count==0 then return false end
	--Check if any effect in the current chain is from this card
	for i=1,chain_count do
		local ce=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT)
		if ce and ce:GetHandler()==e:GetHandler() and ce:GetDescription()==aux.Stringid(e:GetHandler():GetOriginalCode(),0) then
			return true
		end
	end
	return false
end