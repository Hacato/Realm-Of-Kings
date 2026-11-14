
--Red Dragon Archfiend - Crimson Dreadnought
--Card ID: 800000310
--DARK / Dragon / Synchro / Effect
--Level 8 / ATK 3000 / DEF 2500

local s,id=GetID()
local CARD_RED_DRAGON_ARCHFIEND=70902743
local SET_RESONATOR=0x57

s.listed_names={CARD_RED_DRAGON_ARCHFIEND}
s.listed_series={SET_RESONATOR}

function s.initial_effect(c)
    --Synchro Summon
    c:EnableReviveLimit()
    Synchro.AddProcedure(c,nil,1,1,
        Synchro.NonTuner(nil),1,99)

    --Name becomes Red Dragon Archfiend
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetRange(LOCATION_ONFIELD|LOCATION_GRAVE)
    e0:SetValue(CARD_RED_DRAGON_ARCHFIEND)
    c:RegisterEffect(e0)

    --Special Summon a Fiend Tuner
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE|EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Destroy Defense Position monsters and burn
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY|CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)

    --Revive RDA or Resonator when destroyed
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE|EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_DESTROYED)
    e3:SetCountLimit(1,id+2)
    e3:SetCondition(s.revcon)
    e3:SetTarget(s.revtg)
    e3:SetOperation(s.revop)
    e3:SetLabel(0)
    c:RegisterEffect(e3)

    --Record whether the current Summon
    --was a Synchro Summon
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE|EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetLabelObject(e3)
    e4:SetOperation(s.regop)
    c:RegisterEffect(e4)
end

--========================================
-- RECORD SYNCHRO SUMMON STATUS
--========================================

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local reff=e:GetLabelObject()

    if c:IsSummonType(SUMMON_TYPE_SYNCHRO) then
        reff:SetLabel(1)
    else
        reff:SetLabel(0)
    end
end

--========================================
-- EFFECT 1: SPECIAL SUMMON FIEND TUNER
--========================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(
        SUMMON_TYPE_SYNCHRO)
end

function s.spfilter(c,e,tp)
    return c:IsRace(RACE_FIEND)
        and c:IsType(TYPE_TUNER)
        and c:IsLevelBelow(4)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                aux.NecroValleyFilter(s.spfilter),
                tp,LOCATION_HAND|LOCATION_GRAVE,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,aux.NecroValleyFilter(s.spfilter),
        tp,LOCATION_HAND|LOCATION_GRAVE,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummon(
        tc,0,tp,tp,false,false,POS_FACEUP)>0 then

        --Negate the summoned monster's effects
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        tc:RegisterEffect(e1)

        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        tc:RegisterEffect(e2)
    end
end

--========================================
-- EFFECT 2: DESTROY DEFENSE MONSTERS
--========================================

function s.desfilter(c)
    return c:IsPosition(POS_DEFENSE)
        and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,0,LOCATION_MZONE,1,nil)
    end

    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,0,LOCATION_MZONE,nil)

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,g,#g,0,0)

    Duel.SetOperationInfo(
        0,CATEGORY_DAMAGE,nil,0,1-tp,500*#g)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,0,LOCATION_MZONE,nil)

    if #g==0 then return end

    local ct=Duel.Destroy(g,REASON_EFFECT)

    if ct>0 then
        Duel.Damage(1-tp,ct*500,REASON_EFFECT)
    end
end

--========================================
-- EFFECT 3: REVIVE RDA OR RESONATOR
--========================================

function s.revcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    return e:GetLabel()==1
        and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsReason(REASON_BATTLE|REASON_EFFECT)
end

function s.revfilter(c,e,tp)
    return (c:IsCode(CARD_RED_DRAGON_ARCHFIEND)
            or c:IsSetCard(SET_RESONATOR))
        and not c:IsOriginalCode(id)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                aux.NecroValleyFilter(s.revfilter),
                tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_GRAVE)
end

function s.revop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,aux.NecroValleyFilter(s.revfilter),
        tp,LOCATION_GRAVE,0,1,1,nil,e,tp)

    local tc=g:GetFirst()

    if tc then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP)
    end
end
