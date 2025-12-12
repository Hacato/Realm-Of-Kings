--Slayer-Thaiasa The Sacred Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as every attribute
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_ATTRIBUTE)
	e0:SetRange(LOCATION_ALL)
	e0:SetValue(ATTRIBUTE_ALL)
	c:RegisterEffect(e0)
	
	--Additional Normal Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetRange(LOCATION_HAND)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsCode,id))
	e1:SetCondition(s.sumcon)
	c:RegisterEffect(e1)
	
	--Cannot respond to Slayer Spell/Trap cards
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
	
	--Grant effect to Xyz monster
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCondition(s.matcon)
	e3:SetOperation(s.matop)
	c:RegisterEffect(e3)
end

s.listed_series={0x2407}

--Additional Normal Summon condition
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2407)
end
function s.sumcon(e)
	return Duel.IsExistingMatchingCard(s.cfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--Cannot activate in response to Slayer Spell/Trap
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) and rc:IsSetCard(0x2407) and Duel.GetChainInfo(0,CHAININFO_TRIGGERING_EFFECT)==re
end

--Xyz material condition
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_XYZ
end

--Grant effect to Xyz monster
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if rc and rc:IsType(TYPE_XYZ) then
		--Special Summon Slayer monsters from banished/GY
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e1:SetType(EFFECT_TYPE_IGNITION)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCountLimit(1)
		e1:SetCost(s.spcost)
		e1:SetTarget(s.sptg)
		e1:SetOperation(s.spop)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		rc:RegisterEffect(e1,true)
	end
end

--Special Summon cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGrave,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end

--Special Summon target
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2407) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

--Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,ft,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end