
--Seafarer Undead Brawler McCallister
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Synchro Summon:
    --1 Tuner + 1 or more non-Tuner "Seafarer" monsters
    Synchro.AddProcedure(c,nil,1,1,
        Synchro.NonTunerEx(Card.IsSetCard,SET_SEAFARER),1,99)
    c:EnableReviveLimit()

    --Destroy 1 Spell/Trap you control, then Set
    --1 Spell/Trap from your opponent's hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)

    --If destroyed and sent to the GY:
    --Special Summon another "Seafarer" from your GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--Spell/Trap you control that can be destroyed
function s.desfilter(c)
    return c:IsSpellTrap() and c:IsDestructable()
end

--Spell/Trap in opponent's hand
function s.handfilter(c)
    return c:IsSpellTrap()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(
                s.desfilter,tp,LOCATION_ONFIELD,0,1,nil
            )
            and Duel.IsExistingMatchingCard(
                s.handfilter,tp,0,LOCATION_HAND,1,nil
            )
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    --Destroy 1 Spell/Trap you control
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local dg=Duel.SelectMatchingCard(
        tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil
    )
    if #dg==0 then return end
    if Duel.Destroy(dg,REASON_EFFECT)==0 then return end

    --Check for available Spell/Trap Zone
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

    Duel.BreakEffect()

    --Reveal opponent's Spell/Trap cards to you
    local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    local sg=hg:Filter(s.handfilter,nil)
    if #sg==0 then return end

    Duel.ConfirmCards(tp,sg)

    --Choose 1 of those Spell/Trap cards
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local tc=sg:Select(tp,1,1,nil):GetFirst()
    if not tc then return end

    --Set it on your side of the field
    if Duel.MoveToField(
        tc,tp,tp,LOCATION_SZONE,POS_FACEDOWN,true
    ) then
        Duel.ConfirmCards(1-tp,tc)
    end

    --Shuffle opponent's hand after inspection
    Duel.ShuffleHand(1-tp)
end

--Destroyed and sent to the GY
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_DESTROY)
        and c:IsLocation(LOCATION_GRAVE)
end

--Other Seafarer monster in your GY
function s.spfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and not c:IsCode(id)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp
            )
    end
    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE
    )
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp
    )
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
