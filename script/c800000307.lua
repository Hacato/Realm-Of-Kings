
--Guardragon Trial
--Dragon / Tuner / Effect
local s,id=GetID()

function s.initial_effect(c)
    --Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.spcon)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Negate Spell/Trap Card activation
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

--====================================
-- SPECIAL SUMMON PROCEDURE
--====================================

function s.sendfilter(c)
    return c:IsRace(RACE_DRAGON)
        and c:IsType(TYPE_NORMAL)
        and c:IsAbleToGrave()
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.sendfilter,tp,
            LOCATION_HAND|LOCATION_DECK,
            0,1,c)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local tp=c:GetControler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.sendfilter,tp,
        LOCATION_HAND|LOCATION_DECK,0,1,1,c)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_COST)
    end
end

--====================================
-- SPELL/TRAP NEGATION
--====================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp
        and re:IsHasType(EFFECT_TYPE_ACTIVATE)
        and re:IsActiveType(TYPE_SPELL|TYPE_TRAP)
        and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsReleasable()
    end
    Duel.Release(e:GetHandler(),REASON_COST)
end

function s.thfilter(c)
    return c:IsRace(RACE_DRAGON)
        and c:IsType(TYPE_NORMAL)
        and c:IsAbleToHand()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,
        nil,1,tp,LOCATION_GRAVE)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev)
        and Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_GRAVE,0,1,nil) then

        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,
            LOCATION_GRAVE,0,1,1,nil)

        if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
