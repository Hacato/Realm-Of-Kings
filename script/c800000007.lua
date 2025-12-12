--Yoshiie Formation – Battle Pledge
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e1)
    
    --Cannot control multiple copies
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetCode(EFFECT_CANNOT_HAVE_MULTIPLE_COPIES)
    c:RegisterEffect(e2)
    
    --Search Yoshiie monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetCondition(s.searchcon)
    e3:SetTarget(s.searchtg)
    e3:SetOperation(s.searchop)
    c:RegisterEffect(e3)
    
    --Special Summon FIRE Warrior from GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_TO_GRAVE)
    e4:SetRange(LOCATION_SZONE)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

s.listed_series={0x2408}

--Search condition: control a Yoshiie monster
function s.searchcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x2408),tp,LOCATION_MZONE,0,1,nil)
end

--Search filter: Yoshiie monster
function s.searchfilter(c)
    return c:IsSetCard(0x2408) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

--Search target
function s.searchtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.searchfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Search operation
function s.searchop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.searchfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--Special Summon condition: Yoshiie monster sent to GY
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spconfilter,1,nil,tp)
end

function s.spconfilter(c,tp)
    return c:IsSetCard(0x2408) and c:IsType(TYPE_MONSTER) and c:IsPreviousControler(tp) 
        and c:IsPreviousLocation(LOCATION_MZONE) and c:IsReason(REASON_DESTROY+REASON_RELEASE+REASON_BATTLE+REASON_EFFECT)
end

--Special Summon filter: FIRE Warrior in GY
function s.spfilter(c,e,tp)
    return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsRace(RACE_WARRIOR) 
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

--Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
end