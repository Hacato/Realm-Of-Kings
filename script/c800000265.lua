--Sky Striker Maneuver - Warp Drive
local s,id=GetID()

local SET_SKY_STRIKER=0x115

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
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
--Target filters
--------------------------------------------------

function s.xyzfilter(c)
	return c:IsFaceup()
		and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsType(TYPE_XYZ)
		and c:IsSetCard(SET_SKY_STRIKER)
end

function s.oppfilter(c)
	return c:IsFaceup()
		and c:IsControler(1-tp)
		and c:IsLocation(LOCATION_MZONE)
end

--------------------------------------------------
--Target 1 Sky Striker Xyz you control
--and 1 face-up opponent's monster
--------------------------------------------------

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return false
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			function(c)
				return c:IsFaceup()
					and c:IsType(TYPE_XYZ)
					and c:IsSetCard(SET_SKY_STRIKER)
			end,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
		and Duel.IsExistingTarget(
			Card.IsFaceup,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	--Select your Sky Striker Xyz Monster
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local g1=Duel.SelectTarget(
		tp,
		function(c)
			return c:IsFaceup()
				and c:IsType(TYPE_XYZ)
				and c:IsSetCard(SET_SKY_STRIKER)
		end,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	--Select opponent's face-up monster
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local g2=Duel.SelectTarget(
		tp,
		Card.IsFaceup,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	g1:Merge(g2)
end

--------------------------------------------------
--Count Spells in your GY
--------------------------------------------------

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
end

--------------------------------------------------
--Resolve
--------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)

	if not g or g:GetCount()~=2 then
		return
	end

	local xyz=nil
	local opp=nil

	for tc in aux.Next(g) do
		if tc:IsControler(tp)
			and tc:IsFaceup()
			and tc:IsType(TYPE_XYZ)
			and tc:IsSetCard(SET_SKY_STRIKER) then
			xyz=tc
		elseif tc:IsControler(1-tp)
			and tc:IsFaceup()
			and tc:IsLocation(LOCATION_MZONE) then
			opp=tc
		end
	end

	if not xyz
		or not opp
		or not xyz:IsRelateToEffect(e)
		or not opp:IsRelateToEffect(e) then
		return
	end

	--------------------------------------------------
	--Attach opponent's monster as Xyz Material
	--------------------------------------------------

	Duel.Overlay(
		xyz,
		Group.FromCards(opp)
	)

	--------------------------------------------------
	--If you have 3 or more Spells in your GY,
	--you can banish 1 random card from
	--your opponent's hand face-down
	--------------------------------------------------

	if Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)<3 then
		return
	end

	if Duel.GetFieldGroupCount(
		1-tp,
		LOCATION_HAND,
		0
	)==0 then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,1)
	) then
		return
	end

	local hg=Duel.GetFieldGroup(
		1-tp,
		LOCATION_HAND,
		0
	)

	local rg=hg:RandomSelect(
		tp,
		1
	)

	Duel.Remove(
		rg,
		POS_FACEDOWN,
		REASON_EFFECT
	)
end