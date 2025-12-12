--Welcome to Chaos
--Targets 1 Fusion monster on the field; Special Summons 1 Pendulum monster with an equal or lower Level from your Deck in Defense Position, but it cannot be used as Link Material.
local s,id=GetID()
function s.initial_effect(c)
    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--Check for valid Fusion monster target
function s.tgfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_FUSION)
end

--Check for valid Pendulum monster to summon
function s.spfilter(c,e,tp,lv)
    return c:IsType(TYPE_PENDULUM) and c:IsLevelBelow(lv) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

--Target function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.tgfilter(chkc) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

--Activation function
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local tc=Duel.GetFirstTarget()
    if not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,tc:GetLevel())
    
    if #g>0 then
        local sc=g:GetFirst()
        if Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)~=0 then
            --Cannot be used as Link Material
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetDescription(3312)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
            e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
            e1:SetValue(1)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            sc:RegisterEffect(e1)
        end
    end
end