--El Shaddoll Aschera
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--==================================================
	-- FUSION SUMMON PROCEDURE
	-- 2 "Shaddoll" monsters with different Attributes
	--
	-- Uses the same working procedure as
	-- El Shaddoll Apkallone.
	--==================================================
	Fusion.AddProcMixN(c,true,true,s.ffilter,2)

	--Must first be Fusion Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(
		EFFECT_FLAG_SINGLE_RANGE+
		EFFECT_FLAG_CANNOT_DISABLE+
		EFFECT_FLAG_UNCOPYABLE
	)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)

	--==================================================
	-- QUICK EFFECT
	-- Once per turn, during the Main Phase:
	-- Change all monsters on the field to
	-- face-down Defense Position
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
	e1:SetCountLimit(1)
	e1:SetCondition(s.poscon)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)

	--==================================================
	-- IF SPECIAL SUMMONED
	-- Special Summon 1 "Shaddoll" monster from
	-- Deck or GY in face-down Defense Position
	--==================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

	--==================================================
	-- IF SENT TO THE GY
	-- Add 1 "Shaddoll" card from Deck or GY,
	-- then discard 1 card
	--==================================================
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(
		CATEGORY_TOHAND+
		CATEGORY_SEARCH+
		CATEGORY_HANDES
	)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SHADDOLL}
s.material_setcode=SET_SHADDOLL

--==================================================
-- FUSION MATERIAL
--
-- EXACT APKALLONE METHOD:
--
-- Material must be a "Shaddoll".
--
-- If another material has already been selected,
-- this material cannot have the same Attribute.
--==================================================

function s.ffilter(c,fc,sumtype,sp,sub,mg,sg)
	return c:IsSetCard(
		SET_SHADDOLL,
		fc,
		sumtype,
		sp
	)
	and (
		not sg
		or sg:FilterCount(aux.TRUE,c)==0
		or not sg:IsExists(
			Card.IsAttribute,
			1,
			c,
			c:GetAttribute(),
			fc,
			sumtype,
			sp
		)
	)
end

--==================================================
-- QUICK EFFECT
-- MAIN PHASE ONLY
--==================================================

function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return ph==PHASE_MAIN1
		or ph==PHASE_MAIN2
end

--==================================================
-- MONSTER CAN BE CHANGED FACE-DOWN
--==================================================

function s.posfilter(c)
	return c:IsFaceup()
		and c:IsCanTurnSet()
end

--==================================================
-- CHANGE ALL MONSTERS FACE-DOWN
--==================================================

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.posfilter,
			tp,
			LOCATION_MZONE,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	local g=Duel.GetMatchingGroup(
		s.posfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_POSITION,
		g,
		#g,
		0,
		0
	)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(
		s.posfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	if #g>0 then
		Duel.ChangePosition(
			g,
			POS_FACEDOWN_DEFENSE
		)
	end
end

--==================================================
-- SPECIAL SUMMON SHADDOLL FROM DECK/GY
-- FACE-DOWN DEFENSE POSITION
--==================================================

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SHADDOLL)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false,
			POS_FACEDOWN_DEFENSE
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_DECK|LOCATION_GRAVE,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_DECK|LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEDOWN_DEFENSE
		)
	end
end

--==================================================
-- ADD SHADDOLL FROM DECK/GY
--==================================================

function s.thfilter(c)
	return c:IsSetCard(SET_SHADDOLL)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK|LOCATION_GRAVE,
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
		LOCATION_DECK|LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_HANDES,
		nil,
		0,
		tp,
		1
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.thfilter),
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	if #g>0
		and Duel.SendtoHand(
			g,
			nil,
			REASON_EFFECT
		)>0 then

		local og=Group.Filter(
			Duel.GetOperatedGroup(),
			Card.IsLocation,
			nil,
			LOCATION_HAND
		)

		--Only continue to "then discard 1"
		--if the selected card actually reached hand.
		if #og>0 then

			Duel.ConfirmCards(1-tp,g)

			Duel.BreakEffect()

			Duel.ShuffleHand(tp)

			Duel.DiscardHand(
				tp,
				nil,
				1,
				1,
				REASON_EFFECT|
				REASON_DISCARD
			)
		end
	end
end