--Master Control Dragon
local s,id=GetID()
s.levels={3,4,5}

function s.initial_effect(c)
    c:EnableReviveLimit()
    s.AddSpiralProcedure(c)

    ----------------------------------------
    -- Treat as not a Fusion while on field or grave
    ----------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_ADD_TYPE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e0:SetValue(TYPE_FUSION)
    e0:SetCondition(function() return false end) -- always false, so it never counts as Fusion
    c:RegisterEffect(e0)

    ----------------------------------------
    -- Level 3 Effect: Attack Negate + LP Gain
    ----------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_ATTACK_ANNOUNCE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.l3con)
    e1:SetTarget(s.l3tg)
    e1:SetOperation(s.l3op)
    c:RegisterEffect(e1)

    ----------------------------------------
    -- Level 4 Effect: Optional Spell/Trap modification
    ----------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCondition(s.l4con)
    e2:SetCost(s.l4cost)
    e2:SetTarget(s.l4tg)
    e2:SetOperation(s.l4op)
    c:RegisterEffect(e2)

    ----------------------------------------
    -- Level 5 Effect: Optional ATK gain (Ignition)
    ----------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_ATKCHANGE)
    e3:SetType(EFFECT_TYPE_IGNITION) -- Optional
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.l5con)
    e3:SetTarget(s.l5tg)
    e3:SetOperation(s.l5op)
    c:RegisterEffect(e3)
end

----------------------------------------
-- SPIRAL SUMMON PROCEDURE
----------------------------------------
function s.AddSpiralProcedure(c)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.spcon)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)
end

function s.matfilter(c,lv)
    return c:IsType(TYPE_LINK) and c:IsLink(lv) and c:IsAbleToRemoveAsCost()
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil,TYPE_LINK)
    local g3=g:Filter(s.matfilter,nil,3)
    local g4=g:Filter(s.matfilter,nil,4)
    local g5=g:Filter(s.matfilter,nil,5):Filter(Card.IsLocation,nil,LOCATION_MZONE)
    return g3:GetCount()>0 and g4:GetCount()>0 and g5:GetCount()>0
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil,TYPE_LINK)
    local g3=g:Filter(s.matfilter,nil,3)
    local g4=g:Filter(s.matfilter,nil,4)
    local g5=g:Filter(s.matfilter,nil,5):Filter(Card.IsLocation,nil,LOCATION_MZONE)
    if g3:GetCount()==0 or g4:GetCount()==0 or g5:GetCount()==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg3=g3:Select(tp,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg4=g4:Select(tp,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg5=g5:Select(tp,1,1,nil)

    local mats=Group.CreateGroup()
    mats:Merge(sg3)
    mats:Merge(sg4)
    mats:Merge(sg5)

    Duel.Remove(mats,POS_FACEUP,REASON_COST+REASON_MATERIAL+REASON_SPSUMMON)
    Duel.SpecialSummon(c,SUMMON_TYPE_SPECIAL,tp,tp,false,false,POS_FACEUP)
    c:CompleteProcedure()
end

----------------------------------------
-- Helper: Banished link checks
----------------------------------------
function s.has_banished_lv(tp,lv)
    return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsLink(lv) end,tp,LOCATION_REMOVED,0,1,nil)
end

function s.shuffle_back_lv(tp,lv)
    local g=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsLink(lv) end,tp,LOCATION_REMOVED,0,nil)
    if g:GetCount()>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local sg=g:Select(tp,1,1,nil)
        Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end

----------------------------------------
-- Level 3 Effect
----------------------------------------
function s.l3tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return s.has_banished_lv(tp,3) end
end

function s.l3con(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsFaceup() and s.has_banished_lv(tp,3)
end

function s.l3op(e,tp,eg,ep,ev,re,r,rp)
    local att=eg:GetFirst()
    if att then
        s.shuffle_back_lv(tp,3)
        Duel.NegateAttack()
        Duel.Recover(tp,att:GetAttack(),REASON_EFFECT)
    end
end

----------------------------------------
-- Level 4 Effect
----------------------------------------
function s.l4con(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsFaceup() 
        and rp==1-tp 
        and re:IsActiveType(TYPE_SPELL+TYPE_TRAP) 
        and s.has_banished_lv(tp,4)
end

function s.l4cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    e:SetLabel(0)
    if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        e:SetLabel(1)
    end
end

function s.l4tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_DECK,0,1,nil,RACE_CYBERSE) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.l4op(e,tp,eg,ep,ev,re,r,rp)
    if e:GetLabel()~=1 then return end
    s.shuffle_back_lv(tp,4)
    Duel.NegateEffect(ev)
    local dg=Duel.GetMatchingGroup(Card.IsRace,tp,LOCATION_DECK,0,nil,RACE_CYBERSE)
    if dg:GetCount()>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=dg:Select(tp,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

----------------------------------------
-- Level 5 Effect
----------------------------------------
function s.l5con(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsFaceup() and s.has_banished_lv(tp,5)
end

function s.l5tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return s.has_banished_lv(tp,5) end
end

function s.l5op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(function(tc) return tc:IsFaceup() and tc:IsLink(5) end,tp,LOCATION_REMOVED,0,nil)
    if g:GetCount()==0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local sg=g:Select(tp,1,1,nil)
    Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)

    local diff=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(diff)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
end
