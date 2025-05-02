-- Galaxy Wand Sage
local s,id=GetID()
function s.initial_effect(c)
    -- Effect 1: Summon when controlling low-level, search high-level
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id+1)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)
    
    -- Effect 2: Summon when controlling high-level, search low-level
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id+1)
    e2:SetCondition(s.spcon2)
    e2:SetTarget(s.sptg2)
    e2:SetOperation(s.spop2)
    c:RegisterEffect(e2)
    
    -- Level modification effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CHANGE_LEVEL)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.lvcon4)
    e3:SetValue(4)
    c:RegisterEffect(e3)
    
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CHANGE_LEVEL)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.lvcon8)
    e4:SetValue(8)
    c:RegisterEffect(e4)
    
    -- Global once-per-turn restriction
    local ge1=Effect.CreateEffect(c)
    ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    ge1:SetCode(EVENT_SUMMON_SUCCESS)
    ge1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    ge1:SetRange(LOCATION_MZONE)
    ge1:SetLabelObject(c)
    ge1:SetOperation(s.regop)
    Duel.RegisterEffect(ge1,0)
end

-- Archetype definitions
s.listed_series={0x55, 0x7B} -- Galaxy and Photon

-- Effect 1 Condition (control only Level/Rank 4 or lower)
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    return #g>0 and g:FilterCount(aux.NOT(s.lowfilter),nil)==0
end

function s.lowfilter(c)
    return (c:IsSetCard(0x55) or c:IsSetCard(0x7B)) and c:IsLevelBelow (4) or c:IsRankBelow(4)
end

-- Effect 1 Target
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(s.highfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- Effect 2 Condition (control only Level/Rank 8 or higher)
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    return #g>0 and g:FilterCount(aux.NOT(s.highmonfilter),nil)==0
end

function s.highmonfilter(c)
    return (c:IsSetCard(0x55) or c:IsSetCard(0x7B)) and c:IsLevelAbove(8) or c:IsRankAbove(8)
end

-- Effect 2 Target
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(s.lowsearchfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- Search filters
function s.highfilter(c)
    return (c:IsSetCard(0x55) or c:IsSetCard(0x1079)) and (c:GetLevel()>=8 or c:GetRank()>=8) and c:IsAbleToHand()
end

function s.lowsearchfilter(c)
    return (c:IsSetCard(0x55) or c:IsSetCard(0x1079)) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

-- Operations
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.highfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD,0,1)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.lowsearchfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end

-- Level modification conditions
function s.lvcon4(e)
    return e:GetHandler():GetFlagEffect(id)>0
end

function s.lvcon8(e)
    return e:GetHandler():GetFlagEffect(id+1)>0
end

-- Global once-per-turn restriction
function s.regop(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    if tc==e:GetLabelObject() then
        Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    end
end

function s.actcon(e)
    return Duel.GetFlagEffect(e:GetHandlerPlayer(),id)==0
end