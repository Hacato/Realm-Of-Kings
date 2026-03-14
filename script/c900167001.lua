--NSO - Ame-chan
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --pendulum summon
    Pendulum.AddProcedure(c)
    --place
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SET)
	e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.tptg)
	e1:SetOperation(s.tpop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
    --place trap
    local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCode(EVENT_CHAIN_SOLVED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.tcon)
	e3:SetTarget(s.ttg)
	e3:SetOperation(s.top)
	c:RegisterEffect(e3)
end
s.listed_series={SET_NSO}
function s.tpfilter(c)
	return c:IsCode(CODE_KANGEL) and not c:IsForbidden()
end
function s.setfilter(c)
	return c:IsTrap() and c:IsSetCard(SET_NSO) and c:IsSSetable()
end
function s.tptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsForbidden()
        and Duel.IsExistingMatchingCard(s.tpfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.CheckLocation(tp,LOCATION_PZONE,0)
        and Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end
function s.tpop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.tpfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.MoveToField(e:GetHandler(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        and Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #sg==0 then return end
        Duel.SSet(tp,sg)
    end
end
function s.tcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsTrapEffect()
		and rp==tp 
end
function s.tfilter(c)
	return c:IsCode(900167004) and not c:IsForbidden()
end
function s.ttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tfilter,tp,LOCATION_DECK|LOCATION_HAND,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
end
function s.top(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.tfilter,tp,LOCATION_DECK|LOCATION_HAND,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
        Duel.Destroy(e:GetHandler(),REASON_EFFECT)
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end
Duel.LoadScript("nso-utility.lua")