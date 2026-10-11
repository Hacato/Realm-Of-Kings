
--Seafarers Sail Again
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Activate: Special Summon 1 "Seafarer"
    --monster from your Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,0})
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --If this face-down card is destroyed
    --and sent to the GY:
    --Special Summon 1 "Seafarer" from Deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--Seafarer monster that can be Special Summoned
function s.spfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Card must have been destroyed face-down
--from your field and sent to the GY
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_DESTROY)
        and c:IsPreviousLocation(LOCATION_ONFIELD)
        and c:IsPreviousPosition(POS_FACEDOWN)
        and c:GetPreviousControler()==tp
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK
    )
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp
    )

    if #g>0 then
        Duel.SpecialSummon(
            g,0,tp,tp,false,false,POS_FACEUP
        )
    end
end
