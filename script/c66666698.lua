
--Seafarer's Lost Wreckage
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Activate: Choose 1 of 2 effects
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_CONTROL+CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--Face-up Seafarer monsters
function s.cfilter(c)
    return c:IsFaceup()
        and c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
end

--Must control at least 2 Seafarer monsters
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(
        s.cfilter,tp,LOCATION_MZONE,0,2,nil
    )
end

--Opponent's Spell/Trap in their S/T Zone
function s.fieldfilter(c)
    return c:IsSpellTrap()
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

--Opponent's Spell/Trap in their GY
function s.gyfilter(c)
    return c:IsSpellTrap()
        and c:IsSSetable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(1-tp)
            and (
                (chkc:IsLocation(LOCATION_SZONE)
                    and s.fieldfilter(chkc))
                or
                (chkc:IsLocation(LOCATION_GRAVE)
                    and s.gyfilter(chkc))
            )
    end

    local b1=Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingTarget(
            s.fieldfilter,tp,0,LOCATION_SZONE,1,nil
        )

    local b2=Duel.GetLocationCount(tp,LOCATION_SZONE)>0
        and Duel.IsExistingTarget(
            s.gyfilter,tp,0,LOCATION_GRAVE,1,nil
        )

    if chk==0 then
        return b1 or b2
    end

    --Choose which effect to activate
    local op
    if b1 and b2 then
        op=Duel.SelectOption(tp,
            aux.Stringid(id,1),
            aux.Stringid(id,2))
    elseif b1 then
        op=0
    else
        op=1
    end

    e:SetLabel(op)

    if op==0 then
        --Target opponent's field Spell/Trap
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectTarget(
            tp,s.fieldfilter,tp,0,LOCATION_SZONE,1,1,nil
        )
        Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
    else
        --Target opponent's GY Spell/Trap
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectTarget(
            tp,s.gyfilter,tp,0,LOCATION_GRAVE,1,1,nil
        )
        Duel.SetOperationInfo(
            0,CATEGORY_LEAVE_GRAVE,g,1,1-tp,LOCATION_GRAVE
        )
    end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end

    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    if e:GetLabel()==0 then
        --Set a Spell/Trap from opponent's field
        if not tc:IsLocation(LOCATION_SZONE)
            or not s.fieldfilter(tc) then return end

        Duel.MoveToField(
            tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
        )
    else
        --Set a Spell/Trap from opponent's GY
        if not tc:IsLocation(LOCATION_GRAVE)
            or not s.gyfilter(tc) then return end

        Duel.SSet(tp,tc)
    end
end
