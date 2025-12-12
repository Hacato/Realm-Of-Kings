--Paladin Of The Dovakin
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon itself + 1 Dovakin from Deck/Banished
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Discard to banish 1 Dovakin from Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.bancost)
	e2:SetTarget(s.bantg)
	e2:SetOperation(s.banop)
	c:RegisterEffect(e2)
end
s.listed_series={0x2411}

--Effect 1: Special Summon condition
function s.cfilter(c)
	return c:IsSetCard(0x2411)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Effect 1: target
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2411) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		return ft>0 and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK+LOCATION_REMOVED)
end

--Effect 1: operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not c:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end

--Effect 2: discard cost
function s.bancost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

--Effect 2: banish target
function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end

--Effect 2: banish operation
function s.banop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end
