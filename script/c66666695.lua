
--Seafarer Undead King Blackbeard
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Synchro Summon:
    --1 Tuner + 1 or more non-Tuner "Seafarer" monsters
    Synchro.AddProcedure(c,nil,1,1,
        Synchro.NonTunerEx(Card.IsSetCard,SET_SEAFARER),1,99)
    c:EnableReviveLimit()

    --Quick Effect: Negate 1 face-up Spell/Trap
    --until the next End Phase
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e1:SetCountLimit(1,{id,0})
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    --Destroy up to 2 Spell/Traps you control
    --Gain 1 additional attack per card destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

--Face-up Spell/Trap cards on either field
function s.negfilter(c)
    return c:IsFaceup()
        and c:IsSpellTrap()
        and not c:IsDisabled()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsOnField() and s.negfilter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(
            s.negfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil
        )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(
        tp,s.negfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil
    )
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e)
        or not tc:IsFaceup() then
        return
    end

    --Negate effects of the targeted Spell/Trap
    Duel.NegateRelatedChain(tc,RESET_TURN_SET)

    --If activated during the End Phase, retain
    --the negation until the following End Phase
    local reset=RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
    local reset_count=1
    if Duel.GetCurrentPhase()==PHASE_END then
        reset_count=2
    end

    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_DISABLE)
    e1:SetReset(reset,reset_count)
    tc:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_DISABLE_EFFECT)
    e2:SetValue(RESET_TURN_SET)
    tc:RegisterEffect(e2)

    --Trap Monster handling
    if tc:IsType(TYPE_TRAPMONSTER) then
        local e3=e1:Clone()
        e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
        tc:RegisterEffect(e3)
    end
end

--Spell/Trap cards you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
        )
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,tp,LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,2,nil
    )
    if #g==0 then return end

    local ct=Duel.Destroy(g,REASON_EFFECT)
    if ct<=0 or not c:IsRelateToEffect(e) then return end

    --Gain 1 additional attack for each card destroyed
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EXTRA_ATTACK)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetValue(ct)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
end
