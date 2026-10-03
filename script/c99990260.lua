--SAO Counteract
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) When an opponent's monster declares an attack
	--while you control an "SAO" monster:
	--Negate the attack, then end the Battle Phase.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Except the turn this card was sent to the GY:
	--Quick Effect from the GY.
	--Banish this card and remove 1 En-Counter;
	--halve all battle damage you take this turn.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.damcon)
	e2:SetCost(s.damcost)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(3) If you control 2 or more "SAO" monsters,
	--you can activate this Trap from your hand.
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetCondition(s.handcon)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--"SAO" MONSTER FILTER
----------------------------------------------------------

function s.saofilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(SET_SAO)
end

----------------------------------------------------------
--(1) ATTACK NEGATION CONDITION
----------------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()

	return a
		and a:IsControler(1-tp)
		and Duel.IsExistingMatchingCard(
			s.saofilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

----------------------------------------------------------
--ATTACK NEGATION TARGET
----------------------------------------------------------

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end
end

----------------------------------------------------------
--NEGATE ATTACK, THEN END THE BATTLE PHASE
----------------------------------------------------------

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateAttack()~=0 then
		Duel.SkipPhase(
			1-tp,
			PHASE_BATTLE,
			RESET_PHASE|PHASE_BATTLE,
			1
		)
	end
end

----------------------------------------------------------
--(2) GY EFFECT
--CANNOT BE USED THE TURN THIS CARD WAS SENT TO THE GY
----------------------------------------------------------

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--COST:
--BANISH THIS CARD + REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
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

	--Banish Counteract from the GY
	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)

	--Remove 1 En-Counter from your field
	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--APPLY BATTLE DAMAGE REDUCTION FOR THIS TURN
----------------------------------------------------------

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetCondition(s.halfcon)
	e1:SetOperation(s.halfop)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

----------------------------------------------------------
--ONLY DAMAGE TAKEN BY THIS CARD'S CONTROLLER
----------------------------------------------------------

function s.halfcon(e,tp,eg,ep,ev,re,r,rp)
	return ep==tp
end

----------------------------------------------------------
--HALVE EACH INSTANCE OF BATTLE DAMAGE
----------------------------------------------------------

function s.halfop(e,tp,eg,ep,ev,re,r,rp)
	local dam=Duel.GetBattleDamage(tp)

	if dam>0 then
		Duel.ChangeBattleDamage(
			tp,
			math.floor(dam/2)
		)
	end
end

----------------------------------------------------------
--(3) ACTIVATE FROM HAND
--IF YOU CONTROL 2 OR MORE "SAO" MONSTERS
----------------------------------------------------------

function s.handcon(e)
	local tp=e:GetHandlerPlayer()

	return Duel.GetMatchingGroupCount(
		s.saofilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)>=2
end