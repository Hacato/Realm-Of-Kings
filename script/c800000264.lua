--Sky Striker Mecha - Crab Rocket
local s,id=GetID()

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------
--Activate only if you control no monsters
--in your Main Monster Zones
--------------------------------------------------

function s.cfilter(c)
	return c:GetSequence()<5
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(
		s.cfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

--------------------------------------------------
--Count Spells in your GY
--------------------------------------------------

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
end

--------------------------------------------------
--Target monsters
--------------------------------------------------

function s.desfilter(c)
	return c:IsDestructable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and s.desfilter(chkc)
	end

	local max=1

	if Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)>=3 then
		max=2
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.desfilter,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DESTROY
	)

	local g=Duel.SelectTarget(
		tp,
		s.desfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		1,
		max,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		g:GetCount(),
		0,
		0
	)
end

--------------------------------------------------
--Negate the monster's effects
--------------------------------------------------

function s.disable(c,handler)
	local e1=Effect.CreateEffect(handler)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT|
		RESETS_STANDARD_EXC_GRAVE
	)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(handler)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetReset(
		RESET_EVENT|
		RESETS_STANDARD_EXC_GRAVE
	)
	c:RegisterEffect(e2)
end

--------------------------------------------------
--Resolve
--------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)

	if not g or g:GetCount()==0 then
		return
	end

	local dg=Group.CreateGroup()

	for tc in aux.Next(g) do
		if tc:IsRelateToEffect(e)
			and tc:IsDestructable() then

			--Apply the same style of lingering disable
			--used by Dark Ruler Ha Des
			s.disable(
				tc,
				e:GetHandler()
			)

			dg:AddCard(tc)
		end
	end

	if dg:GetCount()>0 then
		Duel.Destroy(
			dg,
			REASON_EFFECT
		)
	end
end