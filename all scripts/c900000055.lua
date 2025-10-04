-- Ritual Of the Dovakin
local s,id=GetID()

function s.initial_effect(c)
    -- Activate to Ritual Summon
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x2411}

-- Filter: Dovakin Ritual Monsters
function s.ritualfilter(c,e,tp)
    return c:IsSetCard(0x2411) and c:IsType(TYPE_RITUAL) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

-- Filter: Extra Deck monsters as tribute
function s.matfilter(c)
    return c:IsLocation(LOCATION_EXTRA) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

-- Calculate total level of group
function s.total_level(g)
    local sum=0
    for tc in aux.Next(g) do
        sum = sum + tc:GetLevel()
    end
    return sum
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_EXTRA,0,nil)
        return Duel.IsExistingMatchingCard(s.ritualfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
            and #mg>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.ritualfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
    if not tc then return end

    local lv=tc:GetLevel()
    local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_EXTRA,0,nil)
    if #mg==0 then return end

    local g=Group.CreateGroup()
    local total=0

    -- Player selects monsters one by one until enough levels
    while total<lv do
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sg=mg:Select(tp,1,1,nil)
        if not sg or #sg==0 then return end
        g:Merge(sg)
        total = total + sg:GetFirst():GetLevel()
        mg:Sub(sg) -- remove from remaining options
        if total >= lv then break end -- enough levels, exit loop
        if #mg==0 then
            Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,0) or "Not enough tribute materials")
            return
        end
    end

    Duel.HintSelection(g)
    Duel.SendtoGrave(g,REASON_COST+REASON_MATERIAL+REASON_RITUAL)
    Duel.BreakEffect()
    Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
    tc:CompleteProcedure()
end
