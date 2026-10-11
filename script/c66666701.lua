
--Seafarer's Final Voyage
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Activate: Revive 1 Seafarer monster,
    --then optionally Set an opponent's GY Spell/Trap
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    --If this face-down card you control is destroyed:
    --Draw 1 card
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCondition(s.drcon)
    e2:SetTarget(s.drtg)
    e2:SetOperation(s.drop)
    c:RegisterEffect(e2)
end

--Seafarer monsters in your GY
function s.spfilter(c,e,tp)
    return c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Opponent's Spell/Trap cards that can be Set
function s.setfilter(c)
    return c:IsSpellTrap()
        and c:IsSSetable()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsControler(tp)
            and chkc:IsLocation(LOCATION_GRAVE)
            and s.spfilter(chkc,e,tp)
    end

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(
                s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp
            )
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(
        tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp
    )
    Duel.SetOperationInfo(
        0,CATEGORY_SPECIAL_SUMMON,g,1,tp,LOCATION_GRAVE
    )
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()

    if not tc or not tc:IsRelateToEffect(e)
        or not s.spfilter(tc,e,tp) then
        return
    end

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
        return
    end

    --Special Summon the targeted Seafarer
    if Duel.SpecialSummon(
        tc,0,tp,tp,false,false,POS_FACEUP
    )==0 then
        return
    end

    --Optionally Set 1 Spell/Trap from opponent's GY
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        s.setfilter,tp,0,LOCATION_GRAVE,1,nil
    ) then
        return
    end

    if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        return
    end

    Duel.BreakEffect()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(
        tp,s.setfilter,tp,0,LOCATION_GRAVE,1,1,nil
    )
    local sc=g:GetFirst()

    if sc and sc:IsSSetable()
        and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
        Duel.SSet(tp,sc)
    end
end

--Destroyed while face-down under your control
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_DESTROY)
        and c:IsPreviousLocation(LOCATION_ONFIELD)
        and c:IsPreviousPosition(POS_FACEDOWN)
        and c:GetPreviousControler()==tp
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
    end
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Draw(tp,1,REASON_EFFECT)
end
