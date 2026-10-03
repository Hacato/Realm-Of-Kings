--SAO Yuuki - ALO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	--Synchro Summon
	--1 Tuner + 1 non-Tuner "SAO" monster
	Synchro.AddProcedure(
		c,
		nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,0x999),1,1
	)
	c:EnableReviveLimit()

	--(1) If Synchro Summoned:
	--Opponent's monsters lose 300 ATK for each
	--other "SAO" monster you control.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.atkcon)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	--(2) If this attacking card destroys
	--an opponent's monster by battle:
	--Remove En-Counters and gain additional attacks.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCountLimit(1)
	e2:SetCondition(s.aacon)
	e2:SetCost(s.aacost)
	e2:SetOperation(s.aaop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) SYNCHRO SUMMON EFFECT
----------------------------------------------------------

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.saofilter(c,sc)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c~=sc
end

function s.oppfilter(c)
	return c:IsFaceup()
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	local ct=Duel.GetMatchingGroupCount(
		s.saofilter,
		tp,
		LOCATION_MZONE,
		0,
		nil,
		c
	)

	if chk==0 then
		return ct>0
			and Duel.IsExistingMatchingCard(
				s.oppfilter,
				tp,
				0,
				LOCATION_MZONE,
				1,
				nil
			)
	end
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local ct=Duel.GetMatchingGroupCount(
		s.saofilter,
		tp,
		LOCATION_MZONE,
		0,
		nil,
		c
	)

	if ct<=0 then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.oppfilter,
		tp,
		0,
		LOCATION_MZONE,
		nil
	)

	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-300*ct)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

----------------------------------------------------------
--(2) DESTROYS A MONSTER BY BATTLE WHILE ATTACKING
----------------------------------------------------------

function s.aacon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()

	return c==Duel.GetAttacker()
		and bc~=nil
		and bc:IsControler(1-tp)
end

----------------------------------------------------------
--REMOVE EN-COUNTERS
----------------------------------------------------------

function s.aacost(e,tp,eg,ep,ev,re,r,rp,chk)
	--How many monsters the opponent currently controls
	local mct=Duel.GetFieldGroupCount(
		tp,
		0,
		LOCATION_MZONE
	)

	--How many En-Counters are available on our field
	local cct=Duel.GetCounter(
		tp,
		1,
		0,
		0x1994
	)

	local maxct=math.min(mct,cct)

	if chk==0 then
		return maxct>0
	end

	--Choose between 1 and the maximum number
	local ct=1

	if maxct>1 then
		local t={}

		for i=1,maxct do
			t[#t+1]=i
		end

		ct=Duel.AnnounceNumber(
			tp,
			table.unpack(t)
		)
	end

	--Remove exactly that many En-Counters
	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		ct,
		REASON_COST
	)

	--Store how many were removed
	e:SetLabel(ct)
end

----------------------------------------------------------
--GAIN ADDITIONAL MONSTER ATTACKS
----------------------------------------------------------

function s.aaop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()

	if ct<=0 then
		return
	end

	if not c:IsFaceup()
		or not c:IsRelateToBattle() then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e1:SetValue(ct)
	e1:SetReset(
		RESET_EVENT
		|RESETS_STANDARD
		|RESET_PHASE
		|PHASE_BATTLE
	)
	c:RegisterEffect(e1)
end