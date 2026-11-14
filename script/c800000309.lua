
--Imduk the Soul World Chalice Dragon
--Card ID: 800000309
--2 Normal Monsters

local s,id=GetID()
local SET_WORLD_CHALICE=0xfd

s.listed_series={SET_WORLD_CHALICE}

function s.initial_effect(c)
    --Link Summon: 2 Normal Monsters
    c:EnableReviveLimit()
    Link.AddProcedure(c,
        aux.FilterBoolFunctionEx(Card.IsType,TYPE_NORMAL),
        2,2)

    --Force opponent to Special Summon only
    --to Main Monster Zones this card points to
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_FORCE_MZONE)
    e1:SetRange(LOCATION_EMZONE)
    e1:SetTargetRange(LOCATION_ALL,LOCATION_ALL)
    e1:SetCondition(s.fmcon)
    e1:SetValue(s.fmval)
    c:RegisterEffect(e1)

    --Quick Effect: Destroy a linked monster
    --and this card, then optionally search
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(
        CATEGORY_DESTROY|CATEGORY_TOHAND|CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

--========================================
-- SPECIAL SUMMON ZONE RESTRICTION
--========================================

function s.fmcon(e)
    local c=e:GetHandler()

    --Must be in an Extra Monster Zone
    if not c:IsInExtraMZone() then
        return false
    end

    --Restriction is disabled if Imduk points
    --to an opponent-controlled monster
    local lg=c:GetLinkedGroup()

    return not lg:IsExists(
        Card.IsControler,1,nil,1-c:GetControler())
end

function s.fmval(e,c,fp,rp,r)
    local lc=e:GetHandler()

    --Do not restrict Imduk's controller
    if rp==lc:GetControler() then
        return 0x7f007f
    end

    --Only allow the opponent to Special Summon
    --into Main Monster Zones Imduk points to
    local zone=lc:GetLinkedZone(rp)

    return zone&0x1f
end

--========================================
-- TARGET MONSTER THIS CARD POINTS TO
--========================================

function s.desfilter(c,lc)
    return lc:GetLinkedGroup():IsContains(c)
        and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local c=e:GetHandler()

    if chkc then
        return chkc:IsOnField()
            and s.desfilter(chkc,c)
    end

    if chk==0 then
        return c:IsDestructable()
            and Duel.IsExistingTarget(
                s.desfilter,tp,
                LOCATION_MZONE,LOCATION_MZONE,
                1,nil,c)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

    local g=Duel.SelectTarget(
        tp,s.desfilter,tp,
        LOCATION_MZONE,LOCATION_MZONE,
        1,1,nil,c)

    g:AddCard(c)

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,g,2,0,0)

    Duel.SetPossibleOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--========================================
-- SEARCH WORLD CHALICE CARD
--========================================

function s.thfilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsAbleToHand()
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e)
        or not c:IsRelateToEffect(e) then
        return
    end

    local g=Group.FromCards(tc,c)

    --Both monsters must be destroyed
    if Duel.Destroy(g,REASON_EFFECT)==2
        and Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then

        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

        local sg=Duel.SelectMatchingCard(
            tp,s.thfilter,tp,
            LOCATION_DECK,0,1,1,nil)

        if #sg>0 then
            Duel.SendtoHand(sg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,sg)
        end
    end
end
