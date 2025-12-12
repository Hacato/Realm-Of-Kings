--Galaxy-Photon Number Dragon
--Xyz monster requiring 3 Level 8 monsters
local s,id=GetID()
function s.initial_effect(c)
    --Xyz summon procedure
    Xyz.AddProcedure(c,nil,8,3)
    c:EnableReviveLimit()
    
    --Multiple attacks
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
    e1:SetValue(s.atkval)
    c:RegisterEffect(e1)
    
    --Detach to Special Summon and reduce ATK/DEF
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_ATTACK_ANNOUNCE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.spcon)
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--Count "Photon" and "Galaxy" materials for extra attacks
function s.atkval(e,c)
    local ct=0
    for i=1,c:GetOverlayCount() do
        local oc=c:GetOverlayGroup():GetFirst()
        if oc:IsSetCard(0x55) or oc:IsSetCard(0x7b) then --0x55 is Photon, 0x7b is Galaxy
            ct=ct+1
        end
    end
    return ct
end

--Condition for Special Summon effect
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return (c==Duel.GetAttacker() and Duel.GetAttackTarget() and Duel.GetAttackTarget():IsControler(1-tp))
        or (c==Duel.GetAttackTarget() and Duel.GetAttacker():IsControler(1-tp))
end

--Cost for Special Summon effect
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Filter for Number monsters
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x48) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

--Target for Special Summon effect
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--Operation for Special Summon and ATK/DEF reduction
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    -- Determine the opponent's monster
    local oc
    if Duel.GetAttacker()==e:GetHandler() then
        oc=Duel.GetAttackTarget()
    else
        oc=Duel.GetAttacker()
    end
    
    -- Special Summon Number monster
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if not tc or not Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE) then return end
    
    -- Reduce opponent's monster ATK and DEF if still on the field
    if oc and oc:IsRelateToBattle() and oc:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(-tc:GetBaseAttack())
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        oc:RegisterEffect(e1)
        
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        e2:SetValue(-tc:GetBaseDefense())
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        oc:RegisterEffect(e2)
    end
end