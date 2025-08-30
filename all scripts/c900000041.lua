local s,id=GetID()

--Custom Fusion Summon procedure functions
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.IsExistingMatchingCard(Card.IsFacedown,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,2,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local sg=g:Select(tp,2,2,nil)
    if sg then
        sg:KeepAlive()
        e:SetLabelObject(sg)
        return true
    else return false end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    Duel.SendtoGrave(g,REASON_COST)
    g:DeleteGroup()
end

--ATK gain function
function s.atkval(e,c)
    return Duel.GetMatchingGroupCount(Card.IsBanished,c:GetControler(),LOCATION_REMOVED,LOCATION_REMOVED,nil)*600
end

--Cost for destroy effect
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,6000) end
    Duel.PayLPCost(tp,6000)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD+LOCATION_HAND,1,nil) end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD+LOCATION_HAND)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD+LOCATION_HAND)
    if #g==0 then return end
    Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_CONFIRM)
    local sg=g:Select(1-tp,1,1,nil)
    g:Sub(sg)
    Duel.Destroy(g,REASON_EFFECT)
end

--Recover condition and functions
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_DESTROY) and rp==1-tp
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(4000)
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,4000)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Recover(p,d,REASON_EFFECT)
end

--Remove opponent's GY functions
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil) end
    local g=Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,0,LOCATION_GRAVE)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        --Restriction to Fiends
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
        e1:SetDescription(aux.Stringid(id,3))
        e1:SetCode(EFFECT_CANNOT_SUMMON)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.sumlimit)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        Duel.RegisterEffect(e2,tp)
    end
end

function s.sumlimit(e,c)
    return not c:IsRace(RACE_FIEND)
end

function s.initial_effect(c)
    --Fusion Summon condition (Custom: send 2 facedown cards)
    c:EnableReviveLimit()
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.spcon)
    e0:SetTarget(s.sptg)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)
    
    --ATK gain per banished card
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)
    
    --Quick Effect: Pay 6000 LP to destroy all opponent's cards except 1
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.descost)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    
    --If sent to GY by opponent, gain 4000 LP
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.reccon)
    e3:SetTarget(s.rectg)
    e3:SetOperation(s.recop)
    c:RegisterEffect(e3)
    
    --Banish opponent's GY, restriction to Fiends
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,2})
    e4:SetTarget(s.rmtg)
    e4:SetOperation(s.rmop)
    c:RegisterEffect(e4)
end