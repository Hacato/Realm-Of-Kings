--SAO Leafa - ALO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--Synchro Summon
	--1 Tuner + 1 non-Tuner "SAO" monster
	----------------------------------------------------------
	Synchro.AddProcedure(
		c,
		nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,0x999),1,1
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) If this card is Synchro Summoned:
	--Send 1 "SAO" monster from your Deck to the GY;
	--draw 1 card.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) If this face-up card leaves the field:
	--Banish this card from your GY and remove
	--1 EN-Counter from your field;
	--Special Summon 1 "SAO" monster from your GY,
	--except an "SAO Boss" monster.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999,0x1999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) SYNCHRO SUMMON -> SEND + DRAW
----------------------------------------------------------

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.tgfilter(c)
	return c:IsSetCard(0x999)
		and c:IsMonster()
		and c:IsAbleToGrave()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.tgfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
		and Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.tgfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then
		return
	end

	if Duel.SendtoGrave(tc,REASON_EFFECT)>0
		and tc:IsLocation(LOCATION_GRAVE) then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

----------------------------------------------------------
--(2) LEAVE FIELD
----------------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousPosition(POS_FACEUP)
end

----------------------------------------------------------
--REVIVAL FILTER
--
--The last parameter is Leafa herself.
--She is explicitly excluded from the candidates.
----------------------------------------------------------

function s.spfilter(c,e,tp,leafa)
	return c~=leafa
		and c:IsSetCard(0x999)
		and not c:IsSetCard(0x1999)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

----------------------------------------------------------
--COST:
--Banish this Leafa from the GY
--and remove 1 EN-Counter
----------------------------------------------------------

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsLocation(LOCATION_GRAVE)
			and c:IsAbleToRemoveAsCost()
			and Duel.IsCanRemoveCounter(
				tp,
				1,
				0,
				0x1994,
				1,
				REASON_COST
			)
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--TARGET ANOTHER "SAO" MONSTER
----------------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp,c)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.spfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				c,
				e,
				tp,
				c
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectTarget(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		c,
		e,
		tp,
		c
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

----------------------------------------------------------
--SPECIAL SUMMON + RECOVER
----------------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsLocation(LOCATION_GRAVE)
		or not s.spfilter(tc,e,tp,e:GetHandler()) then
		return
	end

	if Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		--------------------------------------------------
		--Gain half its original ATK
		--------------------------------------------------
		local atk=tc:GetBaseAttack()

		if atk>0 then
			Duel.Recover(
				tp,
				math.ceil(atk/2),
				REASON_EFFECT
			)
		end
	end
end