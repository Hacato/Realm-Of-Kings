--Sky Striker Ace - Izumi
local s,id=GetID()

local SET_SKY_STRIKER=0x115
local SET_SKY_STRIKER_ACE=0x1115

function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(
		c,
		s.xyzfilter,
		4,
		2,
		s.ovfilter,
		aux.Stringid(id,0),
		2
	)

	--You can only Special Summon "Sky Striker Ace - Izumi(s)" once per turn
	c:SetSPSummonOnce(id)

	--Once per turn (Quick Effect):
	--Detach 1 material; negate face-up cards your opponent controls
	--up to the number of "Sky Striker" Spells in your GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER|TIMING_MAIN_END)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--Double the original ATK of a "Sky Striker Ace" Link Monster
	--that was Link Summoned using this card as material
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Xyz Summon
-- 2 Level 4 "Sky Striker" monsters
--------------------------------------------------

function s.xyzfilter(c,xyzc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER)
end

--------------------------------------------------
-- Alternative Xyz Summon
-- Use 1 WATER "Sky Striker" Link Monster you control
--------------------------------------------------

function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER)
		and c:IsAttribute(ATTRIBUTE_WATER)
		and c:IsType(TYPE_LINK)
end

--------------------------------------------------
-- Quick Effect cost
-- Detach 1 material
--------------------------------------------------

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

--------------------------------------------------
-- Count "Sky Striker" Spells in your GY
--------------------------------------------------

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
		and c:IsSetCard(SET_SKY_STRIKER)
end

--------------------------------------------------
-- Negate target check
--------------------------------------------------

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if chk==0 then
		return ct>0
			and Duel.IsExistingMatchingCard(
				Card.IsFaceup,
				tp,
				0,
				LOCATION_ONFIELD,
				1,
				nil
			)
	end
end

--------------------------------------------------
-- Negate face-up opponent cards
--------------------------------------------------

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if ct<=0 then
		return
	end

	local g=Duel.GetMatchingGroup(
		Card.IsFaceup,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if g:GetCount()==0 then
		return
	end

	local max=math.min(ct,g:GetCount())

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_FACEUP
	)

	local sg=g:Select(
		tp,
		1,
		max,
		nil
	)

	for tc in aux.Next(sg) do
		--Negate card
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(
			RESET_EVENT|
			RESETS_STANDARD|
			RESET_PHASE|
			PHASE_END
		)
		tc:RegisterEffect(e1)

		--Negate activated effects
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
	end
end

--------------------------------------------------
-- Double original ATK of a "Sky Striker Ace"
-- Link Monster that used Izumi as Link Material
--------------------------------------------------

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if (r&REASON_LINK)==0 then
		return false
	end

	local rc=c:GetReasonCard()

	return rc
		and rc:IsType(TYPE_LINK)
		and rc:IsSetCard(SET_SKY_STRIKER_ACE)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc
		or not rc:IsFaceup()
		or not rc:IsType(TYPE_LINK)
		or not rc:IsSetCard(SET_SKY_STRIKER_ACE) then
		return
	end

	local atk=rc:GetBaseAttack()

	local e1=Effect.CreateEffect(rc)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(atk*2)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)
end