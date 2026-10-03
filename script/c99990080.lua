--SAO Asuna - ALO
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
	--(1) Quick Effect:
	--Remove 1 EN-Counter, then target 1 Attack Position
	--monster your opponent controls; change it to Defense
	--Position, and if you do, it cannot activate its
	--effects this turn.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCost(s.poscost)
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Piercing battle damage
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--Double piercing battle damage
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e3:SetCondition(s.damcon)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.poscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			0x1994,
			1,
			REASON_COST
		)
	end

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
--TARGET ATTACK POSITION MONSTER
----------------------------------------------------------

function s.posfilter(c)
	return c:IsFaceup()
		and c:IsAttackPos()
		and c:IsCanChangePosition()
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.posfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.posfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)

	local g=Duel.SelectTarget(
		tp,
		s.posfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_POSITION,
		g,
		1,
		0,
		0
	)
end

----------------------------------------------------------
--CHANGE TO DEFENSE POSITION
--THEN PREVENT EFFECT ACTIVATION
----------------------------------------------------------

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsAttackPos() then
		return
	end

	if Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)>0 then

		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_TRIGGER)
		e1:SetReset(
			RESET_EVENT
			|RESETS_STANDARD
			|RESET_PHASE
			|PHASE_END
		)
		tc:RegisterEffect(e1)
	end
end

----------------------------------------------------------
--(2) DOUBLE PIERCING BATTLE DAMAGE
----------------------------------------------------------

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttackTarget()

	return ep~=tp
		and c==Duel.GetAttacker()
		and tc
		and tc:IsDefensePos()
		and ev>0
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--EVENT_PRE_BATTLE_DAMAGE gives us the battle damage
	--in ev.
	--
	--EFFECT_PIERCE has already established that the
	--opponent will take piercing damage.
	--
	--Simply replace that damage with twice its value.
	------------------------------------------------------
	Duel.ChangeBattleDamage(ep,ev*2)
end