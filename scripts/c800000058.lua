-- Shiranui Spirit Sword
local s,id=GetID()
function s.initial_effect(c)
    -- Special Summon from hand + Token
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- If sent to GY as Synchro Material: banish 1 Zombie from Deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetCondition(s.rmcon)
    e2:SetTarget(s.rmtg)
    e2:SetOperation(s.rmop)
    c:RegisterEffect(e2)

    -- If banished: Set or place a "Shiranui" S/T
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_REMOVE)
    e3:SetCountLimit(1,id+2)
    e3:SetTarget(s.sttg)
    e3:SetOperation(s.stop)
    c:RegisterEffect(e3)
end

-- cost: discard 1 other Shiranui or Zombie
function s.cfilter(c)
    return (c:IsSetCard(0xd9) or c:IsRace(RACE_ZOMBIE)) and c:IsDiscardable()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,1,e:GetHandler())
    Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

-- target for self + optional token
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
            and Duel.IsPlayerCanSpecialSummonMonster(tp,800000059,0,TYPES_TOKEN,0,0,4,RACE_ZOMBIE,ATTRIBUTE_FIRE)
            and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            local token=Duel.CreateToken(tp,800000059)
            Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

-- condition: if used as Synchro Material
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_SYNCHRO)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_DECK,0,1,nil,RACE_ZOMBIE) end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,Card.IsRace,tp,LOCATION_DECK,0,1,1,nil,RACE_ZOMBIE)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    end
end

-- if banished: set or place "Shiranui" S/T
function s.stfilter(c,tp)
    return c:IsSetCard(0xd9) and c:IsType(TYPE_SPELL+TYPE_TRAP) 
        and (c:IsSSetable() 
        or (Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,40005099),tp,LOCATION_FZONE+LOCATION_SZONE,0,1,nil) 
            and c:IsType(TYPE_CONTINUOUS) 
            and Duel.GetLocationCount(tp,LOCATION_SZONE)>0))
end
function s.sttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_DECK,0,1,nil,tp) end
end
function s.stop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_DECK,0,1,1,nil,tp)
    local tc=g:GetFirst()
    if tc then
        if tc:IsType(TYPE_CONTINUOUS) 
            and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,40005099),tp,LOCATION_FZONE+LOCATION_SZONE,0,1,nil) 
            and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
            Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
        else
            Duel.SSet(tp,tc)
        end
    end
end
