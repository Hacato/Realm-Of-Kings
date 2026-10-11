
--Seafarer's Haunted Remains
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Activate: Add 1 "Seafarer" card
    --from your Deck to your hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,0})
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --If this face-down card you control is destroyed:
    --Choose to search 1 Seafarer card
    --or Special Summon 1 Seafarer from your hand
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND
        +CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.descon)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

--Any Seafarer card in the Deck
function s.thfilter(c)
    return c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToHand()
end

--Seafarer monster in hand
function s.spfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Normal activation: search 1 Seafarer
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_DECK,0,1,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
    )
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_DECK,0,1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
    )

    if #g>0 and Duel.SendtoHand(
        g,nil,REASON_EFFECT
    )>0 then
        Duel.ConfirmCards(1-tp,g)
    end
end

--Must have been destroyed while face-down
--under your control
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_ONFIELD)
        and c:IsPreviousPosition(POS_FACEDOWN)
        and c:GetPreviousControler()==tp
end

--Check whether each option is available
function s.cansearch(tp)
    return Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_DECK,0,1,nil
    )
end

function s.cansummon(e,tp)
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp
        )
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return s.cansearch(tp) or s.cansummon(e,tp)
    end

    Duel.SetPossibleOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
    )
    Duel.SetPossibleOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND
    )
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local canth=s.cansearch(tp)
    local cansp=s.cansummon(e,tp)

    if not canth and not cansp then
        return
    end

    local op=0

    --Both choices available
    if canth and cansp then
        op=Duel.SelectOption(
            tp,
            aux.Stringid(id,2),
            aux.Stringid(id,3)
        )
    elseif cansp then
        op=1
    end

    if op==0 then
        --Add 1 Seafarer card from Deck
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(
            tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
        )

        if #g>0 and Duel.SendtoHand(
            g,nil,REASON_EFFECT
        )>0 then
            Duel.ConfirmCards(1-tp,g)
        end
    else
        --Special Summon 1 Seafarer from hand
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(
            tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp
        )

        if #g>0 then
            Duel.SpecialSummon(
                g,0,tp,tp,false,false,POS_FACEUP
            )
        end
    end
end
