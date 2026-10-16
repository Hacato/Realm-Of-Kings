
-- World Legacy Fairy
-- DARK / Fairy / Link / Effect
-- LINK-1 / ATK 0
-- Material: 1 Machine monster

local s,id=GetID()

local SET_WORLD_LEGACY=0xfe
local LEE=21893603

function s.initial_effect(c)
    -- Link Summon: 1 Machine monster
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,1,1)

    -- If Link Summoned: recover World Legacy
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- Banish from GY: search Lee or World Legacy
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.secost)
    e2:SetTarget(s.setg)
    e2:SetOperation(s.seop)
    c:RegisterEffect(e2)
end

s.listed_series={SET_WORLD_LEGACY}
s.listed_names={LEE}

-- Link Material
function s.matfilter(c,lc,sumtype,tp)
    return c:IsRace(RACE_MACHINE)
end

-- Effect 1: Link Summon recovery
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
    return c:IsSetCard(SET_WORLD_LEGACY)
        and c:IsAbleToHand()
        and (not c:IsLocation(LOCATION_REMOVED)
            or c:IsFaceup())
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(tp)
            and chkc:IsLocation(
                LOCATION_GRAVE+LOCATION_REMOVED)
            and s.thfilter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(
            s.thfilter,tp,
            LOCATION_GRAVE+LOCATION_REMOVED,
            0,1,nil)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(
        tp,s.thfilter,tp,
        LOCATION_GRAVE+LOCATION_REMOVED,
        0,1,1,nil)
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,g,1,tp,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e)
        and s.thfilter(tc) then
        if Duel.SendtoHand(
            tc,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,tc)
        end
    end
end

-- Effect 2: Banish from GY as cost
function s.secost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsAbleToRemoveAsCost()
    end
    Duel.Remove(
        e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- Search Lee or World Legacy
function s.sefilter(c)
    return (c:IsCode(LEE)
        or c:IsSetCard(SET_WORLD_LEGACY))
        and c:IsAbleToHand()
end

function s.setg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.sefilter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.seop(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsExistingMatchingCard(
        s.sefilter,tp,LOCATION_DECK,0,1,nil) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.sefilter,tp,LOCATION_DECK,0,1,1,nil)

    if #g>0 and Duel.SendtoHand(
        g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
    end
end
