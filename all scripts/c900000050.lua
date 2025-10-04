local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Fusion material: 3+ Dovakin Fusion monsters (different names implied by normal fusion rules)
    Fusion.AddProcMixRep(c, true, true, s.ffilter, 3, 99)

    -- Contact Fusion (banish cards you control and/or from your GY)
    Fusion.AddContactProc(c, s.contactfil, s.contactop, nil, nil, SUMMON_TYPE_FUSION)

    -- Cannot be targeted or destroyed by card effects
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    local e2 = e1:Clone()
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE + EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)

    -- Shuffle and draw on Fusion Summon (once per turn)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_TODECK + CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCountLimit(1, id)
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
    c:RegisterEffect(e3)

    -- Negate and shuffle (can use up to 3 times per turn)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 1))
    e4:SetCategory(CATEGORY_NEGATE + CATEGORY_TODECK + CATEGORY_DRAW)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP + EFFECT_FLAG_DAMAGE_CAL)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(3, id + 100) -- thrice per turn
    e4:SetCondition(s.negcon)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)

    -- Double piercing damage
    local e5 = Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_PIERCE)
    e5:SetValue(DOUBLE_DAMAGE)
    c:RegisterEffect(e5)

    -- Float into another Dovakin Fusion (once per turn)
    local e6 = Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id, 2))
    e6:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON)
    e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e6:SetProperty(EFFECT_FLAG_DELAY)
    e6:SetCode(EVENT_LEAVE_FIELD)
    e6:SetCountLimit(1, id + 200)
    e6:SetCondition(s.fscon)
    e6:SetTarget(s.fstg)
    e6:SetOperation(s.fsop)
    c:RegisterEffect(e6)
end

s.listed_series = {0x2411} -- Change this to match Dovakin series ID

-- Fusion material filter: must be Dovakin (0x2411) and Fusion-type
function s.ffilter(c, fc, sumtype, tp)
    return c:IsSetCard(0x2411, fc, sumtype, tp) and c:IsType(TYPE_FUSION, fc, sumtype, tp)
end

-- Contact Fusion filters (your on-field and your GY)
function s.contactfil(tp)
    return Duel.GetMatchingGroup(Card.IsAbleToRemoveAsCost, tp, LOCATION_ONFIELD + LOCATION_GRAVE, 0, nil)
end

function s.contactop(g, tp)
    Duel.Remove(g, POS_FACEUP, REASON_COST + REASON_MATERIAL)
end

-- Shuffle and draw effect (trigger only if Fusion Summoned)
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsPlayerCanDraw(tp, 3) and Duel.IsPlayerCanDraw(1 - tp, 3)
    end
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 0, PLAYER_ALL, LOCATION_GRAVE + LOCATION_REMOVED)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, PLAYER_ALL, 3)
end

function s.drop(e, tp, eg, ep, ev, re, r, rp)
    local g1 = Duel.GetMatchingGroup(Card.IsMonster, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, nil)
    local g2 = Duel.GetMatchingGroup(Card.IsMonster, tp, 0, LOCATION_GRAVE + LOCATION_REMOVED, nil)
    g1:Merge(g2)
    if #g1 > 0 then
        Duel.SendtoDeck(g1, nil, SEQ_DECKSHUFFLE, REASON_EFFECT)
    end
    Duel.BreakEffect()
    Duel.Draw(tp, 3, REASON_EFFECT)
    Duel.Draw(1 - tp, 3, REASON_EFFECT)
end

-- Negate effect
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    return rp == 1 - tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
    local rc = re:GetHandler()
    if rc and rc:IsRelateToEffect(re) and rc:IsAbleToDeck() then
        Duel.SetOperationInfo(0, CATEGORY_TODECK, rc, 1, 0, 0)
        Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, 1 - tp, 1)
    end
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    if not Duel.NegateActivation(ev) then return end
    local rc = re:GetHandler()
    if rc and rc:IsRelateToEffect(re) and rc:IsAbleToDeck() then
        rc:CancelToGrave()
        if Duel.SendtoDeck(rc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) > 0 then
            Duel.BreakEffect()
            Duel.Draw(1 - tp, 1, REASON_EFFECT)
        end
    end
end

-- Float effect: if leaves the field by opponent's card effect, banish to Fusion Summon
function s.fscon(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousControler(tp)
        and c:IsReason(REASON_EFFECT) and rp == 1 - tp
end

function s.fsfilter(c, e, tp)
    return c:IsSetCard(0x2411) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false)
        and Duel.GetLocationCountFromEx(tp, tp, nil, c) > 0
end

function s.fstg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return e:GetHandler():IsAbleToRemove()
            and Duel.IsExistingMatchingCard(s.fsfilter, tp, LOCATION_EXTRA, 0, 1, nil, e, tp)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
end

function s.matfilter(c)
    return c:IsAbleToRemove() and c:IsMonster()
end

function s.fsop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    -- Banish this card as cost/material
    if Duel.Remove(c, POS_FACEUP, REASON_EFFECT) == 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
    local sc = Duel.SelectMatchingCard(tp, s.fsfilter, tp, LOCATION_EXTRA, 0, 1, 1, nil, e, tp):GetFirst()
    if not sc then return end
    -- Gather possible materials from hand/field/GY/deck (owner's)
    local mg = Duel.GetMatchingGroup(s.matfilter, tp, LOCATION_HAND + LOCATION_ONFIELD + LOCATION_GRAVE + LOCATION_DECK, 0, nil)
    if #mg == 0 then return end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_REMOVE)
    local mat = mg:Select(tp, 1, #mg, nil) -- player chooses how many to banish as materials (must be enough to satisfy fusion)
    if #mat > 0 and Duel.Remove(mat, POS_FACEUP, REASON_EFFECT + REASON_MATERIAL) > 0 then
        Duel.BreakEffect()
        Duel.SpecialSummon(sc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP)
        sc:CompleteProcedure()
    end
end