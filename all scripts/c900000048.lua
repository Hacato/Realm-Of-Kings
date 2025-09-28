-- Rage Of The Dovakin
-- Continuous Spell
-- scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- (1) Once per turn: discard 1, special summon 1 level 4 or lower "Dovakin" from hand or deck; banish it when it leaves the field.
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (2) Once per duel: If your "Dovakin" card leaves the field because of an opponent's card effect, you may Fusion Summon 1 "Dovakin" Fusion Monster using materials from hand/field/GY.
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_LEAVE_FIELD)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id+100) -- once per duel
    e2:SetCondition(s.fuscon)
    e2:SetTarget(s.fustg)
    e2:SetOperation(s.fusop)
    c:RegisterEffect(e2)
end

-- FILTERS & HELPERS
function s.dovfilter(c)
    return c:IsSetCard(0x2411)
end

-- (1) discard cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

-- (1) target
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2411) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return (Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
            or Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp))
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- (1) operation: special summon and set leave-field redirect to banish
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        -- banish when leaves field
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
        e1:SetValue(LOCATION_REMOVED)
        tc:RegisterEffect(e1,true)
    end
end

-- (2) condition: check if any "Dovakin" you controlled left the field because of opponent's card effect
function s.cfilter(c,tp)
    return c:IsSetCard(0x2411)
        and c:GetPreviousControler()==tp
        and c:IsPreviousLocation(LOCATION_ONFIELD)
        and bit.band(c:GetReason(),REASON_EFFECT)~=0
        and c:GetReasonPlayer() and c:GetReasonPlayer()~=tp
end

function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
    return eg and eg:IsExists(s.cfilter,1,nil,tp)
end

-- (2) Fusion target: check Extra Deck for a Dovakin Fusion that can be summoned
function s.fusfilter(c,e,tp)
    return c:IsSetCard(0x2411) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE,0,nil)
        return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
            and #mg>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
    local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
    if #sg==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local fc=sg:Select(tp,1,1,nil):GetFirst()
    if not fc then return end
    local mat=nil
    if fc.CheckFusionMaterial then
        if not fc:CheckFusionMaterial(mg,nil,tp) then
            Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,2) or "No valid fusion materials.")
            return
        end
        mat=fc:SelectFusionMaterial(tp,mg,nil,tp)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
        mat=mg:Select(tp,1,99,nil)
    end
    if not mat or #mat==0 then return end
    Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
    Duel.BreakEffect()
    if Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)~=0 then
        fc:CompleteProcedure()
    end
end