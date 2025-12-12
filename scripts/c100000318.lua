--Puzzle HERO Manic Maestro
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon itself from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    --Take control after battle
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DAMAGE_STEP_END)
    e2:SetCondition(s.ctcon)
    e2:SetTarget(s.cttg)
    e2:SetOperation(s.ctop)
    c:RegisterEffect(e2)
end

--Special Summon condition
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x8)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--Take control condition
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not Duel.GetAttackTarget() or not Duel.GetAttacker() then return false end
    
    local bc=nil
    if c==Duel.GetAttacker() then
        bc=Duel.GetAttackTarget()
    elseif c==Duel.GetAttackTarget() then
        bc=Duel.GetAttacker()
    else
        return false
    end
    
    return bc and bc:IsRelateToBattle() and not bc:IsStatus(STATUS_BATTLE_DESTROYED)
end

--Take control target
function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local bc=nil
    if c==Duel.GetAttacker() then
        bc=Duel.GetAttackTarget()
    else
        bc=Duel.GetAttacker()
    end
    
    if chk==0 then return bc and bc:IsRelateToBattle() and not bc:IsStatus(STATUS_BATTLE_DESTROYED) 
        and bc:IsControlerCanBeChanged() end
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,bc,1,0,0)
end

--Take control operation
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=nil
    if c==Duel.GetAttacker() then
        bc=Duel.GetAttackTarget()
    else
        bc=Duel.GetAttacker()
    end
    
    if bc and bc:IsRelateToBattle() and not bc:IsStatus(STATUS_BATTLE_DESTROYED) then
        Duel.GetControl(bc,tp)
    end
end