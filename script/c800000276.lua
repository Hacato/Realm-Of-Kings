--Dark World Supremacy
local s,id=GetID()

function s.initial_effect(c)
	--Reveal Fiends, negate the same number of opponent's cards,
	--then discard the revealed monsters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--GY effect:
	--Banish this card; return 2 monsters to the hand,
	--then discard 1 card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.bcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.btg)
	e2:SetOperation(s.bop)
	c:RegisterEffect(e2)
end

--==================================================
-- Effect 1
--
-- Reveal any number of Fiend monsters from your hand
-- and target that many face-up cards your opponent
-- controls; negate their effects until the End Phase,
-- then discard the revealed monsters.
--==================================================

function s.revfilter(c)
	return c:IsRace(RACE_FIEND)
		and c:IsMonster()
		and c:IsDiscardable()
end

function s.tgfilter(c,e)
	return c:IsFaceup()
		and c:IsCanBeEffectTarget(e)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local hct=Duel.GetMatchingGroupCount(
		s.revfilter,
		tp,
		LOCATION_HAND,
		0,
		nil
	)

	local fct=Duel.GetMatchingGroupCount(
		s.tgfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		nil,
		e
	)

	local max=math.min(hct,fct)

	if chk==0 then
		return max>0
	end

	--Choose any number of Fiend monsters,
	--up to the number of valid opponent's cards
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	local rg=Duel.SelectMatchingCard(
		tp,
		s.revfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		max,
		nil
	)

	if #rg==0 then
		return
	end

	--Reveal them
	Duel.ConfirmCards(
		1-tp,
		rg
	)

	--Keep track of the exact monsters revealed
	rg:KeepAlive()
	e:SetLabelObject(rg)

	local ct=#rg

	--Target the same number of face-up
	--cards the opponent controls
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local tg=Duel.SelectTarget(
		tp,
		s.tgfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		ct,
		ct,
		nil,
		e
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DISABLE,
		tg,
		ct,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_HANDES,
		rg,
		ct,
		tp,
		LOCATION_HAND
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rg=e:GetLabelObject()
	local tg=Duel.GetTargetCards(e)

	local negated=0

	--Negate all remaining valid targets
	for tc in aux.Next(tg) do
		if tc:IsFaceup()
			and tc:IsRelateToEffect(e) then

			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(
				RESET_EVENT|RESETS_STANDARD|
				RESET_PHASE|PHASE_END
			)
			tc:RegisterEffect(e1)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)

			negated=negated+1
		end
	end

	--"then discard the revealed monsters"
	if negated>0 and rg then
		local dg=rg:Filter(
			function(c,tp)
				return c:IsLocation(LOCATION_HAND)
					and c:IsControler(tp)
			end,
			nil,
			tp
		)

		if #dg>0 then
			Duel.SendtoGrave(
				dg,
				REASON_EFFECT|REASON_DISCARD
			)
		end
	end

	if rg then
		rg:DeleteGroup()
	end
end

--==================================================
-- Effect 2
--
-- During either player's turn, while this card
-- is in the GY and you control a Fiend:
-- banish this card, target 2 monsters on either field;
-- return them to the hand, then discard 1 card.
--==================================================

function s.fiendfilter(c)
	return c:IsFaceup()
		and c:IsRace(RACE_FIEND)
end

function s.bcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.fiendfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

function s.bfilter(c,e)
	return c:IsMonster()
		and c:IsAbleToHand()
		and c:IsCanBeEffectTarget(e)
end

function s.btg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingTarget(
			s.bfilter,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			2,
			nil,
			e
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RTOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		s.bfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		2,
		2,
		nil,
		e
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		2,
		0,
		0
	)
end

function s.bop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e):Filter(
		function(c)
			return c:IsRelateToEffect(e)
		end,
		nil
	)

	if #g==0 then
		return
	end

	local ct=Duel.SendtoHand(
		g,
		nil,
		REASON_EFFECT
	)

	--"then discard 1 card"
	if ct>0
		and Duel.IsExistingMatchingCard(
			Card.IsDiscardable,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		) then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_DISCARD
		)

		local dg=Duel.SelectMatchingCard(
			tp,
			Card.IsDiscardable,
			tp,
			LOCATION_HAND,
			0,
			1,
			1,
			nil
		)

		if #dg>0 then
			Duel.SendtoGrave(
				dg,
				REASON_EFFECT|REASON_DISCARD
			)
		end
	end
end