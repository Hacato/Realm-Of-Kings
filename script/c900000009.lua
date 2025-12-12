--Slayers Insignia
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --This card is always treated as a "Slayer" card
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_SETCODE)
    e1:SetRange(LOCATION_SZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
    e1:SetValue(0x2407)
    c:RegisterEffect(e1)
    
    --Special summon any 1 monster from deck ignoring summoning conditions
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetTarget(s.target)
    e2:SetOperation(s.activate)
    c:RegisterEffect(e2)
end

--Special summon filter
function s.filter(c,e,tp)
    return c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

--Target function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

--Activation function
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc then
        if Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)~=0 then
            tc:CompleteProcedure()
        end
        Duel.ShuffleDeck(tp)
    end
end