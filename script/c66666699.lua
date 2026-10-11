
--Seafarer's Treasure Trove
local s,id=GetID()
local SET_SEAFARER=0x2A99

function s.initial_effect(c)
    --Destroy your other Spell/Traps, then draw
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
end

--Face-up "Seafarer" monsters
function s.cfilter(c)
    return c:IsFaceup()
        and c:IsMonster()
        and c:IsSetCard(SET_SEAFARER)
end

--Must control at least 2 Seafarer monsters
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(
        s.cfilter,tp,LOCATION_MZONE,0,2,nil
    )
end

--Spell/Trap cards you control, except this card
function s.desfilter(c,sc)
    return c~=sc
        and c:IsSpellTrap()
        and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()

    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
            and Duel.IsExistingMatchingCard(
                s.desfilter,tp,LOCATION_ONFIELD,0,1,nil,c
            )
    end

    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,LOCATION_ONFIELD,0,nil,c
    )

    Duel.SetOperationInfo(
        0,CATEGORY_DESTROY,g,#g,tp,LOCATION_ONFIELD
    )
    Duel.SetOperationInfo(
        0,CATEGORY_DRAW,nil,0,tp,#g
    )
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    --Gather all other destructible Spell/Traps
    local g=Duel.GetMatchingGroup(
        s.desfilter,tp,LOCATION_ONFIELD,0,nil,c
    )

    if #g==0 then return end

    --Destroy as many as possible simultaneously
    local ct=Duel.Destroy(g,REASON_EFFECT)

    --Draw exactly 1 card per card destroyed
    if ct>0 then
        Duel.BreakEffect()
        Duel.Draw(tp,ct,REASON_EFFECT)
    end
end
