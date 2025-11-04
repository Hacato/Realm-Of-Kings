--YuYuYu Flower Calming Ceremony
local s,id=GetID()
function s.initial_effect(c)
    --(1) Draw and shuffle back Pendulum monsters
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end
s.listed_names={0x991} --YuYuYu archetype

--(1) Check if 2 "YuYuYu" cards in Pendulum Zones
function s.pzfilter(c)
    return c:IsSetCard(0x991)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.pzfilter,tp,LOCATION_PZONE,0,2,nil)
end

--Filter face-up "YuYuYu" Pendulum monsters in Extra Deck
function s.edfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x991) and c:IsType(TYPE_PENDULUM)
end

--Target function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.edfilter,tp,LOCATION_EXTRA,0,nil)
    local ct=g:GetCount()
    local deck_ct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
    local draw_ct=math.min(ct,deck_ct)
    if chk==0 then
        return draw_ct>0 and Duel.IsPlayerCanDraw(tp,draw_ct)
    end
    Duel.SetTargetPlayer(tp)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,draw_ct)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,tp,LOCATION_EXTRA)
end

--Activation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.edfilter,tp,LOCATION_EXTRA,0,nil)
    local ct=g:GetCount()
    if ct>0 then
        local deck_ct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
        local draw_ct=math.min(ct,deck_ct)
        if draw_ct>0 then
            Duel.Draw(tp,draw_ct,REASON_EFFECT)
            Duel.BreakEffect()
            Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end

    --Cannot Special Summon except "YuYuYu" monsters
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

--Special Summon limit
function s.splimit(e,c)
    return not c:IsSetCard(0x991)
end
