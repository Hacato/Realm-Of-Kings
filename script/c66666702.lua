
--Seafarer's Last Stand
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Set as many "Seafarer" Spell/Trap cards
    --from your GY as possible
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.settg)
    e1:SetOperation(s.setop)
    c:RegisterEffect(e1)
end

--Seafarer Spell/Trap cards that can be Set
function s.setfilter(c)
    return c:IsSpellTrap()
        and c:IsSetCard(SET_SEAFARER)
        and not c:IsType(TYPE_FIELD)
        and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)

    if chk==0 then
        return ft>0
            and Duel.IsExistingMatchingCard(
                s.setfilter,tp,LOCATION_GRAVE,0,1,nil
            )
    end

    local ct=math.min(
        ft,
        Duel.GetMatchingGroupCount(
            s.setfilter,tp,LOCATION_GRAVE,0,nil
        )
    )

    Duel.SetOperationInfo(
        0,CATEGORY_LEAVE_GRAVE,nil,ct,tp,LOCATION_GRAVE
    )
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
    if ft<=0 then return end

    local g=Duel.GetMatchingGroup(
        s.setfilter,tp,LOCATION_GRAVE,0,nil
    )

    if #g==0 then return end

    --Set as many as possible, up to available zones
    local ct=math.min(ft,#g)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,ct,ct,nil)
    if #sg==0 then return end

    --Set the selected Seafarer Spell/Trap cards
    Duel.SSet(tp,sg)
end
