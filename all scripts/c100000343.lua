--Dark Eclipse Burning Rage Dragon
local s,id=GetID()
function s.initial_effect(c)
    --Pendulum Attributes
    Pendulum.AddProcedure(c)
    
    --Cannot Pendulum Summon non-DARK/LIGHT monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    c:RegisterEffect(e1)
    
    --Protection from destruction
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
    e2:SetRange(LOCATION_PZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.indtg)
    e2:SetValue(s.indval)
    e2:SetCountLimit(1)
    c:RegisterEffect(e2)
    
    --Place "Eclipse" Pendulum Monster in Pendulum Zone
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_PZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.pencon)
    e3:SetTarget(s.pentg)
    e3:SetOperation(s.penop)
    c:RegisterEffect(e3)
    
    --Must be Special Summoned by Tributing
    c:EnableReviveLimit()
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e4:SetCode(EFFECT_SPSUMMON_CONDITION)
    e4:SetValue(s.splimitmon)
    c:RegisterEffect(e4)
    
    --Special Summon procedure
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_SPSUMMON_PROC)
    e5:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e5:SetRange(LOCATION_HAND)
    e5:SetCondition(s.spcon)
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.spop)
    c:RegisterEffect(e5)
    
    --Deal effect damage equal to battle damage taken
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_BATTLE_DAMAGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.damcon)
    e6:SetOperation(s.damop)
    c:RegisterEffect(e6)
    
    --Place in Pendulum Zone if destroyed
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,2))
    e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e7:SetCode(EVENT_DESTROYED)
    e7:SetProperty(EFFECT_FLAG_DELAY)
    e7:SetCountLimit(1,{id,1})
    e7:SetCondition(s.pencon2)
    e7:SetTarget(s.pentg2)
    e7:SetOperation(s.penop2)
    c:RegisterEffect(e7)
end

--Pendulum Summon restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
    return not c:IsAttribute(ATTRIBUTE_DARK+ATTRIBUTE_LIGHT) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Target for protection
function s.indtg(e,c)
    return (c:IsAttribute(ATTRIBUTE_DARK) or c:IsAttribute(ATTRIBUTE_LIGHT)) and 
           (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_CYBERSE)) and 
           (c:IsType(TYPE_RITUAL) or c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or 
           c:IsType(TYPE_XYZ) or c:IsType(TYPE_PENDULUM) or c:IsType(TYPE_LINK) or c:IsType(TYPE_QUANTUM))
end

--Protection value (once per turn)
function s.indval(e,re,r,rp)
    if r&(REASON_BATTLE+REASON_EFFECT)~=0 then
        return 1
    end
    return 0
end

--Check if other pendulum zone is empty
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.GetFieldCard(tp,LOCATION_PZONE,1-e:GetHandler():GetSequence())
end

--Eclipse Pendulum Monster target
function s.penfilter(c)
    return c:IsSetCard(0x04B2) and c:IsType(TYPE_PENDULUM) and 
           (c:IsLocation(LOCATION_DECK) or (c:IsFaceup() and c:IsLocation(LOCATION_EXTRA))) and 
           not c:IsForbidden()
end

--Target for placing Eclipse monster
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil) end
end

--Operation for placing Eclipse monster
function s.penop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,1-e:GetHandler():GetSequence())
    if pc then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
    if #g>0 then
        Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
    end
end

--Special Summon condition
function s.splimitmon(e,se,sp,st)
    return st&SUMMON_TYPE_PENDULUM==SUMMON_TYPE_PENDULUM or e:GetHandler():GetLocation()~=LOCATION_HAND
end

--Tribute filter
function s.spfilter(c)
    return c:IsLevel(7) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON) and
           c:IsType(TYPE_PENDULUM) and c:IsReleasable()
end

--Special Summon condition
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and
           Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE,0,1,1,nil)
    if #g>0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end

--Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.Release(g,REASON_COST)
    g:DeleteGroup()
end

--Battle damage condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return ep==tp and (Duel.GetAttacker()==c or Duel.GetAttackTarget()==c)
end

--Battle damage operation
function s.damop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Damage(1-tp,ev,REASON_EFFECT)
end

--Check if destroyed in Monster Zone
function s.pencon2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFaceup()
end

--Target for placing self in Pendulum Zone
function s.pentg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end

--Operation for placing self in Pendulum Zone
function s.penop2(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
    end
end