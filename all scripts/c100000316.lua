--HERO Fusion Substitute
local s,id=GetID()
function s.initial_effect(c)
    --Search 1 "HERO" monster when Normal Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    
    --Substitute for any Fusion Material
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_FUSION_SUBSTITUTE)
    e2:SetCondition(s.subcon)
    c:RegisterEffect(e2)
end

--Search filter
function s.thfilter(c)
    return c:IsSetCard(0x8) and c:IsMonster() and c:IsAbleToHand()
end

--Search target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Search operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--Fusion Substitute condition - can be used from hand, field, or GY
function s.subcon(e)
    local c=e:GetHandler()
    return c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE)
end