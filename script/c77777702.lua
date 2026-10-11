
--Seafarer Swindler Bonnie
local s,id=GetID()

function s.initial_effect(c)
    --Destroy 1 Spell/Trap you control;
    --Special Summon this card from the GY,
    --banish it when it leaves the field,
    --then optionally Set an opponent's Spell/Trap
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

--Destructible Spell/Trap you control
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Opponent's Spell/Trap in a regular S/T Zone
function s.stfilter(c)
    return c:IsSpellTrap()
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
            and Duel.IsExistingMatchingCard(
                s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD
    )
    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_GRAVE
    )
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    --Destroy 1 Spell/Trap you control
    if not Duel.IsExistingMatchingCard(
        s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end

    if Duel.Destroy(dg,REASON_EFFECT)==0 then return end

    --Special Summon Bonnie from the GY
    if not c:IsRelateToEffect(e)
        or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
        or not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
        return
    end

    Duel.BreakEffect()

    if Duel.SpecialSummon(
        c,0,tp,tp,false,false,POS_FACEUP
    )==0 then
        return
    end

    --Banish Bonnie when she leaves the field
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
    e1:SetValue(LOCATION_REMOVED)
    e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
    c:RegisterEffect(e1,true)

    --Optionally Set an opponent's Spell/Trap
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        s.stfilter,tp,0,LOCATION_SZONE,1,nil
    ) then
        return
    end

    if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(
        tp,s.stfilter,tp,0,LOCATION_SZONE,1,1,nil
    )
    local tc=g:GetFirst()
    if not tc then return end

    --Set the selected Spell/Trap on your field
    Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    )
end
