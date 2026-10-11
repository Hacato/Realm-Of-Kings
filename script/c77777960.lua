
--Seafarer's Clash
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Target 1 opponent's monster and
    --1 Seafarer monster you control;
    --negate their effects until the End Phase
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+
        EFFECT_FLAG_DAMAGE_STEP)
    e1:SetCountLimit(1,{id,0})
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    --If this face-down card you control
    --is destroyed:
    --Target up to 2 Seafarer monsters;
    --they gain 1000 ATK
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetProperty(EFFECT_FLAG_DELAY+
        EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.atkcon)
    e2:SetTarget(s.atktg)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
end

--Opponent's face-up monster
function s.oppfilter(c)
    return c:IsFaceup()
end

--Your face-up Seafarer monster
function s.seafilter(c)
    return c:IsFaceup()
        and c:IsSetCard(SET_SEAFARER)
end

--Target one monster on each side
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_MZONE)
            and ((chkc:IsControler(1-tp)
                and s.oppfilter(chkc))
            or (chkc:IsControler(tp)
                and s.seafilter(chkc)))
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.oppfilter,tp,0,LOCATION_MZONE,1,nil
        )
            and Duel.IsExistingTarget(
                s.seafilter,tp,LOCATION_MZONE,0,1,nil
            )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g1=Duel.SelectTarget(
        tp,s.oppfilter,tp,0,LOCATION_MZONE,1,1,nil
    )

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g2=Duel.SelectTarget(
        tp,s.seafilter,tp,LOCATION_MZONE,0,1,1,nil
    )

    g1:Merge(g2)
    Duel.SetOperationInfo(
        0,CATEGORY_DISABLE,g1,2,0,0
    )
end

--Apply effect negation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)

    for tc in aux.Next(g) do
        if tc:IsFaceup()
            and tc:IsRelateToEffect(e)
            and not tc:IsImmuneToEffect(e) then

            Duel.NegateRelatedChain(tc,RESET_TURN_SET)

            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(
                RESET_EVENT+RESETS_STANDARD+
                RESET_PHASE+PHASE_END
            )
            tc:RegisterEffect(e1)

            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetValue(RESET_TURN_SET)
            e2:SetReset(
                RESET_EVENT+RESETS_STANDARD+
                RESET_PHASE+PHASE_END
            )
            tc:RegisterEffect(e2)
        end
    end
end

--Destroyed while face-down under your control
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_ONFIELD)
        and c:IsPreviousPosition(POS_FACEDOWN)
        and c:GetPreviousControler()==tp
end

--Seafarer monster that can gain ATK
function s.atkfilter(c)
    return c:IsFaceup()
        and c:IsSetCard(SET_SEAFARER)
end

--Target 1 or 2 Seafarer monsters
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_MZONE)
            and chkc:IsControler(tp)
            and s.atkfilter(chkc)
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.atkfilter,tp,LOCATION_MZONE,0,1,nil
        )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(
        tp,s.atkfilter,tp,LOCATION_MZONE,0,1,2,nil
    )

    Duel.SetOperationInfo(
        0,CATEGORY_ATKCHANGE,g,#g,tp,1000
    )
end

--Give each targeted monster 1000 ATK
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)

    for tc in aux.Next(g) do
        if tc:IsFaceup()
            and tc:IsRelateToEffect(e)
            and not tc:IsImmuneToEffect(e) then

            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(1000)
            e1:SetReset(
                RESET_EVENT+RESETS_STANDARD
            )
            tc:RegisterEffect(e1)
        end
    end
end
