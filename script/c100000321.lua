--Puzzle HERO TamperTime
local s,id=GetID()
function s.initial_effect(c)
    --Return Extra Deck monster and summon materials
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOEXTRA+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

--Tribute cost
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

--Target filter for Extra Deck monsters
function s.filter(c,e,tp)
    if not (c:IsFaceup() and c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK) and c:IsAbleToExtra()) then return false end
    local mg=nil
    if c:IsType(TYPE_FUSION) then
        mg=c:GetMaterial()
    elseif c:IsType(TYPE_SYNCHRO) then
        mg=c:GetMaterial()
    elseif c:IsType(TYPE_XYZ) then
        mg=c:GetOverlayGroup()
    elseif c:IsType(TYPE_LINK) then
        mg=c:GetMaterial()
    end
    return mg and mg:FilterCount(s.mgfilter,nil,e,tp,#mg)==#mg 
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>=#mg-1
end

--Filter for materials in GY
function s.mgfilter(c,e,tp,ct)
    return c:IsLocation(LOCATION_GRAVE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and (ct==1 or Duel.IsPlayerCanSpecialSummonCount(tp,ct))
end

--Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc,e,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,g,1,0,0)
    
    local mg=nil
    local tc=g:GetFirst()
    if tc:IsType(TYPE_FUSION) then
        mg=tc:GetMaterial()
    elseif tc:IsType(TYPE_SYNCHRO) then
        mg=tc:GetMaterial()
    elseif tc:IsType(TYPE_XYZ) then
        mg=tc:GetOverlayGroup()
    elseif tc:IsType(TYPE_LINK) then
        mg=tc:GetMaterial()
    end
    
    if mg then
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,mg,#mg,tp,LOCATION_GRAVE)
    end
end

--Operation
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    
    local mg=nil
    if tc:IsType(TYPE_FUSION) then
        mg=tc:GetMaterial()
    elseif tc:IsType(TYPE_SYNCHRO) then
        mg=tc:GetMaterial()
    elseif tc:IsType(TYPE_XYZ) then
        mg=tc:GetOverlayGroup()
    elseif tc:IsType(TYPE_LINK) then
        mg=tc:GetMaterial()
    end
    
    if not mg or mg:FilterCount(aux.NecroValleyFilter(s.mgfilter),nil,e,tp,#mg)~=#mg 
        or Duel.GetLocationCount(tp,LOCATION_MZONE)<#mg then return end
    
    if Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_EXTRA) then
        local sg=mg:Filter(aux.NecroValleyFilter(s.mgfilter),nil,e,tp,#mg)
        if #sg>0 then
            Duel.BreakEffect()
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end