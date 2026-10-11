
--Seafarer Vixen Alexandria
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Special Summon 1 "Seafarer" monster from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Take 1 opponent's face-down Spell/Trap and Set it
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

--Special Summon from hand
function s.spfilter(c,e,tp)
    return c:IsSetCard(SET_SEAFARER)
        and c:IsMonster()
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp
            )
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp
    )
    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
        --Send the summoned monster to the GY during this turn's End Phase
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(aux.Stringid(id,0))
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetCountLimit(1)
        e1:SetCondition(s.gycon)
        e1:SetOperation(s.gyop)
        e1:SetReset(RESET_PHASE+PHASE_END)
        e1:SetLabelObject(tc)
        Duel.RegisterEffect(e1,tp)
    end
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    return tc and tc:IsFaceup() and tc:IsLocation(LOCATION_MZONE)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_MZONE) then
        Duel.SendtoGrave(tc,REASON_EFFECT)
    end
end

--Steal an opponent's face-down Spell/Trap
function s.setfilter(c)
    return c:IsFacedown()
        and c:IsSpellTrap()
        and c:IsLocation(LOCATION_SZONE)
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(1-tp) and s.setfilter(chkc)
    end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingTarget(
                s.setfilter,tp,0,LOCATION_SZONE,1,nil
            )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
    local g=Duel.SelectTarget(
        tp,s.setfilter,tp,0,LOCATION_SZONE,1,1,nil
    )
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e)
        or not tc:IsFacedown()
        or not tc:IsLocation(LOCATION_SZONE)
        or not tc:IsControler(1-tp)
        or not tc:IsAbleToChangeControler()
        or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    --Move the opponent's card to your Spell/Trap Zone face-down
    if Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    ) then
        Duel.ConfirmCards(1-tp,tc)
    end
end
