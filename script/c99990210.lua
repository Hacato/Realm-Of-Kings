--SAO Sinon - GGO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--Xyz Summon
	--2 Level 4 "SAO" monsters
	----------------------------------------------------------
	Xyz.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x999),
		4,2
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) Quick Effect:
	--Remove 1 En-Counter, then target
	--1 "SAO" monster you control and
	--1 card your opponent controls; destroy them.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Once per turn:
	--Detach 1 material;
	--this card can attack directly this turn.
	--If it does, halve the battle damage.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.dacon)
	e2:SetCost(s.dacost)
	e2:SetOperation(s.daop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--YOUR "SAO" MONSTER
----------------------------------------------------------

function s.ownfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c:IsDestructable()
end

----------------------------------------------------------
--OPPONENT'S CARD
----------------------------------------------------------

function s.oppfilter(c)
	return c:IsDestructable()
end

----------------------------------------------------------
--TARGET 1 "SAO" MONSTER YOU CONTROL
--AND 1 CARD OPPONENT CONTROLS
----------------------------------------------------------

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		if chkc:IsControler(tp) then
			return chkc:IsLocation(LOCATION_MZONE)
				and s.ownfilter(chkc)
		else
			return chkc:IsControler(1-tp)
				and chkc:IsLocation(LOCATION_ONFIELD)
				and s.oppfilter(chkc)
		end
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.ownfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
		and Duel.IsExistingTarget(
			s.oppfilter,
			tp,
			0,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	--Your "SAO" monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

	local g1=Duel.SelectTarget(
		tp,
		s.ownfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	--Opponent's card
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

	local g2=Duel.SelectTarget(
		tp,
		s.oppfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	g1:Merge(g2)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g1,
		2,
		0,
		0
	)
end

----------------------------------------------------------
--DESTROY BOTH
----------------------------------------------------------

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)

	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

----------------------------------------------------------
--(2) DIRECT ATTACK
----------------------------------------------------------

function s.dacon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsAbleToEnterBP()
end

----------------------------------------------------------
--DETACH 1 MATERIAL
----------------------------------------------------------

function s.dacost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(
			tp,
			1,
			REASON_COST
		)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--GAIN DIRECT ATTACK PERMISSION
----------------------------------------------------------

function s.daop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsRelateToEffect(e) then
		return
	end

	------------------------------------------------------
	--Can attack directly this turn
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(
		RESET_EVENT
		|RESETS_STANDARD
		|RESET_PHASE
		|PHASE_END
	)
	c:RegisterEffect(e1)

	------------------------------------------------------
	--If Sinon attacks directly using this effect,
	--modify the pending battle damage.
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e2:SetCondition(s.rdcon)
	e2:SetOperation(s.rdop)
	e2:SetReset(
		RESET_EVENT
		|RESETS_STANDARD
		|RESET_PHASE
		|PHASE_END
	)
	c:RegisterEffect(e2)
end

----------------------------------------------------------
--CHECK THAT THIS IS ACTUALLY A DIRECT ATTACK
----------------------------------------------------------

function s.rdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return Duel.GetAttacker()==c
		and Duel.GetAttackTarget()==nil
		and ep~=tp
end

----------------------------------------------------------
--HALVE THE ACTUAL PENDING BATTLE DAMAGE
----------------------------------------------------------

function s.rdop(e,tp,eg,ep,ev,re,r,rp)
	local dam=Duel.GetBattleDamage(ep)

	if dam>0 then
		Duel.ChangeBattleDamage(
			ep,
			math.floor(dam/2)
		)
	end
end