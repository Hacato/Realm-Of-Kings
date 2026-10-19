
--World Legacy - World Chalice Justiciar Guardragon
--Card ID: 800000300
local s,id=GetID()

local SET_WORLD_CHALICE=0xfd
local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    c:EnableReviveLimit()

    --1 non-Link "World Chalice" monster
    Link.AddProcedure(c,s.matfilter,1,1)

    --Search World Legacy card or Field Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --Summon World Chalice Normal Monster
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    --Negate opponent's targeting effect
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_NEGATE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+2)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    --Destruction replacement
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+2)
    e4:SetTarget(s.reptg)
    e4:SetValue(s.repval)
    c:RegisterEffect(e4)

    --Revive when sent to GY
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,4))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetCode(EVENT_TO_GRAVE)
    e5:SetCountLimit(1,id+3)
    e5:SetCondition(s.gycon)
    e5:SetTarget(s.gytg)
    e5:SetOperation(s.gyop)
    c:RegisterEffect(e5)

    --Record whether this card was Link Summoned
    --before it leaves the field
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_LEAVE_FIELD_P)
    e6:SetOperation(s.leaveop)
    e6:SetLabelObject(e5)
    c:RegisterEffect(e6)
end

--========================================
-- LINK MATERIAL
--========================================

function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and not c:IsType(TYPE_LINK)
end

--========================================
-- EFFECT 1: SEARCH AND SEND
--========================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
    return (c:IsSetCard(SET_WORLD_LEGACY)
        or c:IsType(TYPE_FIELD))
        and c:IsAbleToHand()
end

function s.normalfilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_MONSTER)
        and c:IsType(TYPE_NORMAL)
        and c:IsAbleToGrave()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(
        0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g==0 then return end

    if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then
        return
    end
    Duel.ConfirmCards(1-tp,g)

    if Duel.IsExistingMatchingCard(
        s.normalfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then

        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sg=Duel.SelectMatchingCard(
            tp,s.normalfilter,tp,LOCATION_DECK,
            0,1,1,nil)
        if #sg>0 then
            Duel.SendtoGrave(sg,REASON_EFFECT)
        end
    end
end

--========================================
-- EFFECT 2: SUMMON TO LINKED ZONE
--========================================

function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_MONSTER)
        and c:IsType(TYPE_NORMAL)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local zone=e:GetHandler():GetLinkedZone(tp)&0x1f
    if chk==0 then
        return zone~=0
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
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
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    local zone=c:GetLinkedZone(tp)&0x1f
    if zone==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,
        LOCATION_HAND|LOCATION_GRAVE,
        0,1,1,nil,e,tp)
    local tc=g:GetFirst()

    if tc then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP,zone)
    end
end

--========================================
-- PROTECTION FILTERS
--========================================

function s.costfilter(c)
    return c:IsType(TYPE_MONSTER)
        and c:IsType(TYPE_NORMAL)
        and c:IsAbleToDeckAsCost()
end

function s.wcfilter(c,tp)
    return c:IsFaceup()
        and c:IsControler(tp)
        and c:IsSetCard(SET_WORLD_CHALICE)
end

--========================================
-- EFFECT 3: TARGETING NEGATION
--========================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp or not Duel.IsChainNegatable(ev) then
        return false
    end

    if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
        return false
    end

    local g=Duel.GetChainInfo(
        ev,CHAININFO_TARGET_CARDS)

    return g and g:IsExists(s.wcfilter,1,nil,tp)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.costfilter,tp,LOCATION_GRAVE,0,1,nil)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(
        tp,s.costfilter,tp,LOCATION_GRAVE,
        0,1,1,nil)

    if #g>0 then
        Duel.SendtoDeck(
            g,nil,SEQ_DECKSHUFFLE,REASON_COST)
    end
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(
        0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateActivation(ev)
end

--========================================
-- EFFECT 4: DESTRUCTION REPLACEMENT
--========================================

function s.repfilter(c,tp)
    return c:IsFaceup()
        and c:IsControler(tp)
        and c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsLocation(LOCATION_MZONE)
        and c:IsReason(REASON_BATTLE|REASON_EFFECT)
        and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return eg:IsExists(s.repfilter,1,nil,tp)
            and Duel.IsExistingMatchingCard(
                s.costfilter,tp,LOCATION_GRAVE,0,1,nil)
    end

    if not Duel.SelectEffectYesNo(
        tp,e:GetHandler(),aux.Stringid(id,3)) then
        return false
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(
        tp,s.costfilter,tp,LOCATION_GRAVE,
        0,1,1,nil)

    if #g==0 then return false end

    return Duel.SendtoDeck(
        g,nil,SEQ_DECKSHUFFLE,REASON_COST)>0
end

function s.repval(e,c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsControler(e:GetHandlerPlayer())
        and c:IsLocation(LOCATION_MZONE)
end

--========================================
-- EFFECT 5: LEAVE-FIELD REVIVAL
--========================================

--Save summon status while the card is still on field.
function s.leaveop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local te=e:GetLabelObject()
    if te then
        if c:IsSummonType(SUMMON_TYPE_LINK) then
            te:SetLabel(1)
        else
            te:SetLabel(0)
        end
    end
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE)
        and e:GetLabel()==1
end

function s.gyfilter(c,e,tp)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_MONSTER)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(
            tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.gyfilter,tp,
                LOCATION_HAND|LOCATION_GRAVE,
                0,1,nil,e,tp)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
        LOCATION_HAND|LOCATION_GRAVE)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(
        tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.gyfilter,tp,
        LOCATION_HAND|LOCATION_GRAVE,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if tc then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP)
    end
end
