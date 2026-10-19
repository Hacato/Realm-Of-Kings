
--The Legends of World Chalice
--LIGHT / Warrior / Link / Effect
--ATK 3000 / LINK-5
--2+ monsters, including 1 "World Chalice" Link Monster

local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local EXTRA_MONSTER_ZONES=0x600060

function s.initial_effect(c)
    c:EnableReviveLimit()

    --Link Summon: 2+ monsters,
    --including 1 "World Chalice" Link Monster
    Link.AddProcedure(c,nil,2,5,s.lcheck)

    --Co-linked monsters you control are unaffected
    --by your opponent's activated card effects
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.immtg)
    e1:SetValue(s.immval)
    c:RegisterEffect(e1)

    --Gain 200 ATK for each Link Monster you control
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    --If Link Summoned, Special Summon 1 monster
    --from hand or GY to a linked Monster Zone
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    --Neither player can Special Summon from
    --the Extra Deck except to an Extra Monster Zone
    --or a zone a Link Monster points to
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_FORCE_MZONE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(LOCATION_EXTRA,LOCATION_EXTRA)
    e4:SetValue(s.fmval)
    c:RegisterEffect(e4)

    --You can only control 1 copy
    c:SetUniqueOnField(1,0,id)
end

--========================================
-- LINK MATERIAL REQUIREMENT
--========================================

function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(s.lmatfilter,1,nil)
end

function s.lmatfilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_LINK)
end

--========================================
-- EFFECT 1: CO-LINKED IMMUNITY
--========================================

function s.immtg(e,c)
    return c:IsFaceup() and c:IsCoLinked()
end

function s.immval(e,re)
    return re:IsActivated()
        and re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--========================================
-- EFFECT 2: ATK BOOST
--========================================

function s.atkfilter(c)
    return c:IsFaceup()
        and c:IsType(TYPE_LINK)
end

function s.atkval(e,c)
    local tp=e:GetHandlerPlayer()
    local ct=Duel.GetMatchingGroupCount(
        s.atkfilter,tp,LOCATION_MZONE,0,nil)
    return ct*200
end

--========================================
-- EFFECT 3: LINK SUMMON REVIVAL
--========================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--Get every Main Monster Zone pointed to by
--a Link Monster you control.
function s.getzones(tp)
    local g=Duel.GetMatchingGroup(
        s.atkfilter,tp,LOCATION_MZONE,0,nil)

    local zone=0
    for tc in g:Iter() do
        zone=zone|tc:GetLinkedZone(tp)
    end

    return zone&0x1f
end

function s.spfilter(c,e,tp)
    return c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local zone=s.getzones(tp)

    if chk==0 then
        return zone~=0
            and Duel.GetLocationCount(
                tp,LOCATION_MZONE,tp,
                LOCATION_REASON_TOFIELD,zone)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND|LOCATION_GRAVE,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
        LOCATION_HAND|LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local zone=s.getzones(tp)

    if zone==0 then return end

    if Duel.GetLocationCount(
        tp,LOCATION_MZONE,tp,
        LOCATION_REASON_TOFIELD,zone)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,
        LOCATION_HAND|LOCATION_GRAVE,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if not tc then return end

    Duel.SpecialSummon(
        tc,0,tp,tp,false,false,POS_FACEUP,zone)
end

--========================================
-- EFFECT 4: EXTRA DECK ZONE RESTRICTION
--========================================

function s.fmval(e,c,fp,rp,r)
    --Collect all linked zones on the field,
    --including both players' Link Monsters.
    local g=Duel.GetMatchingGroup(
        s.atkfilter,0,LOCATION_MZONE,
        LOCATION_MZONE,nil)

    local zone=g:GetLinkedZone(rp)

    --Extra Monster Zones are always permitted.
    return zone|EXTRA_MONSTER_ZONES
end
