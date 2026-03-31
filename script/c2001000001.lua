--ハロウフォール・オブ・ザ・ギルデントゥリー
--Hallowfall of the Gildentree
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    --Make effects Quick Effects
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(id)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(1,1) --Affects both players
    c:RegisterEffect(e2)
    
    --ATK/DEF gain
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e3:SetTarget(s.atktg)
    e3:SetValue(s.atkval)
    e3:SetRange(LOCATION_FZONE)
    c:RegisterEffect(e3)
    
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)
    
    --Send to GY when this card is sent to GY
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,0))
    e5:SetCategory(CATEGORY_TOGRAVE)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetCode(EVENT_TO_GRAVE)
    e5:SetProperty(EFFECT_FLAG_DELAY)
    e5:SetCountLimit(1,id)
    e5:SetCondition(s.sendcon)
    e5:SetTarget(s.sendtg)
    e5:SetOperation(s.sendop)
    c:RegisterEffect(e5)
end
s.listed_series={0x77b}

--Check if player is affected by quick effect conversion
function s.quickcon(tp)
    return Duel.IsPlayerAffectedByEffect(tp,id)
end

function s.atktg(e,c)
    return c:IsSetCard(0x77b)
end

function s.atkfilter(c)
    return c:IsSetCard(0x77b) and c:IsSpellTrap()
end

function s.atkval(e,c)
    if not c then return 0 end
    local g=Duel.GetMatchingGroup(s.atkfilter,c:GetControler(),LOCATION_REMOVED,0,nil)
    return #g*100
end

function s.sendcon(e)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.stfilter(c)
    return c:IsSetCard(0x77b) and c:IsSpellTrap() and c:IsAbleToGrave()
end

function s.sendtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.stfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.sendop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.stfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end