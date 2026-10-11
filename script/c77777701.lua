
--Seafarer Renegade Jack
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Destroy 1 Spell/Trap you control;
    --add 1 "Seafarer" Spell/Trap from Deck,
    --then optionally Set an opponent's Spell/Trap
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SEARCH+
        CATEGORY_TOHAND+CATEGORY_CONTROL)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

--Spell/Trap you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Seafarer Spell/Trap in Deck that can be added
function s.thfilter(c)
    return c:IsSpellTrap()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToHand()
end

--Opponent's Spell/Trap in a regular S/T Zone
function s.stfilter(c)
    return c:IsSpellTrap()
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
        )
        and Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_DECK,0,1,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD
    )
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
    )
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    --Destroy 1 Spell/Trap you control
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end

    if Duel.Destroy(dg,REASON_EFFECT)==0 then return end

    Duel.BreakEffect()

    --Add 1 Seafarer Spell/Trap from Deck to hand
    if not Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_DECK,0,1,nil
    ) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
    )
    if #g==0 then return end

    if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
    Duel.ConfirmCards(1-tp,g)

    --Optional: Set 1 Spell/Trap from opponent's field
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

    if not Duel.IsExistingMatchingCard(
        s.stfilter,tp,0,LOCATION_SZONE,1,nil
    ) then return end

    if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=Duel.SelectMatchingCard(
        tp,s.stfilter,tp,0,LOCATION_SZONE,1,1,nil
    )
    local tc=sg:GetFirst()
    if not tc then return end

    --Move opponent's Spell/Trap to your field face-down
    Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    )
end
