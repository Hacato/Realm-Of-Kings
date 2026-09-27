--Red Rock Dragon Archfiend
local s,id=GetID()

function s.initial_effect(c)
	--Fusion Materials:
	--1 Dragon Synchro Monster + 1 Rock monster
	Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)
	c:EnableReviveLimit()

	--If Special Summoned:
	--Send 1 Tuner from Deck to GY;
	--opponent's monsters lose 1200 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	--Once while face-up on the field (Quick Effect):
	--Negate effects of all Attack Position monsters
	--your opponent currently controls
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(
		TIMING_MAIN_END|
		TIMING_BATTLE_START|
		TIMING_BATTLE_END,
		TIMINGS_CHECK_MONSTER_E
	)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--If this Fusion Summoned card is destroyed
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--If this Fusion Summoned card is banished
	local e4=e3:Clone()
	e4:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e4)
end

--==================================================
-- FUSION MATERIALS
-- 1 Dragon Synchro Monster + 1 Rock monster
--==================================================

function s.matfilter1(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp)
		and c:IsType(TYPE_SYNCHRO,fc,sumtype,tp)
end

function s.matfilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_ROCK,fc,sumtype,tp)
end

--==================================================
-- EFFECT 1
-- If Special Summoned:
-- Send 1 Tuner from Deck to GY,
-- and if you do, monsters your opponent
-- currently controls lose 1200 ATK
-- until the end of the next turn
--==================================================

function s.tgfilter(c)
	return c:IsMonster()
		and c:IsType(TYPE_TUNER)
		and c:IsAbleToGrave()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.tgfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
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

	--The ATK reduction only happens if the selected
	--Tuner successfully reaches the GY
	if Duel.SendtoGrave(tc,REASON_EFFECT)>0
		and tc:IsLocation(LOCATION_GRAVE) then

		--Only monsters the opponent currently controls
		--are affected
		local g2=Duel.GetMatchingGroup(
			Card.IsFaceup,
			tp,
			0,
			LOCATION_MZONE,
			nil
		)

		for oc in aux.Next(g2) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(-1200)

			--Until the end of the next turn
			e1:SetReset(
				RESET_EVENT|
				RESETS_STANDARD|
				RESET_PHASE|
				PHASE_END,
				2
			)

			oc:RegisterEffect(e1)
		end
	end
end

--==================================================
-- EFFECT 2
-- Once while face-up on the field:
-- Negate the effects of all Attack Position
-- monsters your opponent currently controls
--==================================================

--This flag is used to remember whether this copy
--has already activated its Quick Effect.
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id+100)==0
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:GetFlagEffect(id+100)==0
	end

	--Mark this copy as having used the effect.
	--RESETS_STANDARD removes the flag when this copy
	--leaves its current face-up existence on the field.
	c:RegisterFlagEffect(
		id+100,
		RESET_EVENT|RESETS_STANDARD,
		0,
		1
	)
end

function s.negfilter(c)
	return c:IsFaceup()
		and c:IsAttackPos()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.negfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	local g=Duel.GetMatchingGroup(
		s.negfilter,
		tp,
		0,
		LOCATION_MZONE,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DISABLE,
		g,
		#g,
		0,
		0
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	--"currently controls" means we check which
	--opponent's monsters are still face-up in
	--Attack Position when the effect resolves.
	local g=Duel.GetMatchingGroup(
		s.negfilter,
		tp,
		0,
		LOCATION_MZONE,
		nil
	)

	for tc in aux.Next(g) do
		if tc:IsFaceup() and tc:IsAttackPos() then

			--Negate the monster's effects
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e1)

			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT|RESETS_STANDARD)
			tc:RegisterEffect(e2)
		end
	end
end

--==================================================
-- EFFECT 3
-- If this Fusion Summoned card is destroyed
-- or banished:
-- Special Summon 1 DARK Dragon Synchro Monster
-- with 3000 DEF or less from the Extra Deck.
-- This is treated as a Synchro Summon.
--==================================================

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Only works if this copy was Fusion Summoned
	return c:IsSummonType(SUMMON_TYPE_FUSION)
end

function s.spfilter(c,e,tp)
	return c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsAttribute(ATTRIBUTE_DARK)
		and c:GetDefense()<=3000
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_SYNCHRO,
			tp,
			false,
			false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp,tp,nil,nil)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_EXTRA,
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
		LOCATION_EXTRA
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCountFromEx(tp,tp,nil,nil)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_EXTRA,
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

	if Duel.SpecialSummon(
		tc,
		SUMMON_TYPE_SYNCHRO,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then
		--Marks the monster as properly Synchro Summoned
		tc:CompleteProcedure()
	end
end