
--Seafarer's Ultimate Fate
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Target 3 Seafarer monsters in your GY;
    --shuffle them into the Deck, draw 1,
    --then add 1 Seafarer monster from Deck to hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+
        CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--Seafarer monsters in your GY that can return to Deck
function s.tdfilter(c)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToDeck()
end

--Seafarer monsters in Deck that can be added to hand
function s.thfilter(c)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(tp)
            and chkc:IsLocation(LOCATION_GRAVE)
            and s.tdfilter(chkc)
    end

    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
            and Duel.IsExistingTarget(
                s.tdfilter,tp,LOCATION_GRAVE,0,3,nil
            )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(
        tp,s.tdfilter,tp,LOCATION_GRAVE,0,3,3,nil
    )

    Duel.SetOperationInfo(
        0,CATEGORY_TODECK,g,3,tp,LOCATION_GRAVE
    )
    Duel.SetOperationInfo(
        0,CATEGORY_DRAW,nil,0,tp,1
    )
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
    )
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    --Get the 3 targeted Seafarer monsters
    local g=Duel.GetTargetCards(e)
    if #g~=3 then return end

    --All 3 must still be valid GY targets
    if g:FilterCount(s.tdfilter,nil)~=3 then return end

    --Return all 3 to Deck / Extra Deck as appropriate
    local ct=Duel.SendtoDeck(
        g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT
    )

    --Only continue if all 3 were returned
    if ct~=3 then return end

    Duel.BreakEffect()

    --Draw 1 card
    if Duel.Draw(tp,1,REASON_EFFECT)==0 then return end

    --Then add 1 Seafarer monster from Deck to hand
    if not Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_DECK,0,1,nil
    ) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local sg=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
    )

    if #sg>0 and Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,sg)
    end
end
