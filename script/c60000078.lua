--Ultra Instinct Training
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Prevent destruction of Spell cards
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetCondition(s.protcon)
	e2:SetTarget(s.prottg)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--negate attack and destroy
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end
function s.protfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x702) and c:IsLevelAbove(7)
end
function s.protcon(e)
	return Duel.IsExistingMatchingCard(s.protfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.prottg(e,c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local at=Duel.GetAttackTarget()
	return at and at:IsControler(tp) and at:IsSetCard(0x702) and at:IsLevelBelow(7)
end
function s.desfilter(c,tp)
	return c:IsControler(tp)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local at=Duel.GetAttackTarget()
		return at and at:IsOnField() and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_ONFIELD,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateAttack() then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end