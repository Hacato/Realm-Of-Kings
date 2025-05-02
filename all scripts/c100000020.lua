--Galaxy Tachyon Dragon
--Xyz monster with 2 Level 4 monsters as materials
local s,id=GetID()
function s.initial_effect(c)
    --Xyz summon procedure
    Xyz.AddProcedure(c,nil,4,2)
    c:EnableReviveLimit()
    
    --Opponent's monsters lose 500 ATK
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(0,LOCATION_MZONE)
    e1:SetValue(-500)
    c:RegisterEffect(e1)
    
    --Special Summon Level 4 or 8 Dragon monster
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,0})
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
    
    --Change Level of summoned Dragon monster
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.lvcon)
    e3:SetTarget(s.lvtg)
    e3:SetOperation(s.lvop)
    c:RegisterEffect(e3)
end

--Cost for Special Summon effect
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Target for Special Summon effect
function s.spfilter(c,e,tp)
    return c:IsRace(RACE_DRAGON) and (c:IsLevel(4) or c:IsLevel(8)) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

--Operation for Special Summon effect
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

--Condition for Level change effect
function s.lvfilter(c,tp)
    return c:IsRace(RACE_DRAGON) and c:HasLevel() and c:IsFaceup() and c:IsControler(tp)
end

function s.lvcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.lvfilter,1,nil,tp)
end

--Target for Level change effect
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() and chkc:IsRace(RACE_DRAGON) and chkc:HasLevel() and chkc:IsControler(tp) end
    local g=eg:Filter(s.lvfilter,nil,tp)
    if chk==0 then return #g>0 end
    
    if #g==1 then
        Duel.SetTargetCard(g:GetFirst())
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
        local sg=g:Select(tp,1,1,nil)
        Duel.SetTargetCard(sg)
    end
end

--Operation for Level change effect
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() or not tc:HasLevel() then return end
    
    -- Check current level and determine options
    local lv=0
    if tc:IsLevel(4) then
        -- If already level 4, can only choose level 8
        Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,3)) -- "Make Level 8" message
        lv=8
    elseif tc:IsLevel(8) then
        -- If already level 8, can only choose level 4
        Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,2)) -- "Make Level 4" message
        lv=4
    else
        -- If neither level 4 nor 8, let player choose
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LVRANK)
        local sel=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
        lv=sel==0 and 4 or 8
    end
    
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CHANGE_LEVEL)
    e1:SetValue(lv)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)
end