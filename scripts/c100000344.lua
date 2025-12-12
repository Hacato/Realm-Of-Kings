--Dark Eclipse Pendant Dragon
local s,id=GetID()
function s.initial_effect(c)
    --Pendulum Attributes
    Pendulum.AddProcedure(c)
    
    --Cannot Pendulum Summon non-DARK monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    c:RegisterEffect(e1)
    
    --Place "Eclipse" Pendulum Monster in Pendulum Zone
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.pencon)
    e2:SetTarget(s.pentg)
    e2:SetOperation(s.penop)
    c:RegisterEffect(e2)
    
    --Special Summon restriction
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e3:SetCode(EFFECT_SPSUMMON_CONDITION)
    e3:SetValue(s.splimitmon)
    c:RegisterEffect(e3)
    
    --Special Summon procedure
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_SPSUMMON_PROC)
    e4:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e4:SetRange(LOCATION_HAND)
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
    
    --Halve battle damage
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e5:SetTargetRange(1,0)
    e5:SetCondition(s.damcon)
    e5:SetValue(HALF_DAMAGE)
    c:RegisterEffect(e5)
    
    --Gain ATK from battle damage
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_ATKCHANGE)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_BATTLE_DAMAGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1,{id,1})
    e6:SetCondition(s.atkcon)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
    
    --Effect when Special Summoned
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,3))
    e7:SetCategory(CATEGORY_TODECK)
    e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    e7:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e7:SetCountLimit(1,{id,2})
    e7:SetTarget(s.cptg)
    e7:SetOperation(s.cpop)
    c:RegisterEffect(e7)
    
    --Place in Pendulum Zone if destroyed or banished
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,4))
    e8:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e8:SetProperty(EFFECT_FLAG_DELAY)
    e8:SetCode(EVENT_DESTROYED)
    e8:SetCondition(s.pencon2)
    e8:SetTarget(s.pentg2)
    e8:SetOperation(s.penop2)
    c:RegisterEffect(e8)
    
    local e9=e8:Clone()
    e9:SetCode(EVENT_REMOVE)
    c:RegisterEffect(e9)
end

--Pendulum Summon restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
    return not c:IsAttribute(ATTRIBUTE_DARK) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
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
    return st&SUMMON_TYPE_PENDULUM==SUMMON_TYPE_PENDULUM
end

--Tribute filter for Special Summon
function s.spfilter(c)
    return c:IsSetCard(0x04B2) and c:IsReleasable() and 
           (c:IsType(TYPE_RITUAL) or c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or 
           c:IsType(TYPE_XYZ) or c:IsType(TYPE_LINK) or c:IsType(TYPE_PENDULUM))
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
function s.damcon(e)
    return Duel.GetAttacker()==e:GetHandler() or Duel.GetAttackTarget()==e:GetHandler()
end

--Gain ATK condition
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp
end

--Gain ATK operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFaceup() and c:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
        e1:SetValue(ev)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
        c:RegisterEffect(e1)
    end
end

--Target for copy effect
function s.cpfilter(c)
    return c:IsMonster()
end

--Target for copy effect
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.cpfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.cpfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.cpfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end

--Operation for copy effect
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) and c:IsFaceup() then
        if Duel.SendtoDeck(tc,nil,2,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
            --Copy name
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_CHANGE_CODE)
            e1:SetValue(tc:GetOriginalCode())
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            c:RegisterEffect(e1)
            
            --Copy effect
            local code=tc:GetOriginalCode()
            c:CopyEffect(code,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,1)
            
            --Become Tuner if applicable
            if tc:IsType(TYPE_TUNER) then
                local e3=Effect.CreateEffect(c)
                e3:SetType(EFFECT_TYPE_SINGLE)
                e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e3:SetCode(EFFECT_ADD_TYPE)
                e3:SetValue(TYPE_TUNER)
                e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                c:RegisterEffect(e3)
                
                local e4=Effect.CreateEffect(c)
                e4:SetType(EFFECT_TYPE_SINGLE)
                e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e4:SetCode(EFFECT_CHANGE_LEVEL)
                e4:SetValue(3)
                e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                c:RegisterEffect(e4)
            end
        end
    end
end

--Check if destroyed in Monster Zone
function s.pencon2(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end

--Target for placing self in Pendulum Zone
function s.pentg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        local pc=Duel.GetFieldCard(tp,LOCATION_PZONE,0) or Duel.GetFieldCard(tp,LOCATION_PZONE,1)
        return pc and (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1))
    end
    local g=Duel.GetFieldGroup(tp,LOCATION_PZONE,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

--Operation for placing self in Pendulum Zone
function s.penop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local g=Duel.GetFieldGroup(tp,LOCATION_PZONE,0)
    if #g==0 then return end
    if Duel.Destroy(g,REASON_EFFECT)~=0 then
        if Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) then
            Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        end
    end
end