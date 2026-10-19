
--The Blade Knight of World Chalice
local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    --If Normal or Special Summoned:
    --Special Summon a World Chalice Normal Monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    --If sent to GY:
    --Send a World Chalice Link Monster
    --from Extra Deck to GY
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id+1)
    e3:SetTarget(s.tgtg)
    e3:SetOperation(s.tgop)
    c:RegisterEffect(e3)

    --Banish this card and a World Legacy card
    --to revive a WATER/EARTH/FIRE/WIND monster
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,id+2)
    e4:SetCost(s.gycost)
    e4:SetTarget(s.gytg)
    e4:SetOperation(s.gyop)
    c:RegisterEffect(e4)
end

--========================================
-- EFFECT 1: SUMMON WORLD CHALICE NORMAL
--========================================

function s.normalfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_NORMAL)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.normalfilter,tp,
                LOCATION_HAND|LOCATION_DECK,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_HAND|LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.normalfilter,tp,
        LOCATION_HAND|LOCATION_DECK,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if tc then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP)
    end
end

--========================================
-- EFFECT 2: SEND LINK MONSTER TO GY
--========================================

function s.linkfilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_LINK)
        and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.linkfilter,tp,LOCATION_EXTRA,
            0,1,nil)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TOGRAVE,
        nil,1,tp,LOCATION_EXTRA)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

    local g=Duel.SelectMatchingCard(
        tp,s.linkfilter,tp,LOCATION_EXTRA,
        0,1,1,nil)

    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

--========================================
-- EFFECT 3: BANISH 2 CARDS TO REVIVE
--========================================

function s.legacyfilter(c)
    return c:IsSetCard(SET_WORLD_LEGACY)
        and c:IsAbleToRemoveAsCost()
end

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()

    if chk==0 then
        return c:IsAbleToRemoveAsCost()
            and Duel.IsExistingMatchingCard(
                s.legacyfilter,tp,
                LOCATION_GRAVE,0,1,c)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

    local g=Duel.SelectMatchingCard(
        tp,s.legacyfilter,tp,
        LOCATION_GRAVE,0,1,1,c)

    if #g==0 then return end

    g:AddCard(c)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.revivefilter(c,e,tp)
    return c:IsAttribute(
        ATTRIBUTE_WATER|ATTRIBUTE_EARTH|
        ATTRIBUTE_FIRE|ATTRIBUTE_WIND)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.revivefilter,tp,
                LOCATION_GRAVE,0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,1,tp,LOCATION_GRAVE)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.revivefilter,tp,
        LOCATION_GRAVE,0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if tc then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP)
    end
end
