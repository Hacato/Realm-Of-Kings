--Yoshiie Formation: Iron Wall
--Scripted by Assistant
local s,id=GetID()
function s.initial_effect(c)
	--Activation condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.actcon)
	c:RegisterEffect(e1)
	
	--Indestructible count protection
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.indtg)
	e2:SetValue(s.indct)
	c:RegisterEffect(e2)
	
	--Quick Effect negation
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
end

s.listed_series={0x2408}

--Activation condition: control a "Yoshiie" Synchro Monster
function s.actfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2408) and c:IsType(TYPE_SYNCHRO)
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Target for protection effects
function s.indtg(e,c)
	return c:IsSetCard(0x2408)
end

--Indestructible count (once per turn each)
function s.indct(e,re,r,rp)
	if (r&REASON_BATTLE+REASON_EFFECT)~=0 then
		return 1
	else 
		return 0 
	end
end

--Condition for Quick Effect negation
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if ep==tp or not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsExists(s.negfilter,1,nil,tp)
end

--Filter for targeted "Yoshiie" cards
function s.negfilter(c,tp)
	return c:IsControler(tp) and c:IsSetCard(0x2408) and c:IsLocation(LOCATION_ONFIELD)
end

--Target for negation effect
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

--Operation for negation effect
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end