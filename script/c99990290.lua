--SAO Phantom Bullet
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	--Negate activation
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--ACTIVATION CONDITION
--When your opponent activates a card or effect.
----------------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
end

----------------------------------------------------------
--COST OPTION 1
--Send 1 "SAO" monster from the hand or
--face-up from your field to the GY.
----------------------------------------------------------

function s.negcostfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
		and c:IsAbleToGraveAsCost()
end

----------------------------------------------------------
--COST
--Choose between:
--A) Send 1 SAO monster
--B) Remove 2 En-Counters
----------------------------------------------------------

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local can_send=Duel.IsExistingMatchingCard(
		s.negcostfilter,
		tp,
		LOCATION_HAND+LOCATION_MZONE,
		0,
		1,
		nil
	)

	local can_counter=Duel.IsCanRemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)

	if chk==0 then
		return can_send or can_counter
	end

	------------------------------------------------------
	--If both costs are available, let the player choose.
	--
	--String 1:
	--"Remove 2 En-Counters instead?"
	------------------------------------------------------

	if can_send and can_counter then
		if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.RemoveCounter(
				tp,
				1,
				0,
				COUNTER_EN,
				2,
				REASON_COST
			)
		else
			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_TOGRAVE
			)

			local g=Duel.SelectMatchingCard(
				tp,
				s.negcostfilter,
				tp,
				LOCATION_HAND+LOCATION_MZONE,
				0,
				1,
				1,
				nil
			)

			Duel.SendtoGrave(
				g,
				REASON_COST
			)
		end

	------------------------------------------------------
	--Only counters are available.
	------------------------------------------------------

	elseif can_counter then
		Duel.RemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			2,
			REASON_COST
		)

	------------------------------------------------------
	--Only SAO monster is available.
	------------------------------------------------------

	else
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_TOGRAVE
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.negcostfilter,
			tp,
			LOCATION_HAND+LOCATION_MZONE,
			0,
			1,
			1,
			nil
		)

		Duel.SendtoGrave(
			g,
			REASON_COST
		)
	end
end

----------------------------------------------------------
--NEGATE TARGET
----------------------------------------------------------

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)
end

----------------------------------------------------------
--NEGATE ACTIVATION
--
--Then send every card with the same ORIGINAL NAME
--from the opponent's hand and Deck to the GY.
----------------------------------------------------------

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	------------------------------------------------------
	--Remember the activated card's original code before
	--performing the negate.
	------------------------------------------------------

	local code=rc:GetOriginalCode()

	------------------------------------------------------
	--If the activation was not successfully negated,
	--do not perform the "then" portion.
	------------------------------------------------------

	if not Duel.NegateActivation(ev) then
		return
	end

	------------------------------------------------------
	--Find all cards with that name in the opponent's
	--hand and Deck.
	------------------------------------------------------

	local g=Duel.GetMatchingGroup(
		Card.IsCode,
		tp,
		0,
		LOCATION_HAND+LOCATION_DECK,
		nil,
		code
	)

	if #g==0 then
		return
	end

	------------------------------------------------------
	--Send all copies to the GY by card effect.
	------------------------------------------------------

	Duel.SendtoGrave(
		g,
		REASON_EFFECT
	)
end