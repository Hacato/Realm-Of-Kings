--Witness of Tisiphone
local s,id=GetID()
function s.initial_effect(c)
    --Declare card name, check opponent's hand
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    --Shuffle to deck to add Fury monster to hand
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,{id,2})
    e2:SetCost(s.rtdcost)
    e2:SetTarget(s.rtdtg)
    e2:SetOperation(s.rtdop)
    c:RegisterEffect(e2)
end

s.listed_names={2001003001,2001003002,2001003003} --Fury monster ID codes

--Filter for monsters that can be equipped from extra deck
function s.equipfilter(c)
    return c:IsMonster() and c:IsLocation(LOCATION_EXTRA) and not c:IsForbidden()
end

--Check if we can equip from extra deck
function s.equipcheck(tp)
    return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) and
           Duel.IsExistingMatchingCard(s.equipfilter,tp,LOCATION_EXTRA,0,1,nil) and
           Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and
           Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRitualMonster,Card.IsLevel,8),tp,LOCATION_MZONE,0,1,nil)
end

--Target function for activation
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 end
end

--Operation for activation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    --Announce a card name
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
    local ac=Duel.AnnounceCard(tp)
    
    --Opponent checks their hand
    local g=Duel.GetMatchingGroup(Card.IsCode,1-tp,LOCATION_HAND,0,nil,ac)
    Duel.ConfirmCards(tp,Duel.GetFieldGroup(tp,0,LOCATION_HAND))
    
    local tc=g:GetFirst()
    if tc and tc:IsMonster() then
        if tc:IsCanBeSpecialSummoned(e,0,1-tp,false,false) and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 then
            Duel.SpecialSummon(tc,0,1-tp,1-tp,false,false,POS_FACEUP)
        else
            Duel.SendtoGrave(tc,REASON_EFFECT)
        end
        
        --Check if can equip from Extra Deck
        if s.equipcheck(tp) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            --Select monster to equip
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
            local ec=Duel.SelectMatchingCard(tp,s.equipfilter,tp,LOCATION_EXTRA,0,1,1,nil):GetFirst()
            if not ec then return end
            
            --Select target for equip
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
            local tc=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil):GetFirst()
            if not tc then return end
            
            --Equip
            Duel.Equip(tp,ec,tc)
            
            --Equip limit
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            e1:SetValue(s.eqlimit)
            e1:SetLabelObject(tc)
            ec:RegisterEffect(e1)
        end
    end
    
    Duel.ShuffleHand(1-tp)
end

--Equip limitation
function s.eqlimit(e,c)
    return c==e:GetLabelObject()
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