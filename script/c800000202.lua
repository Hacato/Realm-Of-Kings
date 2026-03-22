local s,id=GetID()

function s.initial_effect(c)
    -- (1) Special Summon from hand (Quick Effect)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,0})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Search when destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    -- (3) Material + effect lock
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,2})
    e3:SetTarget(s.matg)
    e3:SetOperation(s.maop)
    c:RegisterEffect(e3)
    
    -- (4) Kadingir activation
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.kadcon)
    e4:SetTarget(s.kadtg)
    e4:SetOperation(s.kadop)
    c:RegisterEffect(e4)
    
    local e5=e4:Clone()
    e5:SetCode(EVENT_BE_BATTLE_TARGET)
    c:RegisterEffect(e5)
end

-- (1)
function s.descfilter(c)
    return c:IsSetCard(0x2406) and c:IsMonster() and not c:IsCode(id) and c:IsDestructable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.descfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,s.descfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Destroy(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2)
function s.thfilter(c)
    return c:IsSetCard(0x2406) and c:IsLevel(4) and c:IsAbleToHand()
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsReason(REASON_DESTROY)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- (3)
function s.matg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.maop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    local c=e:GetHandler()
    if not tc or not tc:IsRelateToEffect(e) or not c:IsFaceup() then return end
    
    -- Cannot be used as material
    local codes={
        EFFECT_CANNOT_BE_FUSION_MATERIAL,
        EFFECT_CANNOT_BE_SYNCHRO_MATERIAL,
        EFFECT_CANNOT_BE_XYZ_MATERIAL,
        EFFECT_CANNOT_BE_LINK_MATERIAL
    }
    for _,code in ipairs(codes) do
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(code)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end

    -- Cannot activate effects
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_TRIGGER)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e2)
end

-- (4)
function s.kadcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsFaceup() then return false end
    
    if e:GetCode()==EVENT_CHAINING then
        local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
        return g and g:IsContains(c)
    end
    
    return true -- battle target case
end

function s.kadfilter(c)
    return c:IsCode(800000139)
end

function s.kadtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.kadfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
    end
end

function s.kadop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.kadfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil):GetFirst()
    if not tc then return end

    -- Proper activation (Spell/Trap)
    Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)

    -- Counter count
    local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,0x2406),tp,LOCATION_MZONE,0,c)
    tc:AddCounter(0x1996,ct)
end local s,id=GetID()

function s.initial_effect(c)
    -- (1) Special Summon from hand (Quick Effect)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,{id,0})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    
    -- (2) Search when destroyed
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
    
    -- (3) Material + effect lock
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetCountLimit(1,{id,2})
    e3:SetTarget(s.matg)
    e3:SetOperation(s.maop)
    c:RegisterEffect(e3)
    
    -- (4) Kadingir activation (targeted by effect)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.kadcon)
    e4:SetTarget(s.kadtg)
    e4:SetOperation(s.kadop)
    c:RegisterEffect(e4)
    
    -- (4b) Kadingir activation (battle)
    local e5=e4:Clone()
    e5:SetCode(EVENT_BE_BATTLE_TARGET)
    c:RegisterEffect(e5)
end

-- (1) Destroy 1 SZS to Special Summon
function s.descfilter(c)
    return c:IsSetCard(0x2406) and c:IsMonster() and not c:IsCode(id) and c:IsDestructable()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.descfilter,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,s.descfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Destroy(g,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- (2) Search
function s.thfilter(c)
    return c:IsSetCard(0x2406) and c:IsLevel(4) and c:IsAbleToHand()
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsReason(REASON_DESTROY)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- (3) Lock target
function s.matg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.maop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    local c=e:GetHandler()
    if not tc or not tc:IsRelateToEffect(e) or not c:IsFaceup() then return end

    local codes={
        EFFECT_CANNOT_BE_FUSION_MATERIAL,
        EFFECT_CANNOT_BE_SYNCHRO_MATERIAL,
        EFFECT_CANNOT_BE_XYZ_MATERIAL,
        EFFECT_CANNOT_BE_LINK_MATERIAL
    }
    for _,code in ipairs(codes) do
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(code)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end

    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_TRIGGER)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e2)
end

-- (4) Condition
function s.kadcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsFaceup() then return false end
    
    if e:GetCode()==EVENT_CHAINING then
        local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
        return g and g:IsContains(c)
    end
    
    if e:GetCode()==EVENT_BE_BATTLE_TARGET then
        return Duel.GetAttackTarget()==c
    end
    
    return false
end

function s.kadfilter(c)
    return c:IsCode(800000139)
end

function s.kadtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.kadfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
    end
end

-- FIXED Continuous Trap Activation
function s.kadop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local tc=Duel.SelectMatchingCard(tp,s.kadfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil):GetFirst()
    if not tc then return end

    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

    -- Move to SZONE face-up
    Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)

    -- Activate its effect
    local te=tc:GetActivateEffect()
    if te then
        Duel.ClearTargetCard()
        local tep=tc:GetControler()
        local cost=te:GetCost()
        if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
        Duel.BreakEffect()
        local target=te:GetTarget()
        if target then target(te,tep,eg,ep,ev,re,r,rp,1) end
        Duel.BreakEffect()
        local op=te:GetOperation()
        if op then op(te,tep,eg,ep,ev,re,r,rp) end
    end

    -- Counters
    local ct=Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,0x2406),tp,LOCATION_MZONE,0,c)
    tc:AddCounter(0x1996,ct)
end