-- Grayscale Awakening: Eclipse!
-- Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	-- ATK reduction aura
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	-- Once per turn choice effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DRAW+CATEGORY_TOGRAVE+CATEGORY_LEAVE_GRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
s.listed_series={0x2410}
function s.atkval(e,c)
	if c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_FIEND) then
		return 0
	end
	return -800
end
function s.grayscale_filter(c)
	return c:IsSetCard(0x2410) and c:IsMonster()
end
function s.stfilter(c)
	return c:IsSetCard(0x2410) and c:IsSpellTrap() and not c:IsCode(id) and c:IsSSetable()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local b1=Duel.IsExistingMatchingCard(s.grayscale_filter,tp,LOCATION_HAND,0,1,nil) and Duel.IsPlayerCanDraw(tp,1)
		local b2=Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.stfilter),tp,LOCATION_GRAVE,0,1,nil)
		return b1 or b2
	end
	local b1=Duel.IsExistingMatchingCard(s.grayscale_filter,tp,LOCATION_HAND,0,1,nil) and Duel.IsPlayerCanDraw(tp,1)
	local b2=Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.stfilter),tp,LOCATION_GRAVE,0,1,nil)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=0
		Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=1
		Duel.SelectOption(tp,aux.Stringid(id,2))
	end
	e:SetLabel(op)
	if op==0 then
		e:SetCategory(CATEGORY_DRAW+CATEGORY_TOGRAVE)
	else
		e:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_TOGRAVE)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		if Duel.DiscardHand(tp,s.grayscale_filter,1,1,REASON_EFFECT+REASON_DISCARD,nil)==0 then return end
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	else
		if Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD,nil)==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
		local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.stfilter),tp,LOCATION_GRAVE,0,1,1,nil):GetFirst()
		if tc then
			Duel.SSet(tp,tc)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end