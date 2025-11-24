-- Wyrm Excavator the Heavy Cavalry Draco [R]
local s,id=GetID()
function s.initial_effect(c)
    ---------------------------------------------------------------
    -- 1. Place 1 card from your GY on bottom of Deck → Destroy S/T → Draw
    ---------------------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.maxCon)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
    c:AddSideMaximumHandler(e1)

    ---------------------------------------------------------------
    -- 2. If your Spell/Trap is destroyed → return 1 banished "Earth Wyrm" piece
    ---------------------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id+1000)
    e2:SetCondition(s.stcon)
    e2:SetTarget(s.sttg)
    e2:SetOperation(s.stop)
    c:RegisterEffect(e2)
    c:AddSideMaximumHandler(e2)

    ---------------------------------------------------------------
    -- 3. GY Effect: Shuffle into Deck → Set "Constructor" or "Demolition" S/T
    ---------------------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TODECK+CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id+2000)
    e3:SetTarget(s.gytg)
    e3:SetOperation(s.gyop)
    c:RegisterEffect(e3)
end

-- Right-side Maximum Mode check
s.MaximumSide="Right"
function s.maxCon(e)
    return e:GetHandler():IsMaximumModeCenter()
end

---------------------------------------------------------------
-- Cost: Place 1 card from GY to bottom of Deck
---------------------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeckOrExtraAsCost,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeckOrExtraAsCost,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_COST)
end

---------------------------------------------------------------
-- Target Spell/Trap to destroy
---------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local dg=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler())
    if chk==0 then return e:GetHandler():IsMaximumMode() and #dg>0 and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,dg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

---------------------------------------------------------------
-- Operation: Destroy Spell/Trap → Draw
---------------------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    -- Select card to place on bottom of Deck (cost already applied)
    -- Destroy Spell/Trap
    local dg=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,e:GetHandler())
    if #dg==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local sg=dg:Select(tp,1,1,nil)
    if #sg>0 and Duel.Destroy(sg,REASON_EFFECT)>0 then
        Duel.Draw(tp,1,REASON_EFFECT)
        local tc=sg:GetFirst()
        if tc:IsType(TYPE_FIELD) and Duel.IsPlayerCanDraw(tp,1) and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.Draw(tp,1,REASON_EFFECT)
        end
    end
end

---------------------------------------------------------------
-- Trigger: Check destroyed Spell/Trap you control
---------------------------------------------------------------
function s.stfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.stcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.stfilter,1,nil,tp)
end

---------------------------------------------------------------
-- Target banished "Earth Wyrm" piece
---------------------------------------------------------------
function s.excPiece(c)
    return c:IsFaceup() and c:IsAbleToHand() and (c:IsCode(800000119) or c:IsCode(800000121))
end

function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.excPiece,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_REMOVED)
end

---------------------------------------------------------------
-- Retrieve banished piece
---------------------------------------------------------------
function s.stop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.SelectMatchingCard(tp,s.excPiece,tp,LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

---------------------------------------------------------------
-- GY Effect: Filter for "Constructor" or "Demolition" S/T
---------------------------------------------------------------
function s.setfilter(c)
    return (c:IsSetCard(0x1568) or c:IsSetCard(0x801)) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToDeck() 
        and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 
        and c:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SSet(tp,g)
        end
    end
end