-- A Neo Emerges
-- Continuous Trap
-- scripted by Hacato
-- Card ID for "Elemental HERO Neos": 89943723
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local act=Effect.CreateEffect(c)
    act:SetType(EFFECT_TYPE_ACTIVATE)
    act:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(act)

    -- (1) Opponent activates a card/effect → Special Summon 1 "Neo-Spacian"
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_SZONE)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon_chain)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- (2) Opponent declares an attack → Special Summon 1 "Neo-Spacian"
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_ATTACK_ANNOUNCE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.spcon_attack)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

-- Opponent activated a card/effect
function s.spcon_chain(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp
end

-- Opponent declared an attack
function s.spcon_attack(e,tp,eg,ep,ev,re,r,rp)
    local a=Duel.GetAttacker()
    return a and a:GetControler()~=tp
end

-- Neo-Spacian filter
function s.neosp_filter(c,e,tp)
    return c:IsSetCard(0x1f) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Target for Neo-Spacian summon
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
           and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.neosp_filter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end

-- Operation: Neo-Spacian summon + optional Fusion
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.neosp_filter),tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g==0 then return end
    if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==0 then return end

    -- Optional Fusion Summon (Main/Battle Phase)
    local ph=Duel.GetCurrentPhase()
    if not (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE or ph==PHASE_BATTLE_START or ph==PHASE_BATTLE_STEP) then return end
    if Duel.GetFlagEffect(tp,id+1000)>0 then return end

    local ed=Duel.GetMatchingGroup(function(c)
        return c:IsType(TYPE_FUSION) and Card.ListsCodeAsMaterial(c,89943723)
    end,tp,LOCATION_EXTRA,0,nil)
    if #ed==0 then return end

    local mg=Duel.GetMatchingGroup(Card.IsAbleToDeckAsCost,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
    local valid_fusions=ed:Filter(function(fc) return fc:CheckFusionMaterial(mg) end,nil)
    if #valid_fusions==0 then return end
    if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local fc=valid_fusions:Select(tp,1,1,nil):GetFirst()
    if not fc or Duel.GetLocationCountFromEx(tp,tp,nil,fc)<=0 then return end

    local matpool=Duel.GetMatchingGroup(Card.IsAbleToDeckAsCost,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
    if not fc:CheckFusionMaterial(matpool) then return end
    local mat=Duel.SelectFusionMaterial(tp,fc,matpool)
    if not mat or #mat==0 then return end

    Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
    Duel.BreakEffect()

    if Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,true,false,POS_FACEUP)~=0 then
        fc:CompleteProcedure()
        -- +500 ATK/DEF
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(500)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        fc:RegisterEffect(e1,true)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_UPDATE_DEFENSE)
        fc:RegisterEffect(e2,true)

        -- 🔒 Permanent End Phase override
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_CANNOT_TRIGGER)  -- blocks all effects including "return to Extra Deck"
        e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)  -- permanent while on field
        fc:RegisterEffect(e3,true)

        Duel.RegisterFlagEffect(tp,id+1000,RESET_PHASE+PHASE_END,0,1)
    end
end
