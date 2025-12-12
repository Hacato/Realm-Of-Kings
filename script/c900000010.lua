--Denial Of The Eternal God
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --This card is always treated as a "Slayer" card
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_SETCODE)
    e1:SetRange(LOCATION_SZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
    e1:SetValue(0x2407)
    c:RegisterEffect(e1)
    
    --Negate summon or card/effect activation
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_CHAINING)
    e2:SetCondition(s.condition)
    e2:SetTarget(s.target)
    e2:SetOperation(s.activate)
    c:RegisterEffect(e2)
    
    --Negate summon
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_ACTIVATE)
    e3:SetCode(EVENT_SUMMON)
    e3:SetCondition(s.condition2)
    e3:SetTarget(s.target2)
    e3:SetOperation(s.activate2)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_FLIP_SUMMON)
    c:RegisterEffect(e4)
    local e5=e3:Clone()
    e5:SetCode(EVENT_SPSUMMON)
    c:RegisterEffect(e5)
    
    --Can activate from hand if you control no cards
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e6:SetCondition(s.handcon)
    c:RegisterEffect(e6)
end

--Hand activation condition
function s.handcon(e)
    return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),LOCATION_ONFIELD,0)==0
end

--Condition for negating card/effect activation
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsChainNegatable(ev) and rp~=tp
end

--Target for negating card/effect activation
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsAbleToRemove() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

--Operation for negating card/effect activation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Remove(eg,POS_FACEDOWN,REASON_EFFECT)
    end
end

--Condition for negating summon
function s.condition2(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentChain()==0 and eg:GetFirst():IsControler(1-tp)
end

--Target for negating summon
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,eg:GetCount(),0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,eg:GetCount(),0,0)
end

--Operation for negating summon
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateSummon(eg) then
        Duel.Remove(eg,POS_FACEDOWN,REASON_EFFECT)
    end
end