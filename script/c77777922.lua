
--Seafarer Undead Deckhand Pietro
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Link Summon:
    --2 WATER Zombie or Warrior monsters
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,2,2)

    --If Link Summoned:
    --Special Summon 1 Seafarer from Deck
    --to a zone this card points to
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --Once per turn:
    --Target 1 Spell/Trap in either GY;
    --Set it on your field
    --It cannot be activated this turn
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

--Link materials:
--WATER Zombie or WATER Warrior monsters
function s.matfilter(c,lc,sumtype,tp)
    return c:IsAttribute(ATTRIBUTE_WATER,lc,sumtype,tp)
        and c:IsRace(RACE_ZOMBIE+RACE_WARRIOR,lc,sumtype,tp)
end

--Must be Link Summoned
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--Seafarer monster in Deck
function s.spfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Available zones Pietro points to
function s.getzone(e,tp)
    local c=e:GetHandler()
    if not c:IsFaceup() or not c:IsLocation(LOCATION_MZONE) then
        return 0
    end

    return c:GetLinkedZone(tp)
        & Duel.GetLocationCount(tp,LOCATION_MZONE,tp,
            LOCATION_REASON_TOFIELD,0x7f)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return s.getzone(e,tp)~=0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK
    )
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local zone=s.getzone(e,tp)
    if zone==0 then return end

    if not Duel.IsExistingMatchingCard(
        s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp
    )

    if #g>0 then
        Duel.SpecialSummon(
            g,0,tp,tp,false,false,POS_FACEUP,zone
        )
    end
end

--Spell/Trap in either player's GY
function s.setfilter(c,tp)
    return c:IsSpellTrap()
        and c:IsSSetable()
        and (c:IsFieldSpell()
            or Duel.GetLocationCount(tp,LOCATION_SZONE)>0)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE)
            and s.setfilter(chkc,tp)
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.setfilter,tp,
            LOCATION_GRAVE,LOCATION_GRAVE,1,nil,tp
        )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectTarget(
        tp,s.setfilter,tp,
        LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,tp
    )

    Duel.SetOperationInfo(
        0,CATEGORY_LEAVE_GRAVE,g,1,0,0
    )
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e)
        or not tc:IsLocation(LOCATION_GRAVE)
        or not s.setfilter(tc,tp) then
        return
    end

    --Set the targeted Spell/Trap
    if Duel.SSet(tp,tc)==0 then
        return
    end

    --The Set card cannot be activated this turn
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_TRIGGER)
    e1:SetReset(
        RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
    )
    tc:RegisterEffect(e1)

    --Also prevent activating the Set card itself
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ACTIVATE)
    e2:SetReset(
        RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
    )
    tc:RegisterEffect(e2)
end
