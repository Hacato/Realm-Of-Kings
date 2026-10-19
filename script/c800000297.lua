
--The Miko of World Chalice
local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    --Tribute from hand or field to Special Summon
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND|LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --GY effect when a Link Monster is
    --Link Summoned and is co-linked
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_FIELD+
        EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetCondition(s.tgcon)
    e2:SetCost(s.tgcost)
    e2:SetTarget(s.tgtg)
    e2:SetOperation(s.tgop)
    c:RegisterEffect(e2)
end

--==================================
-- FIRST EFFECT: TRIBUTE
--==================================

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsReleasable()
    end
    Duel.Release(e:GetHandler(),REASON_COST)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsLevelBelow(4)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND|LOCATION_DECK,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_HAND|LOCATION_DECK)
end

--==================================
-- MATERIAL RESTRICTIONS
--==================================

function s.matlimit(e,c)
    return not c:IsSetCard(SET_WORLD_CHALICE)
end

function s.applyrestrictions(c)

    local codes={
        EFFECT_CANNOT_BE_FUSION_MATERIAL,
        EFFECT_CANNOT_BE_SYNCHRO_MATERIAL,
        EFFECT_CANNOT_BE_XYZ_MATERIAL,
        EFFECT_CANNOT_BE_LINK_MATERIAL
    }

    for _,code in ipairs(codes) do
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(
            EFFECT_FLAG_CANNOT_DISABLE+
            EFFECT_FLAG_UNCOPYABLE)
        e1:SetCode(code)
        e1:SetValue(s.matlimit)
        e1:SetReset(
            RESET_EVENT|RESETS_STANDARD)
        c:RegisterEffect(e1)
    end

    --Ritual material restriction
    if EFFECT_CANNOT_BE_RITUAL_MATERIAL then
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetProperty(
            EFFECT_FLAG_CANNOT_DISABLE+
            EFFECT_FLAG_UNCOPYABLE)
        e2:SetCode(
            EFFECT_CANNOT_BE_RITUAL_MATERIAL)
        e2:SetValue(s.matlimit)
        e2:SetReset(
            RESET_EVENT|RESETS_STANDARD)
        c:RegisterEffect(e2)
    end

    --Can also be treated as a Tuner
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_ADD_TYPE)
    e3:SetValue(TYPE_TUNER)
    e3:SetReset(
        RESET_EVENT|RESETS_STANDARD)
    c:RegisterEffect(e3)
end

--==================================
-- SPECIAL SUMMON
--==================================

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,
        LOCATION_HAND|LOCATION_DECK,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummon(
        tc,0,tp,tp,false,false,
        POS_FACEUP)>0 then
        s.applyrestrictions(tc)
    end
end

--==================================
-- SECOND EFFECT: CO-LINKED LINK SUMMON
--==================================

function s.linkfilter(c)
    return c:IsType(TYPE_LINK)
        and c:IsSummonType(SUMMON_TYPE_LINK)
        and c:IsCoLinked()
end

function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.linkfilter,1,nil)
end

function s.tgcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsAbleToRemoveAsCost()
    end

    Duel.Remove(
        e:GetHandler(),POS_FACEUP,REASON_COST)
end

function s.tgfilter(c)
    return (c:IsSetCard(SET_WORLD_CHALICE)
        or c:IsSetCard(SET_WORLD_LEGACY))
        and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.tgfilter,tp,LOCATION_DECK,
            0,1,nil)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TOGRAVE,
        nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(
        HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

    local g=Duel.SelectMatchingCard(
        tp,s.tgfilter,tp,
        LOCATION_DECK,0,1,1,nil)

    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end
