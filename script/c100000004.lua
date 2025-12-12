--Photon Galaxy Defender
--Xyz monster with 2 Level 4 LIGHT monsters as materials
local s,id=GetID()
function s.initial_effect(c)
    --Xyz summon procedure
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_LIGHT),4,2)
    c:EnableReviveLimit()
    
    --Effect 1: Negate attack by detaching material
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetOperation(s.atkop)
    c:RegisterEffect(e1)
    
    --Effect 2: Add Level 8+ Photon/Galaxy monster to hand during End Phase
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    --Effect 3: Special Summon Photon Token if Tributed or destroyed by opponent
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_RELEASE)
    e3:SetCountLimit(1,{id,1})
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCondition(s.spcon)
    c:RegisterEffect(e4)
    
    --Global flag to track if attack was negated this turn
    aux.GlobalCheck(s,function()
        s.attack_negated=false
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_TURN_END)
        ge1:SetOperation(function() s.attack_negated=false end)
        Duel.RegisterEffect(ge1,0)
    end)
end

--Effect 1 operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:GetOverlayCount()>0 and c:RemoveOverlayCard(tp,1,1,REASON_EFFECT) then
        Duel.NegateAttack()
        s.attack_negated=true
    end
end

--Effect 2 condition
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return s.attack_negated
end

--Effect 2 target
function s.thfilter(c)
    return c:IsLevel(8) and c:IsAbleToHand() and 
           (c:IsSetCard(0x55) or c:IsSetCard(0x7b)) -- 0x55 is Photon, 0x7b is Galaxy
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Effect 2 operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--Effect 3 condition for destruction
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT) and re and re:GetHandlerPlayer()==1-tp
end

--Effect 3 target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsPlayerCanSpecialSummonMonster(tp,17418745,0,TYPES_TOKEN,2000,0,4,RACE_THUNDER,ATTRIBUTE_LIGHT) end
    Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

--Effect 3 operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 
        or not Duel.IsPlayerCanSpecialSummonMonster(tp,17418745,0,TYPES_TOKEN,2000,0,4,RACE_THUNDER,ATTRIBUTE_LIGHT) then return end
    local token=Duel.CreateToken(tp,17418745)
    if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP_DEFENSE)~=0 then
        --Cannot attack
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetDescription(17418745)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
        e1:SetCode(EFFECT_CANNOT_ATTACK)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        token:RegisterEffect(e1)
        --Cannot be used as Synchro Material
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetDescription(17418745)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
        e2:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        e2:SetValue(1)
        token:RegisterEffect(e2)
    end
end