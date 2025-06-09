--Slayers Society
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --This card is always treated as a "Slayer" card
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_SETCODE)
    e1:SetRange(LOCATION_SZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
    e1:SetValue(0x2407)
    c:RegisterEffect(e1)
    
    --Activate: Add any Slayer card from deck to hand
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    --All Slayer monsters gain 1000 ATK
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x2407))
    e3:SetValue(1000)
    c:RegisterEffect(e3)
    
    --Opponent cannot activate cards/effects from hand if they control a Slayer card
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetCode(EFFECT_CANNOT_ACTIVATE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(0,1)
    e4:SetCondition(s.actcon)
    e4:SetValue(s.aclimit)
    c:RegisterEffect(e4)
    
    --Special summon Level 4 or lower Slayer monster from GY to either field
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.spop)
    c:RegisterEffect(e5)
end

--Add Slayer card from deck to hand
function s.thfilter(c)
    return c:IsSetCard(0x2407) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
        if g:GetCount()>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
            Duel.ShuffleDeck(tp)
        end
    end
end

--Check if opponent controls a Slayer card
function s.actcon(e)
    return Duel.IsExistingMatchingCard(Auxiliary.FaceupFilter(Card.IsSetCard,0x2407),e:GetHandlerPlayer(),0,LOCATION_ONFIELD,1,nil)
end

--Limit activations from hand
function s.aclimit(e,re,tp)
    return re:GetActivateLocation()==LOCATION_HAND
end

--Special summon filter
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2407) and c:IsType(TYPE_MONSTER) and c:IsLevelBelow(4)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Special summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0)
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

--Special summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
    if not (b1 or b2) then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if not tc then return end
    
    local op=0
    if b1 and b2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
    elseif b1 then
        op=0
    else
        op=1
    end
    
    if op==0 then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    else
        Duel.SpecialSummon(tc,0,tp,1-tp,false,false,POS_FACEUP)
    end
end