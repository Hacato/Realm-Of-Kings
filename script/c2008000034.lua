--Ragnaraika Anathema
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
    --extra normal summon
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.rmcon)
    e1:SetCost(s.rmcost)
	e1:SetTarget(s.rmtg)
    e1:SetOperation(s.rmop)
    c:RegisterEffect(e1)
	--special summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.spcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.spscon)
	c:RegisterEffect(e3)
end
s.listed_series={SET_RAGNARAIKA}
s.listed_names={id}
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)--extra normal summon
	return Duel.IsPlayerCanAdditionalSummon(tp)
end
function s.rmfilter(c)
    return c:IsRace(RACE_INSECT|RACE_PLANT|RACE_REPTILE) and c:IsAbleToRemoveAsCost()
end
function s.rmcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_DECK|LOCATION_EXTRA,0,1,1,nil)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanSummon(tp) end
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	--Extra Normal Summon
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_INSECT|RACE_PLANT|RACE_REPTILE))
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end
function s.cfilter(c,tp,rp)--Sp Sum 1 "Ragnaraika" from your Ex D/GY if a LinkSumm "Ragnaraika" leaves your field
	return c:IsPreviousControler(tp) and rp==1-tp and c:GetPreviousTypeOnField()&TYPE_LINK~=0
		and c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_LINK)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not eg:IsContains(c) and eg:IsExists(s.cfilter,1,c,tp,rp)
end
function s.desfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) and c:GetPreviousTypeOnField()&TYPE_LINK~=0
	    and c:IsSummonType(SUMMON_TYPE_LINK) and ((c:IsReason(REASON_BATTLE) and Duel.GetAttacker():IsControler(1-tp))
		or (c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp))
end
function s.spscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.desfilter,1,nil,tp)
end
function s.filter(c,e,tp)
	return c:IsSetCard(SET_RAGNARAIKA) and c:IsType(TYPE_LINK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_EXTRA|LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA|LOCATION_GRAVE)
	Duel.SetChainLimit(aux.FALSE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_EXTRA|LOCATION_GRAVE,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        --immune to opp's c effs until the EP
        local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(3110)
        e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		--e1:SetRange(LOCATION_MZONE)
        e1:SetCode(EFFECT_IMMUNE_EFFECT)
        e1:SetValue(s.efilter)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        --cannot be des by c effs
        local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetDescription(3001)
        e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetValue(1)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
    end
end
function s.efilter(e,re)
    return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end