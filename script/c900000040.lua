--Rage Of The Underworld
local s,id=GetID()
function s.initial_effect(c)
    --Hand effect: Discard to send Extra Deck monster to GY and draw 2
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.handcost)
    e1:SetTarget(s.handtg)
    e1:SetOperation(s.handop)
    c:RegisterEffect(e1)
    
    --GY effect: Banish to negate and shuffle everything back
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetCost(s.negcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
end

--Hand effect functions
function s.handcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

function s.exfilter(c)
    return c:IsMonster() and c:IsAbleToGrave()
end

function s.handtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) 
        and Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.handop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        if Duel.Draw(tp,2,REASON_EFFECT)>0 then
            --Restriction: Can only summon Fiend monsters for the rest of this turn
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD)
            e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
            e1:SetCode(EFFECT_CANNOT_SUMMON)
            e1:SetTargetRange(1,0)
            e1:SetTarget(s.sumlimit)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
            Duel.RegisterEffect(e2,tp)
            local e3=e1:Clone()
            e3:SetCode(EFFECT_CANNOT_MSET)
            Duel.RegisterEffect(e3,tp)
            aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,2),1)
        end
    end
end

function s.sumlimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsRace(RACE_FIEND)
end

--GY effect functions
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local g1=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    local g2=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_GRAVE+LOCATION_REMOVED,nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,#g1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local g1=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        local g2=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_GRAVE+LOCATION_REMOVED,nil)
        g1:Merge(g2)
        if #g1>0 then
            Duel.SendtoDeck(g1,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end