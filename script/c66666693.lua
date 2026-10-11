
--Seafarer Steward Jack
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Special Summon this card from hand if you control a WATER monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    --Destroy 1 Spell/Trap, then Special Summon a non-Tuner Seafarer
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--Check for a face-up WATER monster
function s.waterfilter(c)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_WATER)
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.waterfilter,tp,LOCATION_MZONE,0,1,nil
        )
end

--Spell/Trap you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Non-Tuner Seafarer monster in Deck
function s.deckfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and not c:IsType(TYPE_TUNER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
            )
            and Duel.IsExistingMatchingCard(
                s.deckfilter,tp,LOCATION_DECK,0,1,nil,e,tp
            )
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

--Only Seafarer monsters can be Special Summoned
function s.splimit(e,c)
    return not c:IsSetCard(SET_SEAFARER)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    --Destroy a Spell/Trap you control
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end

    local destroyed=Duel.Destroy(dg,REASON_EFFECT)

    --Apply the Seafarer-only restriction for the rest of the turn
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    if destroyed==0 then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    Duel.BreakEffect()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.deckfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp
    )
    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummonStep(
        tc,0,tp,tp,false,false,POS_FACEUP
    ) then
        --Negate the summoned monster's effects
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2,true)

        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_DISABLE_EFFECT)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e3,true)

        Duel.SpecialSummonComplete()

        --Destroy the summoned monster during this turn's End Phase
        local e4=Effect.CreateEffect(e:GetHandler())
        e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e4:SetCode(EVENT_PHASE+PHASE_END)
        e4:SetCountLimit(1)
        e4:SetLabelObject(tc)
        e4:SetOperation(s.desop)
        e4:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e4,tp)
    end
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_MZONE)
        and tc:IsDestructable() then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end
