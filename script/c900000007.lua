--Realm Of The Slayer
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
    
    --Activate: Draw 2 cards if you control 2+ Extra Deck Slayer monsters
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetTarget(s.drawtg)
    e2:SetOperation(s.drawop)
    c:RegisterEffect(e2)
    
    --Special summon Slayer monster from hand and add Slayer card from deck
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

--Check for 2+ Extra Deck Slayer monsters
function s.extrafilter(c)
    return c:IsFaceup() and c:IsSetCard(0x2407) and c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
end

--Draw target
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g=Duel.GetMatchingGroup(s.extrafilter,tp,LOCATION_MZONE,0,nil)
    if g:GetCount()>=2 and Duel.IsPlayerCanDraw(tp,2) then
        Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
    end
end

--Draw operation
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g=Duel.GetMatchingGroup(s.extrafilter,tp,LOCATION_MZONE,0,nil)
    if g:GetCount()>=2 and Duel.IsPlayerCanDraw(tp,2) then
        Duel.Draw(tp,2,REASON_EFFECT)
    end
end

--Special summon filter
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2407) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Search filter
function s.thfilter(c)
    return c:IsSetCard(0x2407) and c:IsAbleToHand()
end

--Special summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

--Special summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
    if g:GetCount()>0 then
        if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)~=0 then
            --Then you may add 1 Slayer card from deck to hand
            if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
                and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
                Duel.BreakEffect()
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                local tg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
                if tg:GetCount()>0 then
                    Duel.SendtoHand(tg,nil,REASON_EFFECT)
                    Duel.ConfirmCards(1-tp,tg)
                    Duel.ShuffleDeck(tp)
                end
            end
        end
    end
end