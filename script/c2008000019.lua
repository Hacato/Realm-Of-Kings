--Ragnaraika Legion Devourer
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
    --spsumm count limit
    c:SetSPSummonOnce(id)
	--link summon
	Link.AddProcedure(c,s.matfilter,2)
	c:EnableReviveLimit()
	--opp cannot act cs/effs after its Link Summ during your turn
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.actcon)
    e1:SetOperation(s.actop)
    c:RegisterEffect(e1)
    --gain atk
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_SET_BASE_ATTACK)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)
    --Attack directly
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_DIRECT_ATTACK)
    c:RegisterEffect(e3)
    --halve its original ATK to neg the effs of the opp's cs
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_DISABLE)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1)
    e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e4:SetCost(s.discost)
	e4:SetTarget(s.distg)
	e4:SetOperation(s.disop)
    c:RegisterEffect(e4)
end
s.listed_series={SET_RAGNARAIKA}
s.listed_names={id}
function s.matfilter(c,lc,sumtype,tp)--link mats
	return c:IsType(TYPE_LINK,lc,sumtype,tp) and c:IsSetCard(SET_RAGNARAIKA,lc,sumtype,tp)
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)--opp cannot act cs/effs after its Link Summ during your turn
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK) and e:GetHandler():IsControler(tp)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(0,1)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
    return true
end
function s.atkval(e,c)--gain atk
    return c:GetMaterialCount()*2000
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)--halve its original ATK to neg the effs of the opp's cs
    local c=e:GetHandler()
    if chk==0 then return c:GetBaseAttack()>0 end
    -- Halve original ATK
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(c:GetBaseAttack()/2)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsNegatable,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.SetChainLimit(aux.FALSE)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsNegatable,tp,0,LOCATION_ONFIELD,nil)
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
		end
	end
end