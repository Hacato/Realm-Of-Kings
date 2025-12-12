--The Greatest Disciple
--Coded by HuascarD
local s,id,o=GetID()
function s.initial_effect(c)
	--link Summon
	Link.AddProcedure(c,s.mfilter,1,1)
	c:EnableReviveLimit()
	--change name
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e1:SetValue(38033121)
	c:RegisterEffect(e1)
	--atkup
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.val)
	c:RegisterEffect(e2)
	--special summon
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.rmcost1(1))
	e3:SetTarget(s.sstg)
	e3:SetOperation(s.ssop)
	c:RegisterEffect(e3)
	--destroy monsters
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.rmcost2(3))
	e4:SetTarget(s.dmtg)
	e4:SetOperation(s.dmop)
	c:RegisterEffect(e4)	 
end
s.listed_names={46986414,38033121}
function s.mfilter(c,lc,sumtype,tp)
	return c:IsOriginalCodeRule(38033121)
end
function s.filter(c)
	return c:IsRace(RACE_SPELLCASTER)
end
function s.val(e,c)
	return Duel.GetMatchingGroupCount(s.filter,0,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,nil)*100
end
function s.cfilter(c)
	return c:IsMonster() and c:IsAbleToRemoveAsCost()
end 
function s.rmcost1(ct)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_SZONE+LOCATION_GRAVE,0,1,e:GetHandler()) end
		Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,1,1,e:GetHandler())
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end
function s.sfilter(c,e,tp)
	return c:IsCode(CARD_DARK_MAGICIAN) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.sfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.sfilter,tp,LOCATION_DECK+LOCATION_HAND,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.rmcost2(ct)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_SZONE+LOCATION_GRAVE,0,3,e:GetHandler()) end
		Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,3,3,e:GetHandler())
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end
function s.dfilter(c)
	return c:IsFaceup()
end
function s.dmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.dfilter,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(s.dfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.dmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.dfilter,tp,0,LOCATION_MZONE,nil)
	Duel.Destroy(g,REASON_EFFECT)
end