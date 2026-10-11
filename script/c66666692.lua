
--Seafarer Lookout Barbarossa
local s,id=GetID()

function s.initial_effect(c)
    --Destroy 1 Spell/Trap, Special Summon this card,
    --then optionally Set an opponent's Spell/Trap
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_CONTROL)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
end

--Spell/Trap cards you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Opponent's Spell/Trap cards that can be taken
function s.setfilter(c)
    return c:IsSpellTrap()
        and c:IsLocation(LOCATION_SZONE)
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
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    --Destroy 1 Spell/Trap you control
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end

    if Duel.Destroy(dg,REASON_EFFECT)==0 then return end

    --Special Summon Barbarossa from hand
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if not c:IsRelateToEffect(e) then return end

    Duel.BreakEffect()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then
        return
    end

    --Optionally take an opponent's Spell/Trap
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    if not Duel.IsExistingMatchingCard(
        s.setfilter,tp,0,LOCATION_SZONE,1,nil
    ) then return end

    if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
    local g=Duel.SelectMatchingCard(
        tp,s.setfilter,tp,0,LOCATION_SZONE,1,1,nil
    )
    local tc=g:GetFirst()
    if not tc then return end

    --Move the selected Spell/Trap to your field face-down
    if Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    ) then
        Duel.ConfirmCards(1-tp,tc)
    end
end
