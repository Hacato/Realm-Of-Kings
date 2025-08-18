--Eclipse Blue Scale Magician
--ID placeholder (replace with actual ID you want to use)
local s,id=GetID()
local SET_ECLIPSE=0x04B2

function s.initial_effect(c)
    --Pendulum attributes
    Pendulum.AddProcedure(c)
    
    --Cannot Pendulum Summon except DARK
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetRange(LOCATION_PZONE)
    c:RegisterEffect(e1)
    
    --Change Pendulum Scale to 4
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_CHANGE_LSCALE)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCondition(s.sccon)
    e2:SetValue(4)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EFFECT_CHANGE_RSCALE)
    c:RegisterEffect(e3)
    
    --Reduce effect damage to 0
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_PZONE)
    e4:SetCondition(s.damcon)
    e4:SetOperation(s.damop)
    e4:SetCountLimit(1,id)
    c:RegisterEffect(e4)
    
    --Add "Eclipse" monster from GY to hand
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,0))
    e5:SetCategory(CATEGORY_TOHAND)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e5:SetCode(EVENT_DESTROYED)
    e5:SetCountLimit(1,{id,1})
    e5:SetTarget(s.thtg)
    e5:SetOperation(s.thop)
    c:RegisterEffect(e5)
    local e6=e5:Clone()
    e6:SetCode(EVENT_TO_GRAVE)
    e6:SetCondition(s.thcon)
    c:RegisterEffect(e6)
end

--Pendulum Summon restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsAttribute(ATTRIBUTE_DARK) and sumtype&SUMMON_TYPE_PENDULUM==SUMMON_TYPE_PENDULUM
end

--Scale change condition
function s.sccon(e)
    local tp=e:GetHandlerPlayer()
    local seq=e:GetHandler():GetSequence()
    if seq==0 then
        return not Duel.GetFieldCard(tp,LOCATION_PZONE,1)
    else
        return not Duel.GetFieldCard(tp,LOCATION_PZONE,0)
    end
end

--Damage reduction condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsChainNegatable(ev) then return false end
    if not (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE)) then return false end
    if not Duel.IsExistingMatchingCard(s.eclipsefilter,tp,LOCATION_PZONE,0,1,e:GetHandler()) then return false end
    if not Duel.IsExistingMatchingCard(s.eclipsemonfilter,tp,LOCATION_MZONE,0,1,nil) then return false end
    
    local ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
    if ex and (cp==tp or cp==PLAYER_ALL) then return true end
    
    ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_RECOVER)
    if ex and (cp==tp or cp==PLAYER_ALL) and Duel.IsPlayerAffectedByEffect(tp,EFFECT_REVERSE_RECOVER) then return true end
    
    return false
end

--Damage reduction operation
function s.damop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local cid=Duel.GetChainInfo(ev,CHAININFO_CHAIN_ID)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CHANGE_DAMAGE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,0)
    e1:SetLabel(cid)
    e1:SetValue(s.damval)
    e1:SetReset(RESET_CHAIN)
    Duel.RegisterEffect(e1,tp)
end

--Return damage value
function s.damval(e,re,val,r,rp,rc)
    local cc=Duel.GetCurrentChain()
    if cc==0 or r&REASON_EFFECT==0 then return val end
    local cid=Duel.GetChainInfo(0,CHAININFO_CHAIN_ID)
    if cid==e:GetLabel() then return 0 end
    return val
end

--Filter for "Eclipse" card in Pendulum Zone
function s.eclipsefilter(c)
    return c:IsSetCard(SET_ECLIPSE) and c:IsFaceup()
end

--Filter for "Eclipse" monster on field
function s.eclipsemonfilter(c)
    return c:IsSetCard(SET_ECLIPSE) and c:IsFaceup() and c:IsType(TYPE_MONSTER)
end

--Add to hand condition
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsReason(REASON_EFFECT)
end

--Add to hand target
function s.thfilter(c)
    return c:IsSetCard(SET_ECLIPSE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand() and not c:IsCode(id)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

--Add to hand operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc)
    end
end