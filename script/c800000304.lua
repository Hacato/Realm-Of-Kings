
--Qliphort Decatron
--Custom EDOPro script
local s,id=GetID()

function s.initial_effect(c)
    --Pendulum setup
    Pendulum.AddProcedure(c)

    --Pendulum Effect 1:
    --Cannot Special Summon except "Qli" monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+
        EFFECT_FLAG_CANNOT_NEGATE)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetRange(LOCATION_PZONE)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    c:RegisterEffect(e1)

    --Pendulum Effect 2:
    --Additional Normal Summon of a "Qli" monster
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
    e2:SetRange(LOCATION_PZONE)
    e2:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
    e2:SetTarget(s.extg)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    --Monster Effect 1:
    --Special Summon from hand if a face-up Qli
    --monster exists in your Extra Deck
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_SPSUMMON_PROC)
    e3:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e3:SetRange(LOCATION_HAND)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.spcon)
    c:RegisterEffect(e3)

    --Monster Effect 2:
    --Quick Effect: recover Qli and Normal Summon
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)

    --Monster Effect 3:
    --If Tributed: Special Summon opponent's GY monster
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,2))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetProperty(EFFECT_FLAG_DELAY+
        EFFECT_FLAG_CARD_TARGET)
    e5:SetCode(EVENT_RELEASE)
    e5:SetCountLimit(1,{id,2})
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.spop)
    c:RegisterEffect(e5)
end

--Qli archetype
function s.qlifilter(c)
    return c:IsSetCard(0xaa)
end

--Pendulum Special Summon restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsSetCard(0xaa)
end

--Additional Normal Summon target
function s.extg(e,c)
    return c:IsSetCard(0xaa)
end

--Check face-up Qli monster in Extra Deck
function s.exfilter(c)
    return c:IsFaceup() and c:IsMonster()
        and c:IsSetCard(0xaa)
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(
            s.exfilter,tp,LOCATION_EXTRA,0,1,nil)
end

--Quick Effect: retrieve Level 5+ Qli
function s.thfilter(c)
    return c:IsFaceup()
        and c:IsSetCard(0xaa)
        and c:IsMonster()
        and c:IsLevelAbove(5)
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(
            s.thfilter,tp,LOCATION_EXTRA,0,1,nil)
    end
    Duel.SetOperationInfo(
        0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(
        tp,s.thfilter,tp,LOCATION_EXTRA,0,1,1,nil)

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0
        and tc:IsLocation(LOCATION_HAND) then

        Duel.ConfirmCards(1-tp,tc)

        --Immediately Normal Summon the retrieved card
        if Duel.IsPlayerCanSummon(tp)
            and tc:IsSummonable(true,nil) then
            Duel.Summon(tp,tc,true,nil)
        end
    end
end

--Tributed effect: opponent's GY
function s.gyfilter(c,e,tp)
    return c:IsMonster()
        and c:IsCanBeSpecialSummoned(
            e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE)
            and chkc:IsControler(1-tp)
            and s.gyfilter(chkc,e,tp)
    end

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(
                s.gyfilter,tp,0,LOCATION_GRAVE,1,nil,e,tp)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(
        tp,s.gyfilter,tp,0,LOCATION_GRAVE,1,1,nil,e,tp)

    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,g,1,0,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and tc:IsCanBeSpecialSummoned(
            e,0,tp,false,false) then
        Duel.SpecialSummon(
            tc,0,tp,tp,false,false,POS_FACEUP)
    end
end
