
--Seafarer Undead Gunslinger Cecile
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Synchro Summon:
    --1 Tuner + 1 or more non-Tuner "Seafarer" monsters
    Synchro.AddProcedure(c,nil,1,1,
        Synchro.NonTunerEx(Card.IsSetCard,SET_SEAFARER),1,99)
    c:EnableReviveLimit()

    --When Synchro Summoned:
    --Add 1 Seafarer Spell/Trap from GY to hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --Once per turn:
    --Destroy 1 Spell/Trap you control,
    --then destroy exactly 2 opponent's monsters
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

--Must be Synchro Summoned
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

--Seafarer Spell/Trap in your GY
function s.thfilter(c)
    return c:IsSpellTrap()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_GRAVE,0,1,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE
    )
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsExistingMatchingCard(
        s.thfilter,tp,LOCATION_GRAVE,0,1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil
    )

    if #g>0 and Duel.SendtoHand(
        g,nil,REASON_EFFECT
    )>0 then
        Duel.ConfirmCards(1-tp,g)
    end
end

--Spell/Trap you control that can be destroyed
function s.stfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Opponent's monster that can be destroyed
function s.monfilter(c)
    return c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.stfilter,tp,LOCATION_ONFIELD,0,1,nil
        )
        and Duel.IsExistingMatchingCard(
            s.monfilter,tp,0,LOCATION_MZONE,2,nil
        )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD
    )
    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,nil,2,1-tp,LOCATION_MZONE
    )
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    --Destroy 1 Spell/Trap you control
    if not Duel.IsExistingMatchingCard(
        s.stfilter,tp,LOCATION_ONFIELD,0,1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local sg=Duel.SelectMatchingCard(
        tp,s.stfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )

    if #sg==0 then return end

    if Duel.Destroy(sg,REASON_EFFECT)==0 then
        return
    end

    --Then destroy exactly 2 opponent's monsters
    if not Duel.IsExistingMatchingCard(
        s.monfilter,tp,0,LOCATION_MZONE,2,nil
    ) then
        return
    end

    Duel.BreakEffect()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local mg=Duel.SelectMatchingCard(
        tp,s.monfilter,tp,0,LOCATION_MZONE,2,2,nil
    )

    if #mg==2 then
        Duel.Destroy(mg,REASON_EFFECT)
    end
end
