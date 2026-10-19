
--The Lancer of World Chalice
local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    --Set 1 World Chalice/World Legacy Spell/Trap
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+
        EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.setcon)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    --Revive itself and another World Chalice monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+
        EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+
        EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id+1)
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

--==================================
-- FIRST EFFECT: SUMMON CONDITION
--==================================

function s.effectfilter(e)
    if not e then return false end

    local rc=e:GetHandler()
    return rc and
        (rc:IsSetCard(SET_WORLD_CHALICE)
        or rc:IsSetCard(SET_WORLD_LEGACY))
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    --Normal Summoned
    if c:IsSummonType(SUMMON_TYPE_NORMAL) then
        return true
    end

    --Special Summoned by an archetype effect
    if c:IsSummonType(SUMMON_TYPE_SPECIAL) then
        local se=c:GetReasonEffect()
        return s.effectfilter(se)
    end

    return false
end

--==================================
-- SET SPELL/TRAP FROM DECK
--==================================

function s.setfilter(c)
    return (c:IsSetCard(SET_WORLD_CHALICE)
        or c:IsSetCard(SET_WORLD_LEGACY))
        and c:IsSpellTrap()
        and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.setfilter,tp,LOCATION_DECK,
            0,1,nil)
    end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

    local g=Duel.SelectMatchingCard(
        tp,s.setfilter,tp,LOCATION_DECK,
        0,1,1,nil)

    if #g>0 then
        Duel.SSet(tp,g)
    end
end

--==================================
-- SECOND EFFECT: GY CONDITION
--==================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    --Sent to GY as Link Material
    if c:IsReason(REASON_MATERIAL)
        and c:IsReason(REASON_LINK) then
        return true
    end

    --Sent to GY by a World Chalice effect
    if c:IsReason(REASON_EFFECT) then
        local re=c:GetReasonEffect()
        return s.effectfilter(re)
            and re:GetHandler():IsSetCard(
                SET_WORLD_CHALICE)
    end

    return false
end

--==================================
-- TARGET ANOTHER WORLD CHALICE
--==================================

function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE)
            and chkc:IsControler(tp)
            and chkc~=e:GetHandler()
            and s.spfilter(chkc,e,tp)
    end

    if chk==0 then
        return Duel.GetLocationCount(
            tp,LOCATION_MZONE)>=2
            and e:GetHandler():IsCanBeSpecialSummoned(
                e,0,tp,false,false)
            and Duel.IsExistingTarget(
                s.spfilter,tp,LOCATION_GRAVE,
                0,1,e:GetHandler(),e,tp)
    end

    Duel.Hint(
        HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    Duel.SelectTarget(
        tp,s.spfilter,tp,LOCATION_GRAVE,
        0,1,1,e:GetHandler(),e,tp)

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,
        nil,2,tp,LOCATION_GRAVE)
end

--==================================
-- BOTTOM OF DECK REPLACEMENT
--==================================

function s.deckval(e,re,r,rp)
    return true
end

function s.applyreturn(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
    e1:SetValue(LOCATION_DECKBOT)
    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
    c:RegisterEffect(e1)
end

--==================================
-- REVIVE BOTH MONSTERS
--==================================

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()

    if not c:IsRelateToEffect(e)
        or not tc
        or not tc:IsRelateToEffect(e) then
        return
    end

    if Duel.GetLocationCount(
        tp,LOCATION_MZONE)<2 then
        return
    end

    if not c:IsCanBeSpecialSummoned(
        e,0,tp,false,false)
        or not s.spfilter(tc,e,tp) then
        return
    end

    local g=Group.FromCards(c,tc)

    if Duel.SpecialSummon(
        g,0,tp,tp,false,false,
        POS_FACEUP)==2 then

        s.applyreturn(c)
        s.applyreturn(tc)
    end
end
