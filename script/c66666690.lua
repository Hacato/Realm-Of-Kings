
--Seafarer First Mate Elizabeth
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --If Summoned: Add 1 "Seafarer" monster from Deck to hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)
    local e3=e1:Clone()
    e3:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
    c:RegisterEffect(e3)

    --Target 1 opponent's face-up Spell/Trap; Set it on your field
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_CONTROL)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_MZONE)
    e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e4:SetCountLimit(1,id)
    e4:SetTarget(s.settg)
    e4:SetOperation(s.setop)
    c:RegisterEffect(e4)
end

--Search a "Seafarer" monster
function s.thfilter(c)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_DECK,0,1,nil
        )
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil
    )
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
    end
end

--Opponent's face-up Spell/Trap that can be taken
function s.setfilter(c)
    return c:IsFaceup()
        and c:IsSpellTrap()
        and c:IsLocation(LOCATION_SZONE)
        and c:GetSequence()<5
        and c:IsAbleToChangeControler()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(1-tp)
            and s.setfilter(chkc)
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
        or not tc:IsFaceup()
        or not tc:IsLocation(LOCATION_SZONE)
        or not tc:IsControler(1-tp)
        or not tc:IsAbleToChangeControler()
        or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    --Move the targeted card to your Spell/Trap Zone
    if Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true
    ) then
        --Set the stolen Spell/Trap
        Duel.ChangePosition(tc,POS_FACEDOWN)
        Duel.ConfirmCards(1-tp,tc)
    end
end
