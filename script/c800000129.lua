--SZS Ame no Habakiri - Tsubasa
local s,id=GetID()
function s.initial_effect(c)
    --E1: Special Summon from hand if you control another "SZS"
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon1)
    e1:SetCountLimit(1,id)
    c:RegisterEffect(e1)

    --E2: Special Summon instead of being sent from hand to GY, then draw 1
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_SEND_REPLACE)
    e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e2:SetTarget(s.reptg)
    e2:SetOperation(s.repop)
    e2:SetCountLimit(1,{id,1})
    c:RegisterEffect(e2)

    --E3: If destroyed a monster by battle → destroy 1 card, then discard 1
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_DESTROY+CATEGORY_HANDES)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_BATTLE_DESTROYING)
    e3:SetCondition(aux.bdcon)
    e3:SetTarget(s.destg)
    e3:SetOperation(s.desop)
    c:RegisterEffect(e3)

    --E4: Quick Synchro/Xyz on opponent's turn if SS’d last turn
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetHintTiming(TIMING_BATTLE_PHASE+TIMING_MAIN_END,TIMING_BATTLE_PHASE+TIMING_MAIN_END)
    e4:SetCondition(s.scxyzcon)
    e4:SetTarget(s.scxyztg)
    e4:SetOperation(s.scxyzop)
    e4:SetCountLimit(1,{id,2})
    c:RegisterEffect(e4)

    --E5: Register Special Summon (for last-turn SS check)
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_SPSUMMON_SUCCESS)
    e5:SetOperation(s.regop)
    c:RegisterEffect(e5)
end
s.listed_series={0x2406}

-----------------------------------------
-- E1: Special Summon if you control another SZS
-----------------------------------------
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x2406)
end
function s.spcon1(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,c)
end

-----------------------------------------
-- E2: Replacement Effect (from hand → summon instead)
-----------------------------------------
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsLocation(LOCATION_HAND) and c:GetDestination()==LOCATION_GRAVE
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    return Duel.SelectYesNo(tp,aux.Stringid(id,1))
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end

-----------------------------------------
-- E3: Battle destroy → destroy 1 → discard 1
-----------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,1,nil)
    if #g>0 and Duel.Destroy(g,REASON_EFFECT)>0 then
        Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
    end
end

-----------------------------------------
-- E5: Track if Special Summoned on your turn
-----------------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetTurnPlayer()==tp then
        e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
    end
end

-----------------------------------------
-- E4: Quick Synchro/Xyz (same template as Gungnir)
-----------------------------------------
function s.scxyzcon(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return e:GetHandler():GetFlagEffect(id)>0 and Duel.GetTurnPlayer()==1-tp
        and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE)
end
function s.szsfilter(c)
    return c:IsSetCard(0x2406)
end
function s.scxyztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
        local g=Duel.GetMatchingGroup(s.szsfilter,tp,LOCATION_EXTRA,0,nil)
        if g:IsExists(Card.IsSynchroSummonable,1,nil,nil,mg) then return true end
        if g:IsExists(Card.IsXyzSummonable,1,nil,mg) then return true end
        return false
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scxyzop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsControler(1-tp) then return end
    local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    local g=Duel.GetMatchingGroup(s.szsfilter,tp,LOCATION_EXTRA,0,nil)
    local sg1=g:Filter(Card.IsSynchroSummonable,nil,nil,mg)
    local sg2=g:Filter(Card.IsXyzSummonable,nil,mg)
    sg1:Merge(sg2)
    if #sg1>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tc=sg1:Select(tp,1,1,nil):GetFirst()
        if tc:IsSynchroSummonable(nil,mg) 
            and (not tc:IsXyzSummonable(mg) or Duel.SelectYesNo(tp,aux.Stringid(id,4)))
        then
            Duel.SynchroSummon(tp,tc,nil,mg)
        else
            Duel.XyzSummon(tp,tc,mg)
        end
    end
end
