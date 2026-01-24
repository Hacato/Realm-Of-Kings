--Dark Scorpion Hideout
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
    --Search
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_FZONE)
    e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
    --Increase ATK
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.etarget)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
end
s.listed_names={76922029}
s.listed_series={0x1a}
function s.spfilter(c,e,tp)
	return c:IsCode(76922029) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,1,1,nil)
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
	end
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg and eg:IsExists(s.thcfilter,1,nil,e,tp)
end
function s.thcfilter(c,e,tp)
	return c:IsSetCard(0x1a) and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE) and c:IsPreviousLocation(LOCATION_HAND+LOCATION_GRAVE)
		and c:IsCanBeEffectTarget(e)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
        and not Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_ONFIELD,0,1,c,c:GetCode())
end
function s.thfilter(c)
	return c:IsSetCard(0x1a) and c:IsAbleToHand() 
        and not Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsCode,c:GetCode()),c:GetControler(),LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil)
end
function s.spcheck(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetCode)==#sg
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local g=eg:Filter(s.thcfilter,nil,e,tp)
    local g2=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if chkc then return g:IsContains(chkc) and s.thcfilter(chkc,e,tp) end
	if chk==0 then return #g>0 and aux.SelectUnselectGroup(g2,e,tp,1,#g,s.spcheck,0) end
	if #g==1 then
		Duel.SetTargetCard(g:GetFirst())
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local tc=g:Select(tp,1,#g,nil)
		Duel.SetTargetCard(tc)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if not c:IsRelateToEffect(e) then return end
    local g2=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g2==0 then return end
	local rg=aux.SelectUnselectGroup(g2,e,tp,1,#g,s.spcheck,1,tp,HINTMSG_ATOHAND)
    Duel.SendtoHand(rg,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,rg)
    for tc in aux.Next(g) do
        --Cannot target
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
        e1:SetRange(LOCATION_FZONE)
        e1:SetTarget(aux.TargetBoolFunction(Card.IsCode,tc:GetCode()))
        e1:SetValue(s.val)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        e1:SetLabelObject(c)
        c:RegisterEffect(e1)
    end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,2),nil)
	--lizard check
	aux.addTempLizardCheck(e:GetHandler(),tp,s.lizfilter)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:IsRace(RACE_WARRIOR) and c:IsAttribute(ATTRIBUTE_DARK)) and c:IsLocation(LOCATION_EXTRA)
end
function s.lizfilter(e,c)
	return not (c:IsRace(RACE_WARRIOR) and c:IsAttribute(ATTRIBUTE_DARK))
end
function s.val(e)
	return e:GetLabelObject()
end
function s.filter(c)
    return c:IsFaceup() and (c:IsCode(76922029) or c:IsSetCard(0x1a) and c:IsType(TYPE_MONSTER))
end
function s.etarget(e,c)
    return c:IsFaceup() and (c:IsCode(76922029) or c:IsSetCard(0x1a) and c:IsType(TYPE_MONSTER))
end
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.filter,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil)
	return g:GetClassCount(Card.GetCode)*400
end