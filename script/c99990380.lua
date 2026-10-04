--SAO Kobold Sentinels
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994
local TOKEN_KOBOLD=99990385

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) Special Summon 1 Ruin Kobold Sentinel Token,
	--then repeat until you control the same number of
	--monsters as your opponent.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) GY effect:
	--During your Main Phase, except the turn sent to GY:
	--banish this card + remove 1 En-Counter;
	--Special Summon 1 Ruin Kobold Sentinel Token.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.gycon)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--TOKEN CHECK
----------------------------------------------------------

function s.cantoken(tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(
			tp,
			TOKEN_KOBOLD,
			SET_SAO,
			TYPE_TOKEN+TYPE_MONSTER+TYPE_NORMAL,
			1000,
			1000,
			4,
			RACE_BEASTWARRIOR,
			ATTRIBUTE_DARK
		)
end

----------------------------------------------------------
--(1) MAIN EFFECT
----------------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.cantoken(tp)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOKEN,
		nil,
		1,
		tp,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--The first Token is mandatory.
	------------------------------------------------------
	if not s.cantoken(tp) then
		return
	end

	local token=Duel.CreateToken(
		tp,
		TOKEN_KOBOLD
	)

	if Duel.SpecialSummon(
		token,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	------------------------------------------------------
	--Keep repeating while:
	--1. Opponent controls more monsters.
	--2. You have an available Monster Zone.
	--3. You can still Special Summon the Token.
	--4. You choose to continue.
	------------------------------------------------------
	while Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
		<Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		and s.cantoken(tp)
	do
		if not Duel.SelectYesNo(
			tp,
			aux.Stringid(id,2)
		) then
			break
		end

		local token2=Duel.CreateToken(
			tp,
			TOKEN_KOBOLD
		)

		if Duel.SpecialSummon(
			token2,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)==0 then
			break
		end
	end

	------------------------------------------------------
	--For the rest of this turn:
	--cannot Special Summon except SAO monsters.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
	return not c:IsSetCard(SET_SAO)
end

----------------------------------------------------------
--(2) GY EFFECT
----------------------------------------------------------

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	------------------------------------------------------
	--Must be your Main Phase.
	------------------------------------------------------
	if Duel.GetTurnPlayer()~=tp then
		return false
	end

	local ph=Duel.GetCurrentPhase()

	if ph~=PHASE_MAIN1
		and ph~=PHASE_MAIN2
	then
		return false
	end

	------------------------------------------------------
	--Cannot activate during the turn this card
	--was sent to the GY.
	------------------------------------------------------
	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--Banish this card + remove 1 En-Counter.
----------------------------------------------------------

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
			and Duel.IsCanRemoveCounter(
				tp,
				1,
				0,
				COUNTER_EN,
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
		COUNTER_EN,
		1,
		REASON_COST
	)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return s.cantoken(tp)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOKEN,
		nil,
		1,
		tp,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		0
	)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	if not s.cantoken(tp) then
		return
	end

	local token=Duel.CreateToken(
		tp,
		TOKEN_KOBOLD
	)

	Duel.SpecialSummon(
		token,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end