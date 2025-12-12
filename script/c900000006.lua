--Slayer - Inferno The Blazing Warrior
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --This card is always treated as every attribute
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_ATTRIBUTE)
    e1:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
    e1:SetValue(ATTRIBUTE_EARTH+ATTRIBUTE_WATER+ATTRIBUTE_FIRE+ATTRIBUTE_WIND+ATTRIBUTE_LIGHT+ATTRIBUTE_DARK+ATTRIBUTE_DIVINE)
    c:RegisterEffect(e1)
    
    --Add Slayer card from banished/GY when summoned
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
    c:RegisterEffect(e3)
    local e4=e2:Clone()
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e4)
    
    --Discard 1 Slayer card to draw 2 cards
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1,id)
    e5:SetCost(s.drawcost)
    e5:SetTarget(s.drawtg)
    e5:SetOperation(s.drawop)
    c:RegisterEffect(e5)
end

--Add Slayer card from banished/GY
function s.thfilter(c)
    return c:IsSetCard(0x2407) and c:IsAbleToHand() 
        and (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if g:GetCount()>0 then
        local tc=g:GetFirst()
        local is_extra_deck_monster=tc:IsType(TYPE_FUSION+TYPE_XYZ+TYPE_SYNCHRO)
        
        if Duel.SendtoHand(tc,nil,REASON_EFFECT)~=0 then
            if tc:IsLocation(LOCATION_HAND) then
                --Successfully added to hand (Main Deck monster)
                Duel.ConfirmCards(1-tp,tc)
            elseif is_extra_deck_monster and tc:IsLocation(LOCATION_EXTRA) then
                --Extra Deck monster went to Extra Deck instead, draw 1 card
                if Duel.IsPlayerCanDraw(tp,1) then
                    Duel.BreakEffect()
                    Duel.Draw(tp,1,REASON_EFFECT)
                end
            end
        end
    end
end

--Discard cost for draw effect
function s.drawcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.discardfilter,tp,LOCATION_HAND,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    local g=Duel.SelectMatchingCard(tp,s.discardfilter,tp,LOCATION_HAND,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

function s.discardfilter(c)
    return c:IsSetCard(0x2407) and c:IsDiscardable()
end

--Draw target
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

--Draw operation
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end