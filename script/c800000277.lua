--Dark World Marshalling
local s,id=GetID()

function s.initial_effect(c)
	--When this card is activated:
	--You can target 1 "Dark World" monster in your GY; Special Summon it.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--Once per turn, if a Fiend monster you control would be destroyed:
	--It is not destroyed, then discard 1 card.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	--If a Fiend monster is banished by an effect you control:
	--You can add 1 of your banished Fiend monsters to your hand,
	--and if you do, discard 1 card.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Effect 1
-- On activation:
-- You can target 1 "Dark World" monster in your GY;
-- Special Summon it.
--==================================================

function s.spfilter(c,e,tp)
	return c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp)
	end

	--Activation itself is always legal,
	--because the Special Summon is optional.
	if chk==0 then
		return true
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsExistingTarget(
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil,
		e,
		tp
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,0)
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectTarget(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and tc:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		) then

		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

--==================================================
-- Effect 2
-- Once per turn, if a Fiend monster you control
-- would be destroyed:
-- It is not destroyed, then discard 1 card.
--==================================================

function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsRace(RACE_FIEND)
		and c:IsReason(REASON_BATTLE|REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.discfilter(c)
	return c:IsDiscardable()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(
			s.repfilter,
			1,
			nil,
			tp
		)
			and Duel.IsExistingMatchingCard(
				s.discfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				nil
			)
	end

	return Duel.SelectEffectYesNo(
		tp,
		e:GetHandler(),
		aux.Stringid(id,1)
	)
end

function s.repval(e,c)
	return s.repfilter(
		c,
		e:GetHandlerPlayer()
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(
		s.discfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.discfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoGrave(
			g,
			REASON_EFFECT|REASON_DISCARD
		)
	end
end

--==================================================
-- Effect 3
-- If a Fiend monster is banished by an effect
-- you control:
-- Add 1 of your banished Fiend monsters to your hand,
-- and if you do, discard 1 card.
--==================================================

function s.banishedfiend(c)
	return c:IsMonster()
		and c:IsRace(RACE_FIEND)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then
		return false
	end

	--The effect causing the banish must be yours
	if rp~=tp then
		return false
	end

	return eg:IsExists(
		s.banishedfiend,
		1,
		nil
	)
end

function s.thfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsRace(RACE_FIEND)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_REMOVED,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_REMOVED
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_REMOVED,
		0,
		1,
		nil
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_REMOVED,
		0,
		1,
		1,
		nil
	)

	if #g==0 then
		return
	end

	if Duel.SendtoHand(
		g,
		nil,
		REASON_EFFECT
	)>0 then

		Duel.ConfirmCards(
			1-tp,
			g
		)

		--and if you do, discard 1 card
		if Duel.IsExistingMatchingCard(
			s.discfilter,
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
				s.discfilter,
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
end