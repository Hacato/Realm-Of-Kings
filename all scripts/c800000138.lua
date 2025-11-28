-- SZS Synchrogazer
-- Scripted by morganhacato-cloud

local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_SPSUMMON)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- Opponent controls Fusion/Synchro/Xyz/Link
function s.condition(e,tp)
    return Duel.IsExistingMatchingCard(
        Auxiliary.FaceupFilter(Card.IsType,TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK),
        tp,0,LOCATION_MZONE,1,nil
    )
end

-- Level 4 SZS
function s.spfilter(c,e,tp)
    return c:IsLevel(4) and c:IsSetCard(0x2406) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- SZS Synchros that can be summoned
function s.synfilter(c,mg)
    return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x2406) and c:IsSynchroSummonable(nil,mg)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
        if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then return false end

        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND,0,nil,e,tp)
        local field=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)

        for tc in g:Iter() do
            local mg=field:Clone()
            mg:AddCard(tc)
            if Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,mg) then
                return true
            end
        end
        return false
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.activate(e,tp)
    local c=e:GetHandler()

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    -- Special Summon Level 4 SZS
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
    if not sc or Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

    Duel.BreakEffect()

    -- Attempt Synchro
    local field=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    if not field:IsContains(sc) then field:AddCard(sc) end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,field)
    local syn=sg:GetFirst()
    if not syn then return end

    Duel.SynchroSummon(tp,syn,nil,field)

    -------------------------------------------------------------------------
    -- Hand monsters can be used as Synchro Material for SZS Synchros this turn
    -------------------------------------------------------------------------
    -- Grant hand synchro ability to all SZS Synchros in Extra Deck
    local ge1=Effect.CreateEffect(c)
    ge1:SetDescription(aux.Stringid(id,1))
    ge1:SetType(EFFECT_TYPE_FIELD)
    ge1:SetCode(EFFECT_SPSUMMON_PROC_G)
    ge1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
    ge1:SetRange(LOCATION_EXTRA)
    ge1:SetCondition(s.syncon)
    ge1:SetOperation(s.synop)
    ge1:SetValue(SUMMON_TYPE_SYNCHRO)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
    e1:SetTargetRange(LOCATION_EXTRA,0)
    e1:SetTarget(s.grtg)
    e1:SetLabelObject(ge1)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    -------------------------------------------------------------------------
    -- ATK Boost for SZS Synchros summoned this turn
    -------------------------------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetReset(RESET_PHASE+PHASE_END)
    e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return eg:IsExists(function(tc,tp)
            return tc:IsControler(tp) and tc:IsSummonType(SUMMON_TYPE_SYNCHRO) 
                and tc:IsSetCard(0x2406) and tc:IsType(TYPE_SYNCHRO)
        end,1,nil,tp)
    end)
    e2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
        local g=eg:Filter(function(tc,tp)
            return tc:IsControler(tp) and tc:IsSummonType(SUMMON_TYPE_SYNCHRO)
                and tc:IsSetCard(0x2406) and tc:IsType(TYPE_SYNCHRO) and tc:IsFaceup()
        end,nil,tp)
        local ct=Duel.GetMatchingGroupCount(function(c)
            return c:IsFaceup() and c:IsSetCard(0x2406) and c:IsType(TYPE_SYNCHRO)
        end,tp,LOCATION_MZONE,0,nil)
        for tc in g:Iter() do
            local e3=Effect.CreateEffect(e:GetHandler())
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_UPDATE_ATTACK)
            e3:SetValue(500*ct)
            e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e3)
        end
    end)
    Duel.RegisterEffect(e2,tp)

    -------------------------------------------------------------------------
    -- Opponent's turn: SZS Synchros are unaffected by targeting effects
    -------------------------------------------------------------------------
    if Duel.GetTurnPlayer()~=tp then
        local e4=Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e4:SetCode(EVENT_SPSUMMON_SUCCESS)
        e4:SetReset(RESET_PHASE+PHASE_END)
        e4:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
            return eg:IsExists(function(tc,tp)
                return tc:IsControler(tp) and tc:IsSummonType(SUMMON_TYPE_SYNCHRO)
                    and tc:IsSetCard(0x2406) and tc:IsType(TYPE_SYNCHRO)
            end,1,nil,tp)
        end)
        e4:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
            local g=eg:Filter(function(tc,tp)
                return tc:IsControler(tp) and tc:IsSummonType(SUMMON_TYPE_SYNCHRO)
                    and tc:IsSetCard(0x2406) and tc:IsType(TYPE_SYNCHRO) and tc:IsFaceup()
            end,nil,tp)
            for tc in g:Iter() do
                local e5=Effect.CreateEffect(e:GetHandler())
                e5:SetType(EFFECT_TYPE_SINGLE)
                e5:SetCode(EFFECT_IMMUNE_EFFECT)
                e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
                e5:SetRange(LOCATION_MZONE)
                e5:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                e5:SetValue(s.efilter)
                e5:SetOwnerPlayer(tp)
                tc:RegisterEffect(e5)
            end
        end)
        Duel.RegisterEffect(e4,tp)
    end
end

-- Grant target for SZS Synchros
function s.grtg(e,c)
    return c:IsSetCard(0x2406) and c:IsType(TYPE_SYNCHRO)
end

-- Hand Synchro condition
function s.syncon(e,c,mg)
    if c==nil then return true end
    if c:IsType(TYPE_PENDULUM) and c:IsFaceup() then return false end
    local tp=c:GetControler()
    local allmat=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_MZONE,0,nil,c)
    local handmat=Duel.GetMatchingGroup(function(hc,c)
        return hc:IsSetCard(0x2406) and hc:IsCanBeSynchroMaterial(c)
    end,tp,LOCATION_HAND,0,nil,c)
    allmat:Merge(handmat)
    if mg then
        allmat=allmat:Filter(Card.IsHasEffect,nil,73941492)
    end
    return c:IsSynchroSummonable(nil,allmat)
end

-- Hand Synchro operation  
function s.synop(e,tp,eg,ep,ev,re,r,rp,c,sg,mg)
    local allmat=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_MZONE,0,nil,c)
    local handmat=Duel.GetMatchingGroup(function(hc,c)
        return hc:IsSetCard(0x2406) and hc:IsCanBeSynchroMaterial(c)
    end,tp,LOCATION_HAND,0,nil,c)
    allmat:Merge(handmat)
    -- Use the built-in Synchro summon with material group
    Duel.SynchroSummon(tp,c,nil,allmat)
end

-- Immunity filter for targeting effects
function s.efilter(e,te)
    if not te then return false end
    local tc=e:GetHandler()
    local tp=e:GetOwnerPlayer()
    if te:GetOwnerPlayer()==tp then return false end
    if not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    return g and g:IsContains(tc)
end