--Constructor Demolition Wyrm Dracrush
local s,id=GetID()
function s.initial_effect(c)
	--1. Special Summon by sending Field Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- Once per turn
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--2. Destroy on summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1}) -- Once per turn
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

s.listed_series={0x1568,0x1569} -- Constructor, Blisstopia

--Special Summon cost: send Field Spell from hand or face-up field
function s.costfilter(c)
	return c:IsType(TYPE_FIELD) and c:IsAbleToGraveAsCost() 
		and (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_FZONE) and c:IsFaceup()))
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_FZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_FZONE,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Destroy on summon
function s.wyrmfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_WYRM)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,0,1,nil)
	if chkc then
		if blisstopia then
			return chkc:IsOnField() and chkc:IsControler(1-tp)
		else
			return (chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.wyrmfilter(chkc) and chkc~=c)
				or (chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsFaceup())
		end
	end
	if chk==0 then
		if blisstopia then
			return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,2,nil)
		else
			return Duel.IsExistingTarget(s.wyrmfilter,tp,LOCATION_MZONE,0,1,c)
				and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil)
		end
	end
	local g=Group.CreateGroup()
	if blisstopia then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,2,2,nil)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g1=Duel.SelectTarget(tp,s.wyrmfilter,tp,LOCATION_MZONE,0,1,1,c)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g2=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
		g:Merge(g1)
		g:Merge(g2)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
