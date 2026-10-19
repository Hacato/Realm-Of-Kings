
--World Chalice Vanguards
--Card ID: 800000296
local s,id=GetID()
local SET_WORLD_CHALICE=0xfd

function s.initial_effect(c)
    c:EnableReviveLimit()

    --Link Summon: 2-3 monsters, including
    --a "World Chalice" Normal Monster.
    --Tokens cannot be used.
    Link.AddProcedure(c,s.matfilter,2,3,s.lcheck)

    --Allow Normal Monsters in hand as Link Material
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET+
        EFFECT_FLAG_CANNOT_DISABLE)
    e0:SetCode(EFFECT_EXTRA_MATERIAL)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetTargetRange(1,0)
    e0:SetOperation(s.extraop)
    e0:SetValue(s.extraval)
    c:RegisterEffect(e0)

    --You can only control 1 "World Chalice Vanguards"
    c:SetUniqueOnField(1,0,id)

    --Quick Effect during opponent's turn
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+
        CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

--==================================
-- LINK SUMMON MATERIALS
--==================================

function s.matfilter(c,lc,sumtype,tp)
    return not c:IsType(TYPE_TOKEN)
end

function s.chalicefilter(c)
    return c:IsSetCard(SET_WORLD_CHALICE)
        and c:IsType(TYPE_NORMAL)
        and not c:IsType(TYPE_TOKEN)
end

function s.fieldfilter(c,tp)
    return c:IsLocation(LOCATION_MZONE)
        and c:IsControler(tp)
end

function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(s.chalicefilter,1,nil)
        and g:IsExists(s.fieldfilter,1,nil,tp)
end

--==================================
-- HAND MATERIALS
--==================================

function s.handfilter(c)
    return c:IsType(TYPE_MONSTER)
        and c:IsType(TYPE_NORMAL)
        and not c:IsType(TYPE_TOKEN)
end

function s.extraop(c,e,tp,sg,mg,lc,og,chk)
    return sg:IsExists(s.fieldfilter,1,nil,tp)
end

function s.extraval(chk,summon_type,e,...)
    if chk==0 then
        local tp,sc=...

        if summon_type~=SUMMON_TYPE_LINK
            or sc~=e:GetHandler() then
            return Group.CreateGroup()
        end

        return Duel.GetMatchingGroup(
            s.handfilter,tp,LOCATION_HAND,0,nil)
    end
end

--==================================
-- QUICK EFFECT CONDITION
--==================================

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetTurnPlayer()~=tp
end

--==================================
-- GRAVEYARD LINK MONSTERS
--==================================

function s.gyfilter(c)
    return c:IsType(TYPE_LINK)
        and c:IsAbleToExtra()
end

--Count Link Monsters with different names
function s.hasmaterials(tp,ct)
    local g=Duel.GetMatchingGroup(
        s.gyfilter,tp,LOCATION_GRAVE,0,nil)

    local names={}
    local count=0

    for tc in g:Iter() do
        local code=tc:GetCode()

        if not names[code] then
            names[code]=true
            count=count+1
        end
    end

    return count>=ct
end

--==================================
-- EXTRA DECK FILTER
--==================================

function s.exfilter(c,e,tp)
    return c:IsType(TYPE_LINK)
        and not c:IsAttribute(ATTRIBUTE_DARK)
        and c:IsCanBeSpecialSummoned(
            e,SUMMON_TYPE_LINK,tp,false,false)
        and s.hasmaterials(tp,c:GetLink())
end

--==================================
-- EFFECT TARGET
--==================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.exfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
            and Duel.GetLocationCountFromEx(tp,tp,nil)>0
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--==================================
-- SELECT DIFFERENT-NAMED LINKS
--==================================

function s.selectdifferent(tp,ct)
    local pool=Duel.GetMatchingGroup(
        s.gyfilter,tp,LOCATION_GRAVE,0,nil)

    local selected=Group.CreateGroup()
    local used={}

    for i=1,ct do
        local available=pool:Filter(
            function(c)
                return not used[c:GetCode()]
            end,nil)

        if #available==0 then
            return nil
        end

        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)

        --Corrected: fourth parameter added
        local tc=available:Select(tp,1,1,nil):GetFirst()

        if not tc then
            return nil
        end

        selected:AddCard(tc)
        used[tc:GetCode()]=true
        pool:RemoveCard(tc)
    end

    return selected
end

--==================================
-- EFFECT RESOLUTION
--==================================

function s.operation(e,tp,eg,ep,ev,re,r,rp)

    --Find eligible non-DARK Link Monsters
    local g=Duel.GetMatchingGroup(
        s.exfilter,tp,LOCATION_EXTRA,0,nil,e,tp)

    if #g==0 then
        return
    end

    --Select the Link Monster to reveal
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

    --Corrected: fourth parameter added
    local sc=g:Select(tp,1,1,nil):GetFirst()

    if not sc then
        return
    end

    --Reveal the selected Link Monster
    Duel.ConfirmCards(1-tp,Group.FromCards(sc))

    local ct=sc:GetLink()

    --Select Link Monsters with different names
    local sg=s.selectdifferent(tp,ct)

    if not sg or #sg~=ct then
        return
    end

    --Return selected monsters to the Extra Deck
    local returned=Duel.SendtoDeck(
        sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)

    if returned~=ct then
        return
    end

    --Check Extra Monster Zone availability
    if Duel.GetLocationCountFromEx(tp,tp,nil,sc)<=0 then
        return
    end

    if not sc:IsCanBeSpecialSummoned(
        e,SUMMON_TYPE_LINK,tp,false,false) then
        return
    end

    --Special Summon treated as a Link Summon
    if Duel.SpecialSummon(
        sc,SUMMON_TYPE_LINK,tp,tp,
        false,false,POS_FACEUP)>0 then
        sc:CompleteProcedure()
    end
end
