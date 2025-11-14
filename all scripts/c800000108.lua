--Infinite Constructor Wyrm Buildream
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials: "Constructor Wyrm Buildragon" + 1 EARTH Wyrm monster
	Fusion.AddProcMix(c,true,true,800000099,s.ffilter)
	--Send opponent's face-up cards to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tgcon)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	--Cannot be destroyed by card effects while Blisstopia is present
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetCondition(s.indcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end
s.listed_names={800000099} --Constructor Wyrm Buildragon
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia

--Fusion Material filter: EARTH Wyrm monster
function s.ffilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_WYRM,fc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_EARTH,fc,sumtype,tp)
end

--Send to GY condition: Fusion Summoned or Special Summoned by "Constructor" card effect
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION) 
		or (re and re:GetHandler():IsSetCard(0x1568) and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP))
end
--Count different "Blisstopia" Field Spells
function s.blissfilter(c)
	return c:IsSetCard(0x1569) and c:IsType(TYPE_FIELD) and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.blissfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD,nil)
		local ct=g:GetClassCount(Card.GetCode)
		return ct>0 and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.blissfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD,nil)
	local ct=g:GetClassCount(Card.GetCode)
	local tg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,tg,math.min(ct,#tg),0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	--Count different "Blisstopia" Field Spells
	local g=Duel.GetMatchingGroup(s.blissfilter,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD,nil)
	local ct=g:GetClassCount(Card.GetCode)
	if ct==0 then return end
	
	--Send opponent's face-up cards to GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local tg=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,ct,nil)
	if #tg>0 and Duel.SendtoGrave(tg,REASON_EFFECT)>0 then
		--Cannot attack directly
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
		e1:SetTargetRange(LOCATION_MZONE,0)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

--Indestructible condition: "Blisstopia" card in Field Zone
function s.indcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),e:GetHandlerPlayer(),LOCATION_FZONE,LOCATION_FZONE,1,nil)
end