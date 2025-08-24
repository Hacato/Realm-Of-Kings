--Aquamarine Bubble Surge
--Continuous Trap Card
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Main Phase effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.condition)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
s.listed_series={0x30cd}

function s.cfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsAttribute(ATTRIBUTE_WATER)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.stfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	--Count distinct names manually
	local names={}
	local ct=0
	local tc=g:GetFirst()
	while tc do
		local code=tc:GetCode()
		if not names[code] then
			names[code]=true
			ct=ct+1
		end
		tc=g:GetNext()
	end
	if chkc then
		return (chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(1-tp) and s.stfilter(chkc))
			or (chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup())
	end
	if chk==0 then
		return ct>0 and (Duel.IsExistingTarget(s.stfilter,tp,0,LOCATION_ONFIELD,1,nil)
			or Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil))
	end
	local b1=Duel.IsExistingTarget(s.stfilter,tp,0,LOCATION_ONFIELD,1,nil)
	local b2=Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))+1
	elseif b1 then
		op=1
	else
		op=2
	end
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_DESTROY)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local tg=Duel.SelectTarget(tp,s.stfilter,tp,0,LOCATION_ONFIELD,1,ct,nil)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,tg,tg:GetCount(),0,0)
	else
		e:SetCategory(CATEGORY_TOHAND)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local tg=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,ct,nil)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,tg,tg:GetCount(),0,0)
	end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetTargetCards(e)
	if g:GetCount()>0 then
		if e:GetLabel()==1 then
			Duel.Destroy(g,REASON_EFFECT)
		else
			Duel.SendtoHand(g,nil,REASON_EFFECT)
		end
	end
end