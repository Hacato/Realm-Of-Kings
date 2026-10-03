--SAO Kirito - ALO
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
	--(1) Remove 2 En-Counters;
	--Special Summon 1 "SAO" Synchro from Extra Deck,
	--except this card, but banish it when it leaves.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) When this attacking card destroys a monster:
	--Gain 300 ATK for each OTHER "SAO" monster you control
	--until the end of the Battle Phase,
	--also make a second attack in a row.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) REMOVE 2 EN-COUNTERS
----------------------------------------------------------

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			0x1994,
			2,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		2,
		REASON_COST
	)
end

----------------------------------------------------------
--"SAO" SYNCHRO MONSTER FROM EXTRA DECK
--EXCEPT THIS CARD
----------------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x999)
		and c:IsType(TYPE_SYNCHRO)
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCountFromEx(tp)>0
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
	if Duel.GetLocationCountFromEx(tp)<=0 then
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

	------------------------------------------------------
	--Special Summon it.
	--This is NOT treated as a Synchro Summon.
	------------------------------------------------------
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
		--Banish it when it leaves the field.
		--------------------------------------------------
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(LOCATION_REMOVED)
		e1:SetReset(RESET_EVENT|RESETS_REDIRECT)
		tc:RegisterEffect(e1,true)
	end
end

----------------------------------------------------------
--(2) DESTROYS A MONSTER BY BATTLE WHILE ATTACKING
----------------------------------------------------------

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()

	return c==Duel.GetAttacker()
		and bc
		and bc:IsMonster()
end

----------------------------------------------------------
--OTHER "SAO" MONSTERS
----------------------------------------------------------

function s.atkfilter(c,sc)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c~=sc
end

----------------------------------------------------------
--GAIN ATK + SECOND ATTACK
----------------------------------------------------------

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsRelateToBattle() then
		return
	end

	------------------------------------------------------
	--Count OTHER "SAO" monsters.
	------------------------------------------------------
	local ct=Duel.GetMatchingGroupCount(
		s.atkfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil,
		c
	)

	------------------------------------------------------
	--Gain 300 ATK for each other "SAO" monster
	--until the end of the Battle Phase.
	------------------------------------------------------
	if ct>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*300)
		e1:SetReset(
			RESET_EVENT
			|RESETS_STANDARD
			|RESET_PHASE
			|PHASE_BATTLE
		)
		c:RegisterEffect(e1)
	end

	------------------------------------------------------
	--Can make a second attack in a row.
	--
	--Register an additional attack instead of using the
	--deleted IsChainAttackable helper.
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(1)
	e2:SetReset(
		RESET_EVENT
			|RESETS_STANDARD
			|RESET_PHASE
			|PHASE_BATTLE
	)
	c:RegisterEffect(e2)
end