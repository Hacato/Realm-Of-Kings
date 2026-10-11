
--Seafarer Spyglass Helga
local s,id=GetID()

function s.initial_effect(c)
    --Target 1 opponent's Spell/Trap;
    --Set it on your side of the field
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_CONTROL)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,{id,0})
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    --If Special Summoned: Draw 1 card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.drtg)
    e2:SetOperation(s.drop)
    c:RegisterEffect(e2)
end

--Spell/Trap in opponent's regular S/T Zone
function s.setfilter(c)
    return c:IsSpellTrap()
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(1-tp)
            and chkc:IsLocation(LOCATION_SZONE)
            and s.setfilter(chkc)
    end

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingTarget(
                s.setfilter,tp,0,LOCATION_SZONE,1,nil
            )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectTarget(
        tp,s.setfilter,tp,0,LOCATION_SZONE,1,1,nil
    )
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e)
        or not tc:IsLocation(LOCATION_SZONE)
        or not s.setfilter(tc) then
        return
    end

    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    --Move the targeted Spell/Trap face-down
    --to your Spell/Trap Zone
    Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    )
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
    end

    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Draw(tp,1,REASON_EFFECT)
end
