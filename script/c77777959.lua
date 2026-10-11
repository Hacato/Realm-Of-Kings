
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --1 Seafarer Tuner
    --+ 1 or more Seafarer non-Tuners
    Synchro.AddProcedure(c,
        aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SEAFARER),
        1,1,
        Synchro.NonTunerEx(Card.IsSetCard,SET_SEAFARER),
        1,99)
    c:EnableReviveLimit()

    --At the start of the Damage Step:
    --Destroy the opponent's battling monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e1:SetCondition(s.descon)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    --Can be treated as Level 3
    --when used for a Synchro Summon
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_SYNCHRO_LEVEL)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.slevel)
    c:RegisterEffect(e2)

    --Grant effects to the Synchro Monster
    --that uses this card as material
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.matcon)
    e3:SetOperation(s.matop)
    c:RegisterEffect(e3)
end

--Original Level OR Level 3
function s.slevel(e,c)
    local lv=e:GetHandler():GetLevel()
    return 3*65536+lv
end

--Start of Damage Step battle condition
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    return d~=nil and (a==c or d==c)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    local tc=(a==c) and d or a

    if chk==0 then
        return tc~=nil
            and tc:IsRelateToBattle()
            and tc:IsDestructable()
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,tc,1,0,0
    )
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    local tc=(a==c) and d or a

    if tc and tc:IsRelateToBattle()
        and tc:IsDestructable() then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

--Must be used for a Synchro Summon
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    return r==REASON_SYNCHRO
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local sc=c:GetReasonCard()

    if not sc or not sc:IsType(TYPE_SYNCHRO) then
        return
    end

    --Granted effect 1:
    --Cannot be destroyed by card effects
    local e1=Effect.CreateEffect(sc)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(
        EFFECT_FLAG_SINGLE_RANGE+
        EFFECT_FLAG_CLIENT_HINT
    )
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    sc:RegisterEffect(e1,true)

    --Granted effect 2:
    --Once per turn (Quick Effect):
    --Target 1 Spell/Trap; destroy it
    local e2=Effect.CreateEffect(sc)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1)
    e2:SetTarget(s.sttg)
    e2:SetOperation(s.stop)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
    sc:RegisterEffect(e2,true)
end

--Spell/Trap on either side of the field
function s.stfilter(c)
    return c:IsSpellTrap()
        and c:IsDestructable()
end

function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsOnField()
            and s.stfilter(chkc)
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.stfilter,tp,
            LOCATION_ONFIELD,LOCATION_ONFIELD,
            1,nil
        )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(
        tp,s.stfilter,tp,
        LOCATION_ONFIELD,LOCATION_ONFIELD,
        1,1,nil
    )

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,g,1,0,0
    )
end

function s.stop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end
