--Grayterror the Grayscale Beast
local s,id=GetID()
function s.initial_effect(c)
    --Link Summon (2+ LIGHT Fiend monsters, must include a "Grayscale")
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,2,99,s.lcheck)
    -- Store the turn this card was Link Summoned
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
    --Cannot be used as Link Material the turn it is Link Summoned, except for the Link Summon of a "Grayscale" Monster.
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    e1:SetValue(function(e,lc,sumtype,tp)
        local c=e:GetHandler()
        local flag=c:GetFlagEffectLabel(id)
        -- Only restrict during the turn it was Link Summoned
        if flag and flag==Duel.GetTurnCount() then
            -- Only allow as Link Material for "Grayscale" monster this turn
            return not (lc and lc:IsSetCard(0x2410))
        end
        return false
    end)
    c:RegisterEffect(e1)
    --ATK boost for Grayscale monsters
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x2410))
    e2:SetValue(800)
    c:RegisterEffect(e2)
    --Quick Effect to change opponent's monster effect
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end
s.listed_series={0x2410}

function s.matfilter(c,lc,sumtype,tp)
    return c:IsRace(RACE_FIEND,lc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_LIGHT,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(Card.IsSetCard,1,nil,0x2410)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local lg=e:GetHandler():GetLinkedGroup()
    if chk==0 then return lg:IsExists(s.tribfilter,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local g=lg:FilterSelect(tp,s.tribfilter,1,1,nil)
    Duel.Release(g,REASON_COST)
end
function s.tribfilter(c)
    return c:IsSetCard(0x2410) and c:IsReleasable()
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_CARD,0,id)
    Duel.ChangeChainOperation(ev,s.newop)
end

function s.newop(e,tp,eg,ep,ev,re,r,rp)
    -- Opponent Special Summons 1 "Grayscale" monster from their hand or GY, then can attach 1 monster from either GY to a "Grayscale" Xyz Monster they control
    local p=1-tp
    local g=Duel.GetMatchingGroup(s.spfilter,p,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,p)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,p,HINTMSG_SPSUMMON)
        local sg=g:Select(p,1,1,nil)
        if Duel.SpecialSummon(sg,0,p,p,false,false,POS_FACEUP)>0 then
            local xyzg=Duel.GetMatchingGroup(s.xyzfilter,p,LOCATION_MZONE,0,nil)
            local matg=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE,LOCATION_GRAVE,nil,TYPE_MONSTER)
            if #xyzg>0 and #matg>0 and Duel.SelectYesNo(p,aux.Stringid(id,0)) then
                Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TARGET)
                local xyz=xyzg:Select(p,1,1,nil):GetFirst()
                Duel.Hint(HINT_SELECTMSG,p,HINTMSG_XMATERIAL)
                local mat=matg:Select(p,1,1,nil):GetFirst()
                Duel.Overlay(xyz,mat)
            end
        end
    end
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x2410) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.xyzfilter(c)
    return c:IsSetCard(0x2410) and c:IsType(TYPE_XYZ) and c:IsFaceup()
end