--Sauravis, Divine Dragon of the Voiceless Voice
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
    --Negate the act of an opp's c/eff that des/rm a c(s)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp==1-tp and Duel.GetOperationInfo(ev,CATEGORY_DESTROY) and Duel.IsChainNegatable(ev) end)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
	e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp==1-tp and Duel.GetOperationInfo(ev,CATEGORY_REMOVE) and Duel.IsChainNegatable(ev) end)
	c:RegisterEffect(e2)
    --negate the eff of an opp's c/eff that spsumms a m(s)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DISABLE+CATEGORY_TODECK)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.discon)
    e3:SetCost(s.discost)
    e3:SetTarget(s.distg)
    e3:SetOperation(s.disop)
    c:RegisterEffect(e3)
end
s.listed_names={25801745,2008000086}
s.listed_series={SET_VOICELESS_VOICE}
function s.filter(c)--Negate the act of an opp's c/eff that des/rm a c(s)
    return c:IsCode(25801745)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsDiscardable() and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local tc=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_MZONE,0,1,1,nil):GetFirst()
    if tc then
        Duel.SendtoGrave(c,REASON_COST|REASON_DISCARD)
        Duel.SendtoGrave(tc,REASON_COST|REASON_RELEASE)
    end
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        if re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsRelateToEffect(re) then
			Duel.SendtoGrave(eg,REASON_EFFECT)
		end
    end
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)--negate the eff of an opp's c/eff that spsumms a m(s)
    return rp==1-tp and re:IsHasCategory(CATEGORY_SPECIAL_SUMMON) and Duel.IsChainNegatable(ev)
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHandAsCost() end
	Duel.SendtoHand(e:GetHandler(),nil,REASON_COST)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,tp,0)
    local rc=re:GetHandler()
    if rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,tp,0)
	end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local ec=re:GetHandler()--
    if Duel.NegateEffect(ev) and re:GetHandler():IsRelateToEffect(re) then
        ec:CancelToGrave()
		Duel.SendtoDeck(ec,nil,2,REASON_EFFECT)
    end
end