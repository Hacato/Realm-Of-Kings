--Trust Resonator
local s,id=GetID()

function s.initial_effect(c)
	--Reveal this card, send 1 "Resonator" Tuner
	--or 1 monster that mentions "Assault Mode Activate",
	--then Special Summon this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Quick Effect from GY:
	--Banish this card; Special Summon 1 Level 4 or higher monster
	--that mentions "Assault Mode Activate", ignoring Summoning conditions
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

--==================================================
-- FIRST EFFECT
--==================================================

--Official card ID for "Assault Mode Activate"
local ASSAULT_MODE_ACTIVATE=80280737

--"Resonator" Tuner OR monster that mentions
--"Assault Mode Activate", except Trust Resonator
function s.sendfilter(c)
	return not c:IsCode(id)
		and c:IsMonster()
		and (
			(c:IsSetCard(SET_RESONATOR) and c:IsType(TYPE_TUNER))
			or c:ListsCode(ASSAULT_MODE_ACTIVATE)
		)
		and c:IsAbleToGraveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.sendfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	--Reveal Trust Resonator
	Duel.ConfirmCards(1-tp,c)

	--Send appropriate monster from Deck to GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(
		tp,
		s.sendfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoGrave(g,REASON_COST)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_HAND
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(
			c,
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
-- SECOND EFFECT
--==================================================

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

--Level 4 or higher monster that mentions
--"Assault Mode Activate"
function s.gyfilter(c,e,tp)
	return c:IsMonster()
		and c:IsLevelAbove(4)
		and c:ListsCode(ASSAULT_MODE_ACTIVATE)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			true,
			true
		)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.gyfilter,
				tp,
				LOCATION_GRAVE,
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
		LOCATION_GRAVE
	)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.gyfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local tc=g:GetFirst()
	if not tc then
		return
	end

	--Ignore Summoning conditions and revive limitation
	Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		true,
		true,
		POS_FACEUP
	)
end