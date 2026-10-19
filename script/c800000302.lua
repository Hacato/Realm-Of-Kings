
--World Chalice - Starry Night
--Quick-Play Spell
local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    --Special Summon 2 "World Chalice"
    --Normal Monsters from hand and/or Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Banish from GY to Normal Summon
    --1 "World Legacy" monster without Tributing
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.nscon)
    e2:SetCost(s.nscost)
    e2:SetTarget(s.nstg)
    e2:SetOperation(s.nsop)
    c:RegisterEffect(e2)
end

s.listed_series={
    SET_WORLD_CHALICE,
    SET_WORLD_LEGACY
}

--========================================
-- EFFECT 1: SPECIAL SUMMON 2
--========================================

function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsMonster()
        and c:IsType(TYPE_NORMAL)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND|LOCATION_DECK,
                0,2,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,2,tp,LOCATION_HAND|LOCATION_DECK)
end

--Extra Deck restriction
function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA)
        and not c:IsSetCard(SET_WORLD_CHALICE)
        and not c:IsSetCard(SET_WORLD_LEGACY)
end

function s.lockcon(e)
    local c=e:GetHandler()
    return c:IsFaceup()
        and c:IsControler(e:GetLabel())
end

function s.applylock(tc,tp)
    local e1=Effect.CreateEffect(tc)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(
        EFFECT_FLAG_PLAYER_TARGET+
        EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(1,0)
    e1:SetCondition(s.lockcon)
    e1:SetTarget(s.exlimit)
    e1:SetLabel(tp)
    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
    tc:RegisterEffect(e1)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        s.spfilter,tp,
        LOCATION_HAND|LOCATION_DECK,
        0,2,nil,e,tp) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,
        LOCATION_HAND|LOCATION_DECK,
        0,2,2,nil,e,tp)

    if #g~=2 then return end

    if Duel.SpecialSummon(
        g,0,tp,tp,false,false,POS_FACEUP)>0 then

        local sg=Duel.GetOperatedGroup()

        for tc in sg:Iter() do
            if tc:IsFaceup()
                and tc:IsControler(tp)
                and tc:IsLocation(LOCATION_MZONE) then
                s.applylock(tc,tp)
            end
        end
    end
end

--========================================
-- EFFECT 2: NORMAL SUMMON WITHOUT TRIBUTES
--========================================

function s.wcfilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsMonster()
        and c:IsType(TYPE_NORMAL)
end

function s.nscon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(
        s.wcfilter,tp,
        LOCATION_MZONE|LOCATION_GRAVE,
        0,1,nil)
end

function s.nscost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsAbleToRemoveAsCost()
    end

    Duel.Remove(
        e:GetHandler(),POS_FACEUP,REASON_COST)
end

--Actual no-Tribute Summon procedure
function s.ntcon(e,c,minc)
    if c==nil then return true end
    return minc==0
        and Duel.GetLocationCount(
            c:GetControler(),LOCATION_MZONE)>0
end

--Check whether a monster can be summoned
--using the temporary procedure.
function s.nsfilter(c)
    if not c:IsSetCard(SET_WORLD_LEGACY)
        or not c:IsMonster()
        or not c:IsSummonableCard() then
        return false
    end

    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SUMMON_PROC)
    e1:SetCondition(s.ntcon)
    c:RegisterEffect(e1)

    local res=c:IsSummonable(true,e1)
    e1:Reset()

    return res
end

function s.nstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.nsfilter,tp,LOCATION_HAND,
                0,1,nil)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.nsfilter,tp,
        LOCATION_HAND,0,1,1,nil)

    local tc=g:GetFirst()
    if not tc then return end

    --Register a temporary no-Tribute
    --Normal Summon procedure.
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SUMMON_PROC)
    e1:SetCondition(s.ntcon)
    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
    tc:RegisterEffect(e1)

    --Pass the procedure itself to Duel.Summon.
    --This is the critical correction.
    if tc:IsSummonable(true,e1) then
        Duel.Summon(tp,tc,true,e1)
    end

    --Remove the temporary procedure if
    --the monster remains in the hand.
    if tc:IsLocation(LOCATION_HAND) then
        e1:Reset()
    end
end
