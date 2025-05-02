--Galaxy Transmigration
--Continuous Trap Card
local s,id=GetID()
function s.initial_effect(c)
    --Activate by paying 800 LP
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.actcost)
    c:RegisterEffect(e1)
    
    --Can only control 1 face-up "Galaxy Transmigration"
    c:SetUniqueOnField(1,0,id)
    
    --Draw 1 card when you Xyz Summon a Dragon-Type Xyz Monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
    c:RegisterEffect(e3)
    
    --Special Summon 2 Level 8 Monsters and Xyz Summon when sent to GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_TO_GRAVE)
    e4:SetCountLimit(1,id)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

--Activation cost
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.PayLPCost(tp,800)
end

-- Unique card functionality is now handled by c:SetUniqueOnField

--Draw condition
function s.drfilter(c,tp)
    return c:IsSummonType(SUMMON_TYPE_XYZ) and c:IsType(TYPE_XYZ) and c:IsRace(RACE_DRAGON) 
        and c:IsSummonPlayer(tp) and c:IsFaceup()
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.drfilter,1,nil,tp)
end

--Draw target
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(1)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

--Draw operation
function s.drop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end

--Special Summon filter for Level 8 monsters
function s.spfilter(c,e,tp)
    return c:IsLevel(8) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Galaxy-Eyes filter for Xyz monsters
function s.xyzfilter(c,mg)
    return c:IsSetCard(0x107b) and c:IsType(TYPE_XYZ) and c:IsXyzSummonable(nil,mg,2,2)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
        return not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
            and g:GetClassCount(Card.GetCode)>=2
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

--Special Summon operation and Xyz Summon
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
    
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
    if g:GetClassCount(Card.GetCode)<2 then return end
    
    local sg=aux.SelectUnselectGroup(g,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_SPSUMMON)
    if #sg<2 then return end
    
    -- Special Summon the 2 Level 8 monsters
    local tc1=sg:GetFirst()
    local tc2=sg:GetNext()
    if Duel.SpecialSummonStep(tc1,0,tp,tp,false,false,POS_FACEUP) and
       Duel.SpecialSummonStep(tc2,0,tp,tp,false,false,POS_FACEUP) then
        Duel.SpecialSummonComplete()
        
        -- Xyz Summon
        local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,sg)
        if #xyzg>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
            Duel.XyzSummon(tp,xyz,nil,sg)
        end
    else
        Duel.SpecialSummonComplete()
    end
end