--Graydimm the Grayscale Shadow
local s,id=GetID()
function s.initial_effect(c)
    --Xyz Summon (2 Level 8 monsters, including a LIGHT Fiend monster)
    Xyz.AddProcedure(c,nil,8,2)
    c:EnableReviveLimit()
    -- Custom material check: must include a LIGHT Fiend
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_MATERIAL_CHECK)
    e0:SetValue(function(e,c)
        local mg=c:GetMaterial()
        if not mg or #mg==0 then return end
        if not mg:IsExists(function(tc) return tc:IsAttribute(ATTRIBUTE_LIGHT) and tc:IsRace(RACE_FIEND) end,1,nil) then
            Duel.SendtoGrave(c,REASON_RULE)
        end
    end)
    c:RegisterEffect(e0)

    -- Track the turn this card was Xyz Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
        local c=e:GetHandler()
        if c:IsSummonType(SUMMON_TYPE_XYZ) then
            c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,Duel.GetTurnCount())
        end
    end)
    c:RegisterEffect(e1)

    --Cannot be used as Link Material the turn it is Xyz Summoned, except for the Link Summon of a "Grayscale" Monster
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    e2:SetValue(function(e,lc,sumtype,tp)
        local c=e:GetHandler()
        local flag=c:GetFlagEffectLabel(id)
        if flag and flag==Duel.GetTurnCount() then
            return not (lc and lc:IsSetCard(0x2410))
        end
        return false
    end)
    c:RegisterEffect(e2)

    -- Special Summon "Grayscale" from GY (once per turn)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)

    -- Redirect effect in GY/banished (once per turn)
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetCondition(s.redircon)
    e4:SetCost(s.redircost)
    e4:SetOperation(s.redirop)
    c:RegisterEffect(e4,false,REGISTER_FLAG_DETACH_XMAT)
end
s.listed_series={0x2410}

--Special Summon cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Special Summon target
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2410) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Redirect effect in GY/banished
function s.redircon(e,tp,eg,ep,ev,re,r,rp)
    if not re then return false end
    local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
    return rp==1-tp and (loc==LOCATION_GRAVE or loc==LOCATION_REMOVED)
end
function s.redircost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.redirop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.ChangeChainOperation(ev,s.neweffect)
end

--The new effect that replaces the original
function s.neweffect(e,tp,eg,ep,ev,re,r,rp)
    -- Opponent Special Summons 1 "Grayscale" monster from their GY to a zone a "Grayscale" Link Monster they control points to
    local p=1-tp
    local g1=Duel.GetMatchingGroup(function(c,e,p)
        return c:IsSetCard(0x2410) and c:IsCanBeSpecialSummoned(e,0,p,false,false)
    end,p,LOCATION_GRAVE,0,nil,e,p)
    local g2=Duel.GetMatchingGroup(function(c)
        return c:IsSetCard(0x2410) and c:IsType(TYPE_LINK) and c:IsFaceup()
    end,p,LOCATION_MZONE,0,nil)
    if #g1>0 and #g2>0 then
        Duel.Hint(HINT_SELECTMSG,p,HINTMSG_SPSUMMON)
        local sg=g1:Select(p,1,1,nil)
        Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TARGET)
        local tg=g2:Select(p,1,1,nil)
        local tc=tg:GetFirst()
        local zones=tc:GetLinkedZone(p) & 0x1f  -- Only main monster zones
        local sc=sg:GetFirst()
        if zones~=0 and sc:IsCanBeSpecialSummoned(e,0,p,false,false,POS_FACEUP,p,zones) then
            Duel.SpecialSummon(sc,0,p,p,false,false,POS_FACEUP,zones)
        end
    end
end