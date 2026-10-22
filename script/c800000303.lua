
--Lee the World Chalice Fairy of Legacy
--LIGHT / Fairy / Effect
--ATK 100 / DEF 2000

local s,id=GetID()

local SET_WORLD_LEGACY=0xfe

function s.initial_effect(c)
    --Send 1 World Legacy monster from Deck
    --Special Summon Lee and copy its effects
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --If sent from field to GY:
    --Recover World Legacy, then optionally Normal Summon
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

s.listed_series={SET_WORLD_LEGACY}

--========================================
--EFFECT 1: SPECIAL SUMMON AND COPY EFFECTS
--========================================

function s.spfilter(c)
    return c:IsSetCard(SET_WORLD_LEGACY)
        and c:IsMonster()
        and c:IsAbleToGrave()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(
                s.spfilter,tp,LOCATION_DECK,0,1,nil)
    end

    Duel.SetOperationInfo(
        0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

    local g=Duel.SelectMatchingCard(
        tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil)

    local tc=g:GetFirst()
    if not tc then return end

    --Send to GY as EFFECT, not cost
    if Duel.SendtoGrave(tc,REASON_EFFECT)==0 then
        return
    end

    if not tc:IsLocation(LOCATION_GRAVE) then
        return
    end

    if not c:IsRelateToEffect(e)
        or not c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
        or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    --Special Summon Lee
    if Duel.SpecialSummon(
        c,0,tp,tp,false,false,POS_FACEUP)>0 then

        --Copy effects of sent World Legacy monster
        local code=tc:GetOriginalCode()
        c:CopyEffect(
            code,RESET_EVENT|RESETS_STANDARD)
    end
end

--========================================
--EFFECT 2: RECOVER WORLD LEGACY
--========================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(
        LOCATION_ONFIELD)
end

function s.thfilter(c)
    return c:IsSetCard(SET_WORLD_LEGACY)
        and c:IsMonster()
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE)
            and chkc:IsControler(tp)
            and s.thfilter(chkc)
    end

    if chk==0 then
        return Duel.IsExistingTarget(
            s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

    local g=Duel.SelectTarget(
        tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)

    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,g,1,0,0)
end

--========================================
--NO-TRIBUTE NORMAL SUMMON PROCEDURE
--Same method as World Chalice - Starry Night
--========================================

function s.ntcon(e,c,minc)
    if c==nil then return true end
    return minc==0
        and Duel.GetLocationCount(
            c:GetControler(),LOCATION_MZONE)>0
end

--========================================
--RECOVER AND OPTIONAL NORMAL SUMMON
--========================================

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e) then
        return
    end

    --Add targeted World Legacy monster to hand
    if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
        return
    end

    if not tc:IsLocation(LOCATION_HAND)
        or not tc:IsControler(tp) then
        return
    end

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    --====================================
    --LEVEL 5 OR HIGHER
    --NORMAL SUMMON WITHOUT TRIBUTING
    --====================================

    if tc:IsLevelAbove(5) then

        --Register temporary no-Tribute
        --Normal Summon procedure
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
        e1:SetCode(EFFECT_SUMMON_PROC)
        e1:SetCondition(s.ntcon)
        e1:SetReset(RESET_EVENT|RESETS_STANDARD)
        tc:RegisterEffect(e1)

        --Check and offer optional Summon
        if tc:IsSummonable(true,e1)
            and Duel.SelectYesNo(
                tp,aux.Stringid(id,2)) then

            --Use the no-Tribute procedure directly
            Duel.Summon(tp,tc,true,e1)
        end

        --Remove unused procedure
        if tc:IsLocation(LOCATION_HAND) then
            e1:Reset()
        end

    else

        --================================
        --LEVEL 4 OR LOWER
        --NORMAL SUMMON NORMALLY
        --================================

        if tc:IsSummonable(true,nil)
            and Duel.SelectYesNo(
                tp,aux.Stringid(id,2)) then

            --Extra Normal Summon
            Duel.Summon(tp,tc,true,nil)
        end
    end
end
