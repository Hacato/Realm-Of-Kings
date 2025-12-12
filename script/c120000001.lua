--Calling of the Noble Arms of Avalon
local s,id=GetID()
function s.initial_effect(c)
    --Activate: Add "Morgan" and a "Noble Arms" or card that mentions "Noble Arms"
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    --Graveyard effect: Banish to search "Avalon" card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
    --Equip as Quick Effect
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_EQUIP)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.eqtg)
    e3:SetOperation(s.eqop)
    c:RegisterEffect(e3)
    --Standard equip spell destruction when monster leaves
    aux.AddEquipProcedure(c)
end
-- e1: Activate and search
function s.filter1(c)
    return c:IsCode(24027078) and c:IsAbleToHand() -- "Morgan, the Enchantress of Avalon"
end
function s.filter2(c)
    return (c:IsSetCard(0x207a) or c:ListsCode(14733538)) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local g1=Duel.GetMatchingGroup(s.filter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
    local g2=Duel.GetMatchingGroup(s.filter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
    if #g1>0 and #g2>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg1=g1:Select(tp,1,1,nil)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg2=g2:Select(tp,1,1,nil)
        sg1:Merge(sg2)
        Duel.SendtoHand(sg1,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg1)
    end
end
-- e2: Banish to search "Avalon" cards (using specific codes instead of text search)
function s.gyfilter(c)
    -- Replace with actual card codes that have "Avalon" in name/effect
    -- Example codes - replace with actual Avalon archetype codes
    local avalon_codes = {24027078, 82140600, 120000001} -- Replace with real codes
    for i, code in ipairs(avalon_codes) do
        if c:IsCode(code) and c:IsAbleToHand() then
            return true
        end
    end
    return false
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
-- e3: Equip this card to a monster and give 500 ATK
function s.eqfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp)
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_MZONE,0,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
    local g=Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
    Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        if Duel.Equip(tp,c,tc) then
            -- Give 500 ATK
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_EQUIP)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(500)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e1)
            -- Equip limit
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_EQUIP_LIMIT)
            e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e2:SetValue(s.eqlimit)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e2)
        end
    end
end
function s.eqlimit(e,c)
    return c:IsControler(e:GetHandlerPlayer())
end
