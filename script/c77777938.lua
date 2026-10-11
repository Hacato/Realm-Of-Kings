
--Seafarer's Fleet
local s,id=GetID()
local SET_SEAFARER=0x2A99
local FLAG_FLEET=id

function s.initial_effect(c)
    --Activate only 1 Fleet per turn
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,EFFECT_COUNT_CODE_OATH})
    c:RegisterEffect(e1)

    --Seafarer monsters gain 300 ATK
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e2:SetTarget(s.statfilter)
    e2:SetValue(300)
    c:RegisterEffect(e2)

    --Seafarer monsters gain 300 DEF
    local e3=e2:Clone()
    e3:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e3)

    --Set a Seafarer Spell/Trap from Deck
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1)
    e4:SetTarget(s.decktg)
    e4:SetOperation(s.deckop)
    c:RegisterEffect(e4)

    --Set a Seafarer Spell/Trap from your GY
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_LEAVE_GRAVE)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1)
    e5:SetTarget(s.gytg)
    e5:SetOperation(s.gyop)
    c:RegisterEffect(e5)

    --Set a Spell/Trap from opponent's GY
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_LEAVE_GRAVE)
    e6:SetType(EFFECT_TYPE_IGNITION)
    e6:SetRange(LOCATION_FZONE)
    e6:SetCountLimit(1)
    e6:SetTarget(s.opptg)
    e6:SetOperation(s.oppop)
    c:RegisterEffect(e6)

    --Only WATER monsters can be Special Summoned
    local e7=Effect.CreateEffect(c)
    e7:SetType(EFFECT_TYPE_FIELD)
    e7:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e7:SetRange(LOCATION_FZONE)
    e7:SetTargetRange(1,0)
    e7:SetTarget(s.splimit)
    c:RegisterEffect(e7)
end

function s.statfilter(e,c)
    return c:IsSetCard(SET_SEAFARER)
end

function s.splimit(e,c)
    return not c:IsAttribute(ATTRIBUTE_WATER)
end

--Seafarer Spell/Trap from Deck, except Fleet
function s.deckfilter(c)
    return c:IsSpellTrap()
        and c:IsSetCard(SET_SEAFARER)
        and not c:IsCode(id)
        and not c:IsType(TYPE_FIELD)
        and c:IsSSetable()
end

--Seafarer Spell/Trap from your GY
function s.gyfilter(c)
    return c:IsSpellTrap()
        and c:IsSetCard(SET_SEAFARER)
        and not c:IsType(TYPE_FIELD)
        and c:IsSSetable()
end

--Any non-Field Spell/Trap from opponent's GY
function s.oppfilter(c)
    return c:IsSpellTrap()
        and not c:IsType(TYPE_FIELD)
        and c:IsSSetable()
end

--Block activation of cards marked by Fleet
function s.aclimit(e,re,tp)
    local c=re:GetHandler()
    return re:IsHasType(EFFECT_TYPE_ACTIVATE)
        and c:IsLocation(LOCATION_SZONE)
        and c:GetFlagEffect(FLAG_FLEET)>0
end

--Register the restriction for the current turn
function s.applylimit(e,tp,tc)
    --Mark only this specific card
    tc:RegisterFlagEffect(
        FLAG_FLEET,
        RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,
        0,1
    )

    --Prevent activating marked Spell/Trap cards
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

--Shared Set operation
function s.setcard(e,tp,filter,p)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        filter,tp,
        p==tp and LOCATION_GRAVE or 0,
        p~=tp and LOCATION_GRAVE or 0,
        1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

    local g
    if p==tp then
        g=Duel.SelectMatchingCard(
            tp,filter,tp,LOCATION_GRAVE,0,1,1,nil
        )
    else
        g=Duel.SelectMatchingCard(
            tp,filter,tp,0,LOCATION_GRAVE,1,1,nil
        )
    end

    local tc=g:GetFirst()
    if not tc then return end

    if Duel.SSet(tp,tc)>0 then
        s.applylimit(e,tp,tc)
    end
end

--Set from Deck
function s.decktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(
                s.deckfilter,tp,LOCATION_DECK,0,1,nil
            )
    end
end

function s.deckop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
        return
    end

    if not Duel.IsExistingMatchingCard(
        s.deckfilter,tp,LOCATION_DECK,0,1,nil
    ) then
        return
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(
        tp,s.deckfilter,tp,LOCATION_DECK,0,1,1,nil
    )

    local tc=g:GetFirst()
    if tc and Duel.SSet(tp,tc)>0 then
        s.applylimit(e,tp,tc)
    end
end

--Set from your GY
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(
                s.gyfilter,tp,LOCATION_GRAVE,0,1,nil
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_GRAVE
    )
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    s.setcard(e,tp,s.gyfilter,tp)
end

--Set from opponent's GY
function s.opptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(
                s.oppfilter,tp,0,LOCATION_GRAVE,1,nil
            )
    end

    Duel.SetOperationInfo(
        0,CATEGORY_LEAVE_GRAVE,nil,1,1-tp,LOCATION_GRAVE
    )
end

function s.oppop(e,tp,eg,ep,ev,re,r,rp)
    s.setcard(e,tp,s.oppfilter,1-tp)
end
