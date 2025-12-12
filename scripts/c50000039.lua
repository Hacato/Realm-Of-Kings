local s,id=GetID()
function s.initial_effect(c)
    -- Activate: Special Summon Wonderbolt Token, then Synchro Summon using your monsters
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    -- GY Quick Effect: Prevent direct attacks
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(0,TIMING_ATTACK)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1000)
    e2:SetCondition(s.grcondition)
    e2:SetCost(aux.bfgcost)
    e2:SetOperation(s.groperation)
    c:RegisterEffect(e2)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local canToken = Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and Duel.IsPlayerCanSpecialSummonMonster(tp,50000040,0,0x4011,0,0,1,RACE_THUNDER,ATTRIBUTE_WIND)
    if chk==0 then return canToken end
    local lv=1
    if Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=5 then
        lv=Duel.AnnounceLevel(tp,1,8,nil)
    end
    Duel.SetTargetParam(lv)
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lv=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
        or not Duel.IsPlayerCanSpecialSummonMonster(tp,50000040,0,0x4011,0,0,lv,RACE_THUNDER,ATTRIBUTE_WIND) then return end
    -- Special Summon Wonderbolt Token
    local token=Duel.CreateToken(tp,50000040)
    Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
    -- Make token a Tuner (if not already defined in its script)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_ADD_TYPE)
    e0:SetValue(TYPE_TUNER)
    e0:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e0)
    -- Change level if declared
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CHANGE_LEVEL)
    e2:SetValue(lv)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
    token:RegisterEffect(e2)
    -- Special Summon restriction (while controlling Wonderbolt Token)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    token:RegisterEffect(e1)
    -- Synchro Summon using monsters you control (optional)
    local allmg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,allmg) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,allmg)
        if #g>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=g:Select(tp,1,1,nil)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
            local tg=allmg:FilterSelect(tp,s.cfilter,1,99,nil,sg:GetFirst())
            Duel.SynchroSummon(tp,sg:GetFirst(),tg)
        end
    end
end

function s.splimit(e,c)
    return not c:IsSetCard(0x701) -- Only "Harmony" monsters can be Special Summoned
end

function s.cfilter(c,syn)
    return syn:IsSynchroSummonable(c)
end
function s.spfilter(c,mg)
    return mg:IsExists(s.cfilter,1,nil,c)
end

-- Graveyard Quick Effect: No monsters on field, opponent's turn, can banish to block direct attacks
function s.grcondition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 
        and Duel.GetTurnPlayer()~=tp 
        and (Duel.IsAbleToEnterBP() or (Duel.GetCurrentPhase()>=PHASE_BATTLE_START and Duel.GetCurrentPhase()<=PHASE_BATTLE))
end

function s.groperation(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_DIRECT_ATTACK)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end