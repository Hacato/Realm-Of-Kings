--Echoes Of The Past
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
    
    --Add 2 Slayer cards from deck then discard 1 Slayer card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.target)
    e2:SetOperation(s.activate)
    c:RegisterEffect(e2)
end

--Search filter
function s.thfilter(c)
    return c:IsSetCard(0x2407) and c:IsAbleToHand()
end

--Discard filter
function s.discardfilter(c)
    return c:IsSetCard(0x2407) and c:IsDiscardable()
end

--Target function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,2,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

--Activation function
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    --Add 2 Slayer cards from deck to hand
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,2,2,nil)
    if g:GetCount()==2 then
        if Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
            Duel.ConfirmCards(1-tp,g)
            Duel.ShuffleDeck(tp)
            --Then discard 1 Slayer card
            if Duel.IsExistingMatchingCard(s.discardfilter,tp,LOCATION_HAND,0,1,nil) then
                Duel.BreakEffect()
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
                local dg=Duel.SelectMatchingCard(tp,s.discardfilter,tp,LOCATION_HAND,0,1,1,nil)
                if dg:GetCount()>0 then
                    Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)
                end
            end
        end
    end
end