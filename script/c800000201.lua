local s,id=GetID()

function s.initial_effect(c)
    -- Cannot be Normal Summoned/Set
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_CANNOT_DISABLE)
    e0:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(e0)
    
    -- (1) Special Summon from hand when a "SZS" monster is destroyed (Quick Effect)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_DESTROYED)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Destroy both this card and opponent's monster in battle
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_BATTLE_START)
    e2:SetCondition(s.descon)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
    
    -- (3) "SZS" Xyz Monster using this card as material cannot be destroyed
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.efcon)
    e3:SetOperation(s.efop)
    c:RegisterEffect(e3)
end

function s.spfilter(c,tp)
    return c:IsSetCard(0x2406) and c:IsReason(REASON_BATTLE|REASON_EFFECT)
        and c:GetPreviousControler()==tp and c:IsPreviousLocation(LOCATION_ONFIELD)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spfilter,1,nil,tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) Destroy both cards when battle starts
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    return bc~=nil
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if c:IsRelateToEffect(e) and bc then
        local g=Group.FromCards(c,bc)
        Duel.Destroy(g,REASON_EFFECT)
    end
end

-- Check if the Xyz monster is a SZS monster and uses only SZS materials
function s.xyzfilter(c)
    return c:IsSetCard(0x2406)
end

function s.efcon(e,tp,eg,ep,ev,re,r,rp)
    local ec=e:GetHandler():GetReasonCard()
    return ec:IsSetCard(0x2406) and ec:GetMaterial():IsExists(s.xyzfilter,ec:GetMaterial():GetCount(),nil) and r==REASON_XYZ
end

function s.efop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    
    -- Xyz Monster using this card cannot be destroyed by battle
    local e1=Effect.CreateEffect(rc)
    e1:SetDescription(3000)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT|RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
    
    -- Xyz Monster using this card cannot be destroyed by card effects
    local e2=Effect.CreateEffect(rc)
    e2:SetDescription(3001)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetValue(1)
    e2:SetReset(RESET_EVENT|RESETS_STANDARD)
    rc:RegisterEffect(e2,true)
end