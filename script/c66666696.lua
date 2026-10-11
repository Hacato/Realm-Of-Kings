
--Seafarer Undead Unagi
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Synchro Summon:
    --1 "Seafarer" Tuner + 1 or more non-Tuner monsters
    Synchro.AddProcedure(c,
        aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SEAFARER),
        1,1,
        Synchro.NonTuner(nil),1,99)
    c:EnableReviveLimit()

    --Cannot be destroyed by battle
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    --Destroy 1 Spell/Trap you control, then Set
    --1 Spell/Trap from your opponent's GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_DESTROY+CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)

    --Gain 100 ATK for each Spell/Trap in your S/T Zone
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)
end

--ATK boost: 100 per Spell/Trap in your S/T Zone
function s.atkval(e,c)
    local tp=c:GetControler()
    return Duel.GetMatchingGroupCount(
        s.stfilter,tp,LOCATION_SZONE,0,nil
    )*100
end

function s.stfilter(c)
    return c:IsSpellTrap() and c:GetSequence()<5
end

--Spell/Trap you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Opponent's Spell/Trap in their GY that can be Set
function s.setfilter(c,tp)
    return c:IsSpellTrap()
        and c:IsSSetable()
        and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
        )
        and Duel.IsExistingMatchingCard(
            s.setfilter,tp,0,LOCATION_GRAVE,1,nil,tp
        )
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,1-tp,LOCATION_GRAVE)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    --Destroy 1 Spell/Trap you control
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end

    if Duel.Destroy(dg,REASON_EFFECT)==0 then return end

    --Check that a Spell/Trap Zone is available
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

    Duel.BreakEffect()

    --Select 1 Spell/Trap from opponent's GY
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(
        tp,s.setfilter,tp,0,LOCATION_GRAVE,1,1,nil,tp
    )
    local tc=g:GetFirst()
    if not tc then return end

    --Set it on your side of the field
    if Duel.SSet(tp,tc)>0 then
        Duel.ConfirmCards(1-tp,tc)
    end
end
