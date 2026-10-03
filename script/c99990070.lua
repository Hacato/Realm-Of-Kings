--SAO Asuna - SAO, Titania
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
	--(1) Each time you Special Summon an "SAO"
	--Synchro Monster:
	--Place 1 EN-Counter on your "SAO" Field Spell
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.ctcon)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Target 1 "SAO" monster you control;
	--this turn, treat it as a Tuner,
	--also its Level becomes 2
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.tnlvtg)
	e2:SetOperation(s.tnlvop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_place_list={0x1994}

----------------------------------------------------------
--(1) PLACE EN-COUNTER
----------------------------------------------------------

--Check that a monster Special Summoned by us is:
--1. face-up
--2. an "SAO" monster
--3. a Synchro Monster
function s.ctfilter(c,tp)
	return c:IsFaceup()
		and c:IsControler(tp)
		and c:GetSummonPlayer()==tp
		and c:IsSetCard(0x999)
		and c:IsType(TYPE_SYNCHRO)
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end

----------------------------------------------------------
--Find our face-up "SAO" Field Spell
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_FIELD)
		and c:IsSetCard(0x999)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fieldfilter,
			tp,
			LOCATION_FZONE,
			0,
			1,
			nil
		)
	end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(
		s.fieldfilter,
		tp,
		LOCATION_FZONE,
		0,
		nil
	)

	if tc then
		--0x1994 = EN-Counter
		tc:AddCounter(0x1994,1)
	end
end

----------------------------------------------------------
--(2) TUNER + LEVEL 2
----------------------------------------------------------

function s.tnlvfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x999)
		and c:IsType(TYPE_MONSTER)
		and c:HasLevel()
end

function s.tnlvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.tnlvfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.tnlvfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	Duel.SelectTarget(
		tp,
		s.tnlvfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)
end

function s.tnlvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then
		return
	end

	------------------------------------------------------
	--Treat it as a Tuner this turn
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_TYPE)
	e1:SetValue(TYPE_TUNER)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e1)

	------------------------------------------------------
	--Its Level becomes 2 this turn
	------------------------------------------------------
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_LEVEL)
	e2:SetValue(2)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e2)
end