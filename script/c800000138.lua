-- SZS Synchrogazer
-- Scripted by MorganHacato-Cloud (merged with old immunity logic)

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
    return Duel.IsExistingMatchingCard(Auxiliary.FaceupFilter(Card.IsType,TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK),tp,0,LOCATION_MZONE,1,nil)
end

-- Level 4 SZS in hand
function s.spfilter(c,e,tp)
    return c:IsLevel(4) and c:IsSetCard(0x2406) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- SZS Synchros in Extra Deck
function s.synfilter(c,mg)
    return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x2406)
end

-- Check if field has materials for Synchro (helper for target check)
function s.fieldMatCheck(tp,handMonster)
    local field=Duel.GetMatchingGroup(function(c) 
        return c:IsFaceup() and c:IsLevel(4) and c:IsSetCard(0x2406) and c:IsAbleToGrave()
    end,tp,LOCATION_MZONE,0,nil)
    
    -- Calculate total levels on field
    local fieldLevels=field:GetSum(Card.GetLevel)
    
    -- Check each possible Synchro target in Extra Deck
    local exg=Duel.GetMatchingGroup(s.synfilter,tp,LOCATION_EXTRA,0,nil)
    for sc in exg:Iter() do
        local targetLevel=sc:GetLevel()
        local handLevel=handMonster:GetLevel()
        local neededFromField=targetLevel-handLevel
        
        -- Check if we have at least half the required levels already on field
        if neededFromField>0 and fieldLevels>=neededFromField then
            -- Verify we can actually make the exact level
            local tempField=field:Clone()
            tempField:AddCard(handMonster)
            if tempField:CheckWithSumEqual(Card.GetLevel,targetLevel,1,tempField:GetCount()) then
                return true
            end
        end
    end
    return false
end

-- Target check
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
        if not Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then return false end
        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND,0,nil,e,tp)
        -- Check if field already has enough materials (at least half the requirement)
        for tc in g:Iter() do
            if s.fieldMatCheck(tp,tc) then
                return true
            end
        end
        return false
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

-- Hand/field Level 4 SZS for fake Synchro
function s.handfield_material(c)
    return c:IsLevel(4) and c:IsSetCard(0x2406) and c:IsAbleToGrave()
end

-- Synchro procedure condition
function s.syncon(e,c,mg)
    if c==nil then return true end
    local tp=c:GetControler()
    local matGroup=Duel.GetMatchingGroup(s.handfield_material,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
    return matGroup:CheckWithSumEqual(Card.GetLevel,c:GetLevel(),1,matGroup:GetCount())
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

-- Synchro procedure operation
function s.synop(e,tp,eg,ep,ev,re,r,rp,c,sg,mg)
    local matGroup=Duel.GetMatchingGroup(s.handfield_material,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local sel=matGroup:SelectWithSumEqual(tp,Card.GetLevel,c:GetLevel(),1,matGroup:GetCount())
    if #sel>0 then
        Duel.SendtoGrave(sel,REASON_EFFECT+REASON_MATERIAL)
        Duel.SpecialSummon(c,SUMMON_TYPE_SPECIAL+SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
        c:CompleteProcedure()
    end
end

-- Grant hand Synchro effect
function s.grtg(e,c)
    return c:IsSetCard(0x2406) and c:IsType(TYPE_SYNCHRO)
end

-- Immunity filter for targeting effects
function s.efilter(e,te)
    if not te then return false end
    local tc=e:GetHandler()
    local tp=e:GetHandlerPlayer()
    if te:GetOwnerPlayer()==tp then return false end
    if not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    return g and g:IsContains(tc)
end

-- Apply immunity to a summoned SZS Synchro
function s.apply_immunity(tc,c)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_IMMUNE_EFFECT)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    e5:SetValue(s.efilter)
    tc:RegisterEffect(e5)
end

-- Activate effect
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    -- Check if activated during opponent's turn
    local opp_turn=Duel.GetTurnPlayer()~=tp

    -- Special Summon Level 4 SZS from hand
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
    if not sc or Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

    Duel.BreakEffect()

    -- Synchro Summon one Extra Deck SZS using field materials only (must include summoned monster)
    local field=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    if not field:IsContains(sc) then field:AddCard(sc) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,field)
    local syn=sg:GetFirst()
    if syn then
        -- Use only field materials (must include the summoned monster)
        local fieldMats=field:Filter(function(c) return c:IsLevel(4) and c:IsSetCard(0x2406) and c:IsAbleToGrave() end,nil)
        if fieldMats:CheckWithSumEqual(Card.GetLevel,syn:GetLevel(),1,fieldMats:GetCount()) and fieldMats:IsContains(sc) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local sel=fieldMats:SelectWithSumEqual(tp,Card.GetLevel,syn:GetLevel(),1,fieldMats:GetCount())
            -- Ensure the summoned monster is included
            if sel:IsContains(sc) then
                Duel.SendtoGrave(sel,REASON_EFFECT+REASON_MATERIAL)
                if Duel.SpecialSummon(syn,SUMMON_TYPE_SPECIAL+SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
                    syn:CompleteProcedure()
                    -- Apply immunity immediately if on opponent's turn
                    if opp_turn and syn:IsFaceup() and syn:IsLocation(LOCATION_MZONE) then
                        s.apply_immunity(syn,c)
                    end
                end
            end
        end
    end

    -- Grant lingering hand Synchro effect for the rest of the turn
    local ge=Effect.CreateEffect(c)
    ge:SetDescription(aux.Stringid(id,0))
    ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
    ge:SetTargetRange(LOCATION_EXTRA,0)
    ge:SetTarget(s.grtg)

    local se=Effect.CreateEffect(c)
    se:SetDescription(aux.Stringid(id,0))
    se:SetType(EFFECT_TYPE_FIELD)
    se:SetCode(EFFECT_SPSUMMON_PROC_G)
    se:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
    se:SetRange(LOCATION_EXTRA)
    se:SetCondition(s.syncon)
    se:SetOperation(s.synop)
    se:SetValue(SUMMON_TYPE_SYNCHRO)
    ge:SetLabelObject(se)
    ge:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(ge,tp)

    -- ATK boost for SZS Synchros summoned this turn
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetReset(RESET_PHASE+PHASE_END)
    e2:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return eg:IsExists(function(tc,tp)
            return tc:IsControler(tp) and tc:IsType(TYPE_SYNCHRO) and tc:IsSetCard(0x2406)
        end,1,nil,tp)
    end)
    e2:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
        local g=eg:Filter(function(tc,tp)
            return tc:IsControler(tp) and tc:IsType(TYPE_SYNCHRO) and tc:IsSetCard(0x2406) and tc:IsFaceup()
        end,nil,tp)
        local ct=Duel.GetMatchingGroupCount(function(c)
            return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x2406)
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

    -- Opponent's turn: SZS Synchros unaffected by targeting (for future summons)
    if opp_turn then
        local e4=Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e4:SetCode(EVENT_SPSUMMON_SUCCESS)
        e4:SetReset(RESET_PHASE+PHASE_END)
        e4:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
            return eg:IsExists(function(tc,tp)
                return tc:IsControler(tp) and tc:IsType(TYPE_SYNCHRO) and tc:IsSetCard(0x2406)
            end,1,nil,tp)
        end)
        e4:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
            local g=eg:Filter(function(tc,tp)
                return tc:IsControler(tp) and tc:IsType(TYPE_SYNCHRO) and tc:IsSetCard(0x2406) and tc:IsFaceup()
            end,nil,tp)
            for tc in g:Iter() do
                s.apply_immunity(tc,e:GetHandler())
            end
        end)
        Duel.RegisterEffect(e4,tp)
    end
end