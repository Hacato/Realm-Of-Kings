
--Orcustrion the Knightmare Guardragon
local s,id=GetID()

function s.initial_effect(c)
    --Link Summon: 3+ monsters with different names
    Link.AddProcedure(c,nil,3,99,s.matcheck)
    c:EnableReviveLimit()

    --This linked card cannot be destroyed by battle
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetCondition(s.indcon)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    --This linked card cannot be destroyed by effects
    local e2=e1:Clone()
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e2)

    --If Link Summoned: discard 1 card;
    --negate all face-up cards opponent controls.
    --If co-linked at activation, optionally draw 1.
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_DISABLE+CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)

    --Target 1 monster this card points to;
    --banish it, then optionally add
    --1 "World Legacy" card from Deck.
    --Normal Ignition version without Babel.
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(
        CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetCondition(s.nobabelcon)
    e4:SetTarget(s.rmtg)
    e4:SetOperation(s.rmop)
    c:RegisterEffect(e4)

    --Quick Effect version with Orcustrated Babel.
    --Shares the same once-per-turn limit.
    local e5=e4:Clone()
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetCondition(s.babelcon)
    e5:SetHintTiming(
        0,TIMING_MAIN_END|TIMING_END_PHASE)
    c:RegisterEffect(e5)
end

s.listed_series={SET_ORCUST,SET_WORLD_LEGACY}
s.listed_names={CARD_ORCUSTRATED_BABEL}

--========================================
-- LINK MATERIAL REQUIREMENTS
--========================================

function s.matcheck(g,lc,sumtype,tp)
    return g:CheckDifferentProperty(
        Card.GetCode,lc,sumtype,tp)
end

--========================================
-- PROTECTION WHILE LINKED
--========================================

function s.indcon(e)
    return e:GetHandler():IsLinked()
end

--========================================
-- ORCUSTRATED BABEL CONDITIONS
--========================================

function s.babelcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsPlayerAffectedByEffect(
        tp,CARD_ORCUSTRATED_BABEL)
end

function s.nobabelcon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsPlayerAffectedByEffect(
        tp,CARD_ORCUSTRATED_BABEL)
end

--========================================
-- EFFECT 1: NEGATE ALL FACE-UP CARDS
--========================================

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(
        SUMMON_TYPE_LINK)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            Card.IsDiscardable,tp,
            LOCATION_HAND,0,1,nil)
    end

    Duel.DiscardHand(
        tp,Card.IsDiscardable,
        1,1,REASON_COST+REASON_DISCARD)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            Card.IsFaceup,tp,
            0,LOCATION_ONFIELD,1,nil)
    end

    --Remember whether Orcustrion was co-linked
    --when this effect was activated.
    if e:GetHandler():GetMutualLinkedGroupCount()>0 then
        e:SetLabel(1)
    else
        e:SetLabel(0)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)

    if e:GetLabel()==1 then
        Duel.SetPossibleOperationInfo(
            0,CATEGORY_DRAW,nil,1,tp,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(
        Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)

    for tc in g:Iter() do
        if tc:IsFaceup() then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(
                RESET_EVENT|RESETS_STANDARD)
            tc:RegisterEffect(e1)

            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetReset(
                RESET_EVENT|RESETS_STANDARD)
            tc:RegisterEffect(e2)
        end
    end

    --Optional draw if co-linked at activation.
    if e:GetLabel()==1
        and Duel.IsPlayerCanDraw(tp,1)
        and Duel.SelectYesNo(
            tp,aux.Stringid(id,1)) then

        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end

--========================================
-- EFFECT 2: BANISH LINKED MONSTER
--========================================

function s.rmfilter(c,g)
    return c:IsAbleToRemove()
        and g:IsContains(c)
end

function s.thfilter(c)
    return c:IsSetCard(SET_WORLD_LEGACY)
        and c:IsAbleToHand()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local lg=e:GetHandler():GetLinkedGroup()

    if chkc then
        return chkc:IsLocation(LOCATION_MZONE)
            and s.rmfilter(chkc,lg)
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.rmfilter,tp,
            LOCATION_MZONE,LOCATION_MZONE,
            1,nil,lg)
    end

    Duel.Hint(
        HINT_SELECTMSG,tp,HINTMSG_REMOVE)

    local g=Duel.SelectTarget(
        tp,s.rmfilter,tp,
        LOCATION_MZONE,LOCATION_MZONE,
        1,1,nil,lg)

    Duel.SetOperationInfo(
        0,CATEGORY_REMOVE,g,1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e) then
        return
    end

    --Banish the targeted monster.
    if Duel.Remove(
        tc,POS_FACEUP,REASON_EFFECT)>0 then

        --Optionally search a World Legacy card.
        if Duel.IsExistingMatchingCard(
            s.thfilter,tp,
            LOCATION_DECK,0,1,nil)
            and Duel.SelectYesNo(
                tp,aux.Stringid(id,3)) then

            Duel.Hint(
                HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

            local g=Duel.SelectMatchingCard(
                tp,s.thfilter,tp,
                LOCATION_DECK,0,1,1,nil)

            if #g>0 then
                Duel.SendtoHand(
                    g,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,g)
            end
        end
    end
end
