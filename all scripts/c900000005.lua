--Slayer-Jörmungandr The Dragon of Divinity
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --Fusion procedure
    c:EnableReviveLimit()
    Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunction(Card.IsSetCard,0x2407),2)
    
    --This card is always treated as every attribute
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_ATTRIBUTE)
    e1:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
    e1:SetValue(ATTRIBUTE_EARTH+ATTRIBUTE_WATER+ATTRIBUTE_FIRE+ATTRIBUTE_WIND+ATTRIBUTE_LIGHT+ATTRIBUTE_DARK+ATTRIBUTE_DIVINE)
    c:RegisterEffect(e1)
    
    --Banish opponent's hand and GY if summoned using opponent's monster
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.rmcon)
    e2:SetTarget(s.rmtg)
    e2:SetOperation(s.rmop)
    c:RegisterEffect(e2)
    
    --Quick Effect: Negate opponent's card/effect (twice per turn)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_TOGRAVE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(2,id)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
    
    --When sent to GY: opponent banishes from hand or field
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_SINGLE)
    e4:SetCode(EVENT_TO_GRAVE)
    e4:SetTarget(s.rmtg2)
    e4:SetOperation(s.rmop2)
    c:RegisterEffect(e4)
end

--Check if summoned using opponent's monster
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) then return false end
    local mg=e:GetHandler():GetMaterial()
    return mg and mg:IsExists(Card.IsControler,1,nil,1-tp)
end

--Banish opponent's hand and GY
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_HAND+LOCATION_GRAVE,1,nil) end
    local g1=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil)
    local g2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g1,g1:GetCount(),0,0)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g2,g2:GetCount(),0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local g1=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_HAND,nil)
    local g2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
    g1:Merge(g2)
    if g1:GetCount()>0 then
        Duel.Remove(g1,POS_FACEDOWN,REASON_EFFECT)
    end
end

--Negate condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end

--Negate cost
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end

function s.costfilter(c)
    return c:IsSetCard(0x2407) and c:IsAbleToGrave()
end

--Negate target
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsDestructable() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

--Negate operation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg,REASON_EFFECT)
    end
end

--When sent to GY target
function s.rmtg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local g1=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    local g2=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
    if g1:GetCount()>0 then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
    elseif g2:GetCount()>0 then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,g2,g2:GetCount(),0,0)
    end
end

--When sent to GY operation
function s.rmop2(e,tp,eg,ep,ev,re,r,rp)
    local g1=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    if g1:GetCount()>0 then
        --Banish 1 random card from opponent's hand
        local sg=g1:RandomSelect(tp,1)
        Duel.Remove(sg,POS_FACEDOWN,REASON_EFFECT)
    else
        --Banish all cards on opponent's field
        local g2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
        if g2:GetCount()>0 then
            Duel.Remove(g2,POS_FACEDOWN,REASON_EFFECT)
        end
    end
end