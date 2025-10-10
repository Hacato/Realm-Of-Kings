--Grayseer the Grayscale Spy
--Script by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
    -- Link Summon: 2 LIGHT Fiend monsters, including a "Grayscale" monster
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,2,2,s.matcheck)

    -- Track the turn this card was Link Summoned
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e0:SetCode(EVENT_SPSUMMON_SUCCESS)
    e0:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
        local c=e:GetHandler()
        if c:IsSummonType(SUMMON_TYPE_LINK) then
            c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,Duel.GetTurnCount())
        end
    end)
    c:RegisterEffect(e0)

    -- Cannot be used as Link Material the turn it is Link Summoned, except for the Link Summon of a "Grayscale" Monster
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    e1:SetValue(function(e,lc,sumtype,tp)
        local c=e:GetHandler()
        local flag=c:GetFlagEffectLabel(id)
        if flag and flag==Duel.GetTurnCount() then
            return not (lc and lc:IsSetCard(0x2410))
        end
        return false
    end)
    c:RegisterEffect(e1)

    -- Monsters this card points to are unaffected by opponent's card effects
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.immtg)
    e2:SetValue(s.immval)
    c:RegisterEffect(e2)

    -- Quick Effect: Discard 1 to Special Summon non-Link "Grayscale" from Deck or GY, once per turn
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e3:SetCondition(s.spcon)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    e3:SetCountLimit(1,id)
    c:RegisterEffect(e3)
end
s.listed_series={0x2410}

-- Link Material filter: 2 LIGHT Fiend monsters, including a "Grayscale" monster
function s.matfilter(c,lc,sumtype,tp)
    return c:IsAttribute(ATTRIBUTE_LIGHT,lc,sumtype,tp) and c:IsRace(RACE_FIEND,lc,sumtype,tp)
end
function s.matcheck(g,lc,sumtype,tp)
    return g:IsExists(Card.IsSetCard,1,nil,0x2410)
end

-- Immune effect target: monsters this card points to
function s.immtg(e,c)
    local handler=e:GetHandler()
    return handler:GetLinkedGroup():IsContains(c)
end
function s.immval(e,te)
    return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Special Summon (Main Phase, Quick Effect)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2410) and not c:IsType(TYPE_LINK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end