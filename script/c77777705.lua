
--Seafarer Undead King Black Bart
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Synchro Summon:
    --1 Tuner + 1 or more non-Tuner "Seafarer" monsters
    Synchro.AddProcedure(c,nil,1,1,
        Synchro.NonTunerEx(Card.IsSetCard,SET_SEAFARER),1,99)
    c:EnableReviveLimit()

    --Once per turn:
    --Destroy 1 Spell/Trap you control,
    --then banish 1 card your opponent controls
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.rmtg)
    e1:SetOperation(s.rmop)
    c:RegisterEffect(e1)

    --Once per turn:
    --Set 1 Spell/Trap from opponent's hand or GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)

    --Cannot be targeted by opponent's card effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
end

--Spell/Trap you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Opponent's card that can be banished
function s.rmfilter(c)
    return c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
        )
        and Duel.IsExistingMatchingCard(
            s.rmfilter,tp,0,LOCATION_ONFIELD,1,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD
    )
    Duel.SetOperationInfo(
        0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD
    )
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
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

    if Duel.Destroy(dg,REASON_EFFECT)==0 then
        return
    end

    --Then banish 1 opponent's card
    if not Duel.IsExistingMatchingCard(
        s.rmfilter,tp,0,LOCATION_ONFIELD,1,nil
    ) then
        return
    end

    Duel.BreakEffect()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local rg=Duel.SelectMatchingCard(
        tp,s.rmfilter,tp,0,LOCATION_ONFIELD,1,1,nil
    )

    if #rg>0 then
        Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)
    end
end

--Spell/Trap in opponent's hand or GY
function s.setfilter(c)
    return c:IsSpellTrap()
        and c:IsAbleToChangeControler()
        and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(
                s.setfilter,tp,0,
                LOCATION_HAND+LOCATION_GRAVE,1,nil
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_CONTROL,nil,1,1-tp,
        LOCATION_HAND+LOCATION_GRAVE
    )
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    --Reveal opponent's hand so you can select
    --a Spell/Trap, then shuffle their hand afterward
    local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    local reveal=hg:Filter(Card.IsSpellTrap,nil)

    if #reveal>0 then
        Duel.ConfirmCards(tp,reveal)
    end

    if not Duel.IsExistingMatchingCard(
        s.setfilter,tp,0,
        LOCATION_HAND+LOCATION_GRAVE,1,nil
    ) then
        Duel.ShuffleHand(1-tp)
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=Duel.SelectMatchingCard(
        tp,s.setfilter,tp,0,
        LOCATION_HAND+LOCATION_GRAVE,1,1,nil
    )

    local tc=sg:GetFirst()
    if not tc then
        Duel.ShuffleHand(1-tp)
        return
    end

    --Set the selected opponent's Spell/Trap
    --on your side of the field
    Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    )

    Duel.ShuffleHand(1-tp)
end
