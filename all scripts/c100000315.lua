--Puzzle HERO Jigsaw Jammer
local s,id=GetID()
if id==nil then id=100000315 end --Use the provided card ID
function s.initial_effect(c)
    --Special Summon 2 "Puzzle HERO Jigsaw Jammer" from hand or deck when Normal Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))  --ID for activation text
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    --Your opponent cannot target "HERO" monsters for attacks, except "Puzzle HERO Jigsaw Jammer"
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0,LOCATION_MZONE)
    e2:SetValue(s.atlimit)
    c:RegisterEffect(e2)
end

--Special Summon target function
function s.spfilter(c,e,tp)
    return c:IsCode(100000315) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>1 
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,2,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK)
end

--Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,2,2,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

--Attack limitation function
function s.atlimit(e,c)
    return c:IsFaceup() and c:IsSetCard(0x8) and not c:IsCode(100000315) -- 0x8 is "HERO" archetype
end