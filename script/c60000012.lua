-- Restrained Blade Herald
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be Normal Summoned/Set. Must be Special Summoned by a card effect.
	c:EnableUnsummonable()
	--Cannot be targeted by opponent's card effects while Linked
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.tgcon)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	--Destroy opponent's cards
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
-- condition for protection
function s.tgcon(e)
	return e:GetHandler():IsLinked()
end
-- filter for WATER Warrior Link monsters that point to this card
function s.rfilter(c,tc)
	return c:IsFaceup() and c:IsRace(RACE_WARRIOR) and c:IsAttribute(ATTRIBUTE_WATER)
		and c:IsType(TYPE_LINK) and c:GetLinkedGroup():IsContains(tc)
end
-- target
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.rfilter(chkc,c) end
	if chk==0 then 
		-- need a valid WATER Warrior Link pointing at this card
		-- and opponent must control at least 1 card
		return Duel.IsExistingTarget(s.rfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,c)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.rfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,c)
	local ct=g:GetFirst():GetLink()
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,ct,1-tp,LOCATION_ONFIELD)
end
-- operation
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() 
		and tc:GetLinkedGroup():IsContains(c) then
		local ct=tc:GetLink()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,1,ct,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end
