--Sky Striker Ace - Arashi
local s,id=GetID()

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

	--You can only Special Summon "Sky Striker Ace - Arashi(s)" once per turn
	c:SetSPSummonOnce(id)

	--Once per turn: Detach 1 material, then target 1 card
	--your opponent controls; return it to the hand.
	--If it was not returned by this effect, inflict 1000 damage.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--A "Sky Striker Ace" monster Link Summoned using this card
	--as material can make a second attack during each Battle Phase
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Xyz Summon
-- 2 Level 4 "Sky Striker Ace" monsters
--------------------------------------------------

function s.xyzfilter(c,xyzc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
-- Alternative Xyz Summon
-- Use 1 WIND "Sky Striker Ace" Link Monster
--------------------------------------------------

function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
		and c:IsAttribute(ATTRIBUTE_WIND)
		and c:IsType(TYPE_LINK)
end

--------------------------------------------------
-- Bounce effect cost
-- Detach 1 material
--------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
-- Target 1 card your opponent controls
--------------------------------------------------

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			Card.IsAbleToHand,
			tp,
			0,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RTOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		Card.IsAbleToHand,
		tp,
		0,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DAMAGE,
		nil,
		0,
		1-tp,
		1000
	)
end

--------------------------------------------------
-- Return target to hand.
-- If it was not returned by this effect,
-- inflict 1000 damage.
--------------------------------------------------

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local returned=false

	if tc and tc:IsRelateToEffect(e) then
		local res=Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)

		if res>0 and tc:IsLocation(LOCATION_HAND) then
			returned=true
		end
	end

	if not returned then
		Duel.Damage(
			1-tp,
			1000,
			REASON_EFFECT
		)
	end
end

--------------------------------------------------
-- Used as Link Material for a "Sky Striker Ace"
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

--------------------------------------------------
-- Give the Link Monster 1 additional attack
-- during each Battle Phase
--------------------------------------------------

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc
		or not rc:IsFaceup()
		or not rc:IsType(TYPE_LINK)
		or not rc:IsSetCard(SET_SKY_STRIKER_ACE) then
		return
	end

	local e1=Effect.CreateEffect(rc)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)
end