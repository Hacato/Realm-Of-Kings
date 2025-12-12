--Slayer-Doom The Eternal God Of Destruction
--Custom card script
local s,id,o=GetID()
function s.initial_effect(c)
    --Link summon procedure
    c:EnableReviveLimit()
    Link.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x2407),2,nil)
    
    --This card is always treated as every attribute
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_ADD_ATTRIBUTE)
    e1:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
    e1:SetValue(ATTRIBUTE_EARTH+ATTRIBUTE_WATER+ATTRIBUTE_FIRE+ATTRIBUTE_WIND+ATTRIBUTE_LIGHT+ATTRIBUTE_DARK+ATTRIBUTE_DIVINE)
    c:RegisterEffect(e1)
    
    --Cannot be targeted or destroyed by card effects
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(1)
    c:RegisterEffect(e3)
    
    --Add up to 2 Slayer spell/trap cards from GY to hand when summoned
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetCondition(s.thcon)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
    
    --Negate opponent's effect that would make this card leave the field
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_TOGRAVE)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_CHAINING)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1,id)
    e5:SetCondition(s.negcon)
    e5:SetCost(s.negcost)
    e5:SetTarget(s.negtg)
    e5:SetOperation(s.negop)
    c:RegisterEffect(e5)
    
    --Gain ATK when destroying monster by battle
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_ATKCHANGE)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_BATTLE_DESTROYING)
    e6:SetCondition(aux.bdcon)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
    
    --Negate and destroy opponent's activated cards (twice per turn)
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,3))
    e7:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_TOGRAVE)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_CHAINING)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(2,id+100)
    e7:SetCondition(s.discon)
    e7:SetCost(s.discost)
    e7:SetTarget(s.distg)
    e7:SetOperation(s.disop)
    c:RegisterEffect(e7)
    
    --Special summon Slayer monster from GY by banishing this card from GY
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,4))
    e8:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
    e8:SetType(EFFECT_TYPE_IGNITION)
    e8:SetRange(LOCATION_GRAVE)
    e8:SetCost(aux.bfgcost)
    e8:SetTarget(s.sptg)
    e8:SetOperation(s.spop)
    c:RegisterEffect(e8)
end

--Link summon condition
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--Add Slayer spell/trap from GY
function s.thfilter(c)
    return c:IsSetCard(0x2407) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,2,nil)
    if g:GetCount()>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--Negate effect that would make this card leave field
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
    local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
    return g and g:IsContains(c) and rp~=tp and re:IsActiveType(TYPE_SPELL+TYPE_TRAP+TYPE_MONSTER)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDiscardDeckAsCost(tp,1) end
    Duel.DiscardDeck(tp,1,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsDestructable() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg,REASON_EFFECT)
    end
end

--Gain ATK
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if c:IsRelateToEffect(e) and c:IsFaceup() and bc and bc:IsType(TYPE_MONSTER) then
        local atk=bc:GetAttack()
        if atk>0 then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(atk)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE)
            c:RegisterEffect(e1)
        end
    end
end

--Negate opponent's activated cards
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDiscardDeckAsCost(tp,2) end
    Duel.DiscardDeck(tp,2,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsDestructable() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg,REASON_EFFECT)
    end
end

--Special summon from GY
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2407) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler(),e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)~=0 then
        tc:CompleteProcedure()
    end
end