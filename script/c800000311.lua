--Crimson Kuriboh
--Card ID: 800000311
--Passive GY Synchro Test V5 + early banish (EVENT_SPSUMMON)

local s,id=GetID()

function s.initial_effect(c)
    --Discard to destroy Defense Position monsters
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_FIELD|EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_BATTLED)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.descon)
    e1:SetCost(s.descost)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)

    --Treat as Level 4 in the GY
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_SYNCHRO_LEVEL)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetValue(4)
    c:RegisterEffect(e2)

    --GY Synchro material permission
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_HAND_SYNCHRO)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetLabel(id)
    e3:SetValue(s.matval)
    e3:SetTarget(s.handtg)
    c:RegisterEffect(e3)

    --Expose the GY material to field monsters
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_HAND_SYNCHRO)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetLabel(id)
    e4:SetValue(s.matval)
    e4:SetTarget(s.fieldtg)
    c:RegisterEffect(e4)

    --Banish after a successful Synchro Summon
    --if this card was used as material (V5 fallback)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD|EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetRange(LOCATION_GRAVE)
    e5:SetCondition(s.rmcon)
    e5:SetOperation(s.rmop)
    c:RegisterEffect(e5)

    --NEW: banish as soon as the Synchro Summon is being performed,
    --before it can succeed (materials are already processed here)
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD|EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_SPSUMMON)
    e6:SetRange(LOCATION_GRAVE)
    e6:SetCondition(s.earlycon)
    e6:SetOperation(s.earlyop)
    c:RegisterEffect(e6)
end

--========================================
-- HAND EFFECT
--========================================

function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    return a~=nil and d~=nil
        and a:IsControler(tp)
        and d:IsControler(1-tp)
        and d:IsPosition(POS_DEFENSE)
end

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsDiscardable()
    end
    Duel.SendtoGrave(
        e:GetHandler(),
        REASON_COST|REASON_DISCARD)
end

function s.desfilter(c)
    return c:IsPosition(POS_DEFENSE)
        and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,0,LOCATION_MZONE,1,nil)
    end

    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,0,LOCATION_MZONE,nil)

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,0,LOCATION_MZONE,nil)

    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

--========================================
-- GY SYNCHRO MATERIAL
--========================================

function s.fieldtg(e,c)
    local tp=e:GetHandlerPlayer()

    return c:IsFaceup()
        and c:IsControler(tp)
        and Duel.GetFlagEffect(tp,id)==0
end

function s.matval(e,mc,sc)
    local c=e:GetHandler()
    local tp=c:GetOwner()

    return mc==c
        and mc:IsLocation(LOCATION_GRAVE)
        and mc:IsType(TYPE_TUNER)
        and mc:IsCanBeSynchroMaterial(sc)
        and Duel.GetFlagEffect(tp,id)==0
end

function s.handtg(e,sc,sg,mg,tg,tsg,ntsg)
    return true,
        Group.CreateGroup(),
        Group.CreateGroup()
end

--========================================
-- EARLY BANISH (EVENT_SPSUMMON)
--========================================

function s.earlyfilter(sc,mc)
    if not sc:IsType(TYPE_SYNCHRO) then
        return false
    end

    local mg=sc:GetMaterial()
    return mg and mg:IsContains(mc)
end

function s.earlycon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    return c:IsLocation(LOCATION_GRAVE)
        and eg:IsExists(s.earlyfilter,1,nil,c)
end

function s.earlyop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if not c:IsLocation(LOCATION_GRAVE) then
        return
    end

    if not eg:IsExists(s.earlyfilter,1,nil,c) then
        return
    end

    if Duel.Remove(
        c,POS_FACEUP,
        REASON_EFFECT)>0 then

        Duel.RegisterFlagEffect(
            tp,id,
            RESET_PHASE|PHASE_END,
            0,1)
    end
end

--========================================
-- BANISH AFTER SYNCHRO SUMMON (V5 FALLBACK)
--========================================

function s.rmfilter(sc,mc)
    if not sc:IsSummonType(SUMMON_TYPE_SYNCHRO) then
        return false
    end

    local mg=sc:GetMaterial()
    return mg and mg:IsContains(mc)
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    return c:IsLocation(LOCATION_GRAVE)
        and eg:IsExists(s.rmfilter,1,nil,c)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    if not c:IsLocation(LOCATION_GRAVE) then
        return
    end

    if not eg:IsExists(s.rmfilter,1,nil,c) then
        return
    end

    if Duel.Remove(
        c,POS_FACEUP,
        REASON_EFFECT)>0 then

        Duel.RegisterFlagEffect(
            tp,id,
            RESET_PHASE|PHASE_END,
            0,1)
    end
end