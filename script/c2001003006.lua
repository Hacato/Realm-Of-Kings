--Domain of the Furies
local s,id=GetID()
function s.initial_effect(c)
    --Set 1 "Witness of Tisiphone"
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)
    
    --Add Level 8 Ritual Monster or Ritual Spell
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,{id,2})
    e2:SetCost(s.thcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    --Shuffle self to deck to add a Fury to hand
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,3})
    e3:SetCost(s.rtdcost)
    e3:SetTarget(s.rtdtg)
    e3:SetOperation(s.rtdop)
    c:RegisterEffect(e3)
end

s.listed_names={2001003001,2001003002,2001003003} --Fury monster ID codes

--Filter function to Set Witness of Tisiphone
function s.setfilter(c)
    return c:IsCode(2001003007) and c:IsSSetable()
end

--Activation target function
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end -- Card can always be activated
    
    -- Make the set effect optional
    if Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) 
       and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
       and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        e:SetCategory(CATEGORY_SEARCH)
        Duel.SetOperationInfo(0,CATEGORY_SEARCH,nil,1,tp,LOCATION_DECK)
    else
        e:SetCategory(0)
    end
end

--Activation operation function
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    if e:GetCategory()~=CATEGORY_SEARCH or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SSet(tp,g:GetFirst())
    end
end

--Helper function to check if a card can be selected
function s.cfilterfordisc(c,tp)
    return c:IsAbleToGraveAsCost() and 
           Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,c)
end

--Cost for adding a card to hand
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilterfordisc,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler(),tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.cfilterfordisc,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,e:GetHandler(),tp)
    s.sent_card = g:GetFirst()
    Duel.SendtoGrave(g,REASON_COST)
end

--Filter for cards to add based on the card sent to GY
function s.thfilter(c,cc)
    if not c:IsAbleToHand() then return false end
    
    --Check if sent card is a Ritual Monster
    if cc:IsRitualMonster() then
        return c:IsRitualSpell() and c:ListsCode(cc:GetCode()) 
    --Check if sent card is a Ritual Spell
    elseif cc:IsRitualSpell() then
        return c:IsRitualMonster() and c:IsLevel(8) and c:ListsCode(cc:GetCode())
    --Otherwise check if sent card lists the card we want to add
    else
        return ((c:IsRitualMonster() and c:IsLevel(8)) or c:IsRitualSpell()) and cc:ListsCode(c:GetCode())
    end
end

--Target function for adding a card to hand
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end -- Check is done in cost
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Operation function for adding a card to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    
    local tc = s.sent_card
    if not tc then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tc)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
    s.sent_card = nil
end

--Cost for returning to deck
function s.rtdcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToDeckAsCost() end
    Duel.SendtoDeck(e:GetHandler(),nil,2,REASON_COST)
end

--Filter for target Fury monsters on field or banished
function s.rtdfilter(c)
    return (c:IsCode(2001003001) or c:IsCode(2001003002) or c:IsCode(2001003003)) and 
           c:IsMonster() and c:IsAbleToHand() and 
           (c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_REMOVED))
end

--Target function for returning a Fury to hand
function s.rtdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.rtdfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.rtdfilter,tp,LOCATION_MZONE+LOCATION_REMOVED,0,1,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.rtdfilter,tp,LOCATION_MZONE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

--Operation for returning Fury to hand
function s.rtdop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end