--Galaxy-Eyes Banish Spell
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--Check if player controls a "Galaxy-Eyes" Xyz Monster
function s.cfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x107b)
end

--Check if player controls Number 62 or Number C62
function s.number62filter(c)
    return c:IsFaceup() and (c:IsCode(31801517) or c:IsCode(48348921)) -- Number 62 or Number C62
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    --Check if player controls a "Galaxy-Eyes" Xyz Monster
    if not Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) then
        return false
    end
    
    --If not controlling Number 62, restrict activation
    local has_num62=Duel.IsExistingMatchingCard(s.number62filter,tp,LOCATION_MZONE,0,1,nil)
    if not has_num62 then
        return Duel.GetTurnPlayer()==tp -- Can only activate during own turn
    end
    
    return true
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,nil)
        if #g<=0 then return false end
        
        --Check if Number 62 or C62 is present for additional effect
        local has_num62=Duel.IsExistingMatchingCard(s.number62filter,tp,LOCATION_MZONE,0,1,nil)
        if has_num62 then
            g=g+Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_SZONE,nil)
        end
        
        return #g>0
    end
    
    local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,nil)
    
    --Check if Number 62 or C62 is present for additional effect
    local has_num62=Duel.IsExistingMatchingCard(s.number62filter,tp,LOCATION_MZONE,0,1,nil)
    if has_num62 then
        g=g+Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_SZONE,nil)
    end
    
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    --First banish all opponent's monsters
    local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_MZONE,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
    
    --Check if Number 62 or C62 is present for additional effect
    local has_num62=Duel.IsExistingMatchingCard(s.number62filter,tp,LOCATION_MZONE,0,1,nil)
    if has_num62 then
        local g2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_SZONE,nil)
        if #g2>0 then
            Duel.Remove(g2,POS_FACEUP,REASON_EFFECT)
        end
    end
    
    --If Number 62 was not present at activation, skip Battle Phase
    local had_num62_at_activation=e:GetLabel()==1
    if not had_num62_at_activation then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_BP)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
        e1:SetTargetRange(1,0)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    end
end

--Store whether Number 62 is present at activation
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    if Duel.IsExistingMatchingCard(s.number62filter,tp,LOCATION_MZONE,0,1,nil) then
        e:SetLabel(1)
    else
        e:SetLabel(0)
    end
    return true
end