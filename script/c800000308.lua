--Guardragon Foskoteno
--DARK / Dragon / Xyz / Effect
--2 Dragon Link monsters with the same Link Rating

local s,id=GetID()
local SET_GUARDRAGON=0x2fda

s.listed_series={SET_GUARDRAGON}

function s.initial_effect(c)
    --Xyz Summon procedure
    c:EnableReviveLimit()
    Xyz.AddProcedure(c,s.xyzfilter,nil,2,
        nil,nil,nil,nil,false,s.xyzcheck)

    --Only Special Summon this card once per turn
    c:SetSPSummonOnce(id)

    --Cannot Special Summon non-Dragon monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    c:RegisterEffect(e1)

    --Detach 1 Xyz Material to Special Summon a Dragon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--========================================
-- XYZ SUMMON MATERIALS
--========================================

function s.xyzfilter(c,xyz,sumtype,tp)
    return c:IsRace(RACE_DRAGON,xyz,sumtype,tp)
        and c:IsType(TYPE_LINK,xyz,sumtype,tp)
end

function s.xyzcheck(g,tp,xyz)
    return g:GetClassCount(Card.GetLink)==1
end

--========================================
-- DRAGON-ONLY SPECIAL SUMMON RESTRICTION
--========================================

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsRace(RACE_DRAGON)
end

--========================================
-- DETACH XYZ MATERIAL
--========================================

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():CheckRemoveOverlayCard(
            tp,1,REASON_COST)
    end
    e:GetHandler():RemoveOverlayCard(
        tp,1,1,REASON_COST)
end

--========================================
-- SPECIAL SUMMON LEVEL 4 OR LOWER DRAGON
--========================================

function s.spfilter(c,e,tp)
    return c:IsRace(RACE_DRAGON)
        and c:IsLevelBelow(4)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,
        LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummon(tc,0,tp,tp,false,false,
        POS_FACEUP_DEFENSE)>0 then

        --Summoned monster cannot be Link Material
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end