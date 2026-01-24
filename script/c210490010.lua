--Dark Scorpion Teamwork Trap 
local s,id=GetID() 
function s.initial_effect(c) 
    --Activate from hand 
	local e1=Effect.CreateEffect(c) 
	e1:SetType(EFFECT_TYPE_SINGLE) 
	e1:SetCode(EFFECT_TRAP_ACT_IN_HAND) 
	e1:SetCondition(s.actcon) 
	c:RegisterEffect(e1) 
    --Negate 
	local e2=Effect.CreateEffect(c) 
	e2:SetCategory(CATEGORY_NEGATE) 
	e2:SetType(EFFECT_TYPE_ACTIVATE) 
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL) 
	e2:SetCode(EVENT_CHAINING) 
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) 
	e2:SetCondition(s.ngcon) 
	e2:SetTarget(s.ngtg) 
	e2:SetOperation(s.ngop) 
	c:RegisterEffect(e2) 
end 
s.listed_names={76922029} 
s.listed_series={0x1a} 
function s.dzfilter(c) 
    return c:IsCode(76922029) and (c:IsLocation(LOCATION_GRAVE) or (c:IsFaceup() and c:IsLocation(LOCATION_MZONE))) 
end 
function s.actcon(e) 
	return Duel.IsExistingMatchingCard(s.dzfilter,e:GetHandlerPlayer(),LOCATION_MZONE+LOCATION_GRAVE,0,1,nil) 
end 
function s.confilter(c) 
    return c:IsFaceup() and (c:IsCode(76922029) or (c:IsSetCard(0x1a) and c:IsType(TYPE_MONSTER))) 
end 
function s.ngcon(e,tp,eg,ep,ev,re,r,rp) 
    local g=Duel.GetMatchingGroup(s.confilter,tp,LOCATION_MZONE,0,nil) 
    return g:GetClassCount(Card.GetCode)>=1
end 
function s.ngtg(e,tp,eg,ep,ev,re,r,rp,chk) 
	if chk==0 then return Duel.IsChainNegatable(ev) end 
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0) 
end 
function s.ngop(e,tp,eg,ep,ev,re,r,rp) 
	local c=e:GetHandler() 
    local g=Duel.GetMatchingGroup(s.confilter,tp,LOCATION_MZONE,0,nil) 
    local ct=g:GetClassCount(Card.GetCode) 
    if Duel.NegateActivation(ev) then 
        if ct>=2 and re:GetHandler():IsRelateToEffect(re) then 
            Duel.Destroy(eg,REASON_EFFECT) 
        end 
        if ct>=3 and c:IsRelateToEffect(e) and c:IsSSetable(true) and e:IsHasType(EFFECT_TYPE_ACTIVATE) then 
            c:CancelToGrave() 
            Duel.ChangePosition(c,POS_FACEDOWN) 
            Duel.RaiseEvent(c,EVENT_SSET,e,REASON_EFFECT,tp,tp,0) 
        end 
        if ct>=4 then 
            local sg=Duel.GetFieldGroup(tp,0,LOCATION_HAND) 
		    local dg=sg:RandomSelect(1-tp,1) 
		    Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD) 
        end 
        if ct>=5 then 
            Duel.Damage(1-tp,2000,REASON_EFFECT) 
        end 
	end 
end