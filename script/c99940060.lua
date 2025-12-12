-- NGNL Disboard World
local s, id = GetID()
local FLAG_RPS = 999500 -- Flag used to detect any RPS action

function s.initial_effect(c)
    -- Activate
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    -- Cannot be targeted or destroyed while both Pendulum Zones have NGNL cards
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetCondition(s.protcon)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetValue(1)
    c:RegisterEffect(e3)
    
    -- No battle damage from NGNL monsters
    local e4 = Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetRange(LOCATION_FZONE)
    e4:SetTargetRange(1,0)
    e4:SetCondition(s.protcon)
    e4:SetValue(s.damval)
    c:RegisterEffect(e4)
    
    -- Both players discard 1 and draw 1 after coin toss/die roll
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,0))
    e5:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_TOSS_COIN)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCondition(s.coincon)
    e5:SetTarget(s.drtg)
    e5:SetOperation(s.drop)
    c:RegisterEffect(e5)
    local e6 = e5:Clone()
    e6:SetCode(EVENT_TOSS_DICE)
    c:RegisterEffect(e6)
    
    -- Add NGNL Spell/Trap sent from Deck to GY
    local e8 = Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,1))
    e8:SetCategory(CATEGORY_TOHAND)
    e8:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e8:SetCode(EVENT_TO_GRAVE)
    e8:SetProperty(EFFECT_FLAG_DELAY)
    e8:SetRange(LOCATION_FZONE)
    e8:SetCondition(s.thcon)
    e8:SetTarget(s.thtg)
    e8:SetOperation(s.thop)
    c:RegisterEffect(e8)
    
    -- Return Pendulum card and place another
    local e9 = Effect.CreateEffect(c)
    e9:SetDescription(aux.Stringid(id,2))
    e9:SetCategory(CATEGORY_TOHAND)
    e9:SetType(EFFECT_TYPE_IGNITION)
    e9:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e9:SetRange(LOCATION_FZONE)
    e9:SetCountLimit(1,id)
    e9:SetTarget(s.pztg)
    e9:SetOperation(s.pzop)
    c:RegisterEffect(e9)
    
    -- Rock-Paper-Scissors Trigger (FLAG-BASED)
    local e10 = Effect.CreateEffect(c)
    e10:SetDescription(aux.Stringid(id,3))
    e10:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
    e10:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e10:SetCode(EVENT_CHAIN_SOLVED)
    e10:SetRange(LOCATION_FZONE)
    e10:SetCondition(s.rpscon)
    e10:SetTarget(s.rpstg)
    e10:SetOperation(s.rpsop)
    c:RegisterEffect(e10)
end

s.listed_series={0x994}

-------------------------------------------------
-- Conditions
-------------------------------------------------
function s.protcon(e)
    local tp=e:GetHandlerPlayer()
    local lp=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
    local rp=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
    return lp and rp and lp:IsSetCard(0x994) and rp:IsSetCard(0x994)
end

function s.damval(e,re,val,r,rp,rc)
    if not rc then return 0 end
    return rc:IsSetCard(0x994) and (r & REASON_BATTLE) ~= 0
end

function s.coincon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp
end

-------------------------------------------------
-- Discard + Draw from Coin/Dice
-------------------------------------------------
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,PLAYER_ALL,1)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g1=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
    local g2=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    if #g1>0 and #g2>0 then
        local sg1=g1:Select(tp,1,1,nil)
        local sg2=g2:Select(1-tp,1,1,nil)
        sg1:Merge(sg2)
        if Duel.SendtoGrave(sg1,REASON_EFFECT+REASON_DISCARD)>0 then
            Duel.Draw(tp,1,REASON_EFFECT)
            Duel.Draw(1-tp,1,REASON_EFFECT)
        end
    end
end

-------------------------------------------------
-- Add NGNL S/T sent from Deck
-------------------------------------------------
function s.thfilter(c,tp)
    return c:IsSetCard(0x994) and c:IsType(TYPE_SPELL+TYPE_TRAP) 
        and c:IsPreviousLocation(LOCATION_DECK) and c:IsControler(tp) and c:IsAbleToHand()
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.thfilter,1,nil,tp)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=eg:Filter(s.thfilter,nil,tp)
    if chk==0 then return #g>0 end
    Duel.SetTargetCard(eg)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g=eg:Filter(s.thfilter,nil,tp):Filter(Card.IsRelateToEffect,nil,e)
    if #g>0 then
        local sg=g:Select(tp,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

-------------------------------------------------
-- Pendulum Zone return + replace
-------------------------------------------------
function s.pzfilter(c)
    return c:IsSetCard(0x994) and c:IsFaceup()
end

function s.placefilter(c)
    return c:IsSetCard(0x994) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end

function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_PZONE) and chkc:IsControler(tp) and s.pzfilter(chkc) end
    if chk==0 then
        return Duel.IsExistingTarget(s.pzfilter,tp,LOCATION_PZONE,0,1,nil)
            and Duel.IsExistingMatchingCard(s.placefilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_EXTRA,0,1,nil)
    end
    local g=Duel.SelectTarget(tp,s.pzfilter,tp,LOCATION_PZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.pzop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.SendtoHand(tc,nil,REASON_EFFECT)>0
        and tc:IsLocation(LOCATION_HAND) and Duel.CheckPendulumZones(tp) then
        local g=Duel.SelectMatchingCard(tp,s.placefilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_EXTRA,0,1,1,nil)
        if #g>0 then
            Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        end
    end
end

-------------------------------------------------
-- Rock-Paper-Scissors Trigger Effect (FLAG-BASED)
-------------------------------------------------
function s.rpscon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:GetHandler():GetFlagEffect(FLAG_RPS)>0
end

function s.rpstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,PLAYER_ALL,1)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end

function s.rpsop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
        Duel.DiscardHand(tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD)
    end
    if Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)>0 then
        Duel.DiscardHand(1-tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD)
    end
    Duel.Draw(tp,1,REASON_EFFECT)
    Duel.Draw(1-tp,1,REASON_EFFECT)
end
