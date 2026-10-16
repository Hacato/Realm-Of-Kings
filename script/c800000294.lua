
-- Mekk-Knight Blue Star
-- Replace YOUR_CARD_ID with the card's database ID.
local s,id=GetID()
function s.initial_effect(c)
    -- Special Summon from hand
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.spcon)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- Tribute this card to Special Summon a Mekk-Knight
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop2)
    c:RegisterEffect(e2)
end

s.listed_series={0x10c}
s.listed_names={84754430}

-- Mekk-Knight Avram
local AVRAM=84754430
local MEKK_KNIGHT=0x10c

-- Hand Special Summon procedure
function s.banfilter(c)
    return c:IsSetCard(MEKK_KNIGHT)
        and not c:IsLevel(4)
        and c:IsAbleToRemoveAsCost()
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.banfilter,tp,LOCATION_GRAVE,0,1,nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(
        tp,s.banfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_COST)
    end
end

-- Tribute cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsReleasable()
    end
    Duel.Release(e:GetHandler(),REASON_COST)
end

-- Special Summon target filter
function s.spfilter(c,e,tp)
    return c:IsSetCard(MEKK_KNIGHT)
        and not c:IsCode(id)
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
        and (not c:IsLocation(LOCATION_REMOVED)
            or c:IsFaceup())
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,
                LOCATION_HAND+LOCATION_DECK+
                LOCATION_GRAVE+LOCATION_REMOVED,
                0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,
        LOCATION_HAND+LOCATION_DECK+
        LOCATION_GRAVE+LOCATION_REMOVED)
end

-- Special Summon and double Avram's ATK
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,
        LOCATION_HAND+LOCATION_DECK+
        LOCATION_GRAVE+LOCATION_REMOVED,
        0,1,1,nil,e,tp)

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummon(
        tc,0,tp,tp,false,false,POS_FACEUP)==0 then
        return
    end

    -- Double Mekk-Knight Avram's ATK
    if tc:IsCode(AVRAM) and tc:IsFaceup() then
        local atk=tc:GetAttack()
        if atk<0 then return end

        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_ATTACK_FINAL)
        e1:SetValue(atk*2)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end
