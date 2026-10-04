--SAO LLENN - GGO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Xyz Summon
	--2 Level 4 "SAO" monsters
	----------------------------------------------------------
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SAO),4,2)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) Activate SAO Quick-Play Spells from the hand
	--during the opponent's turn
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_HAND,0)
	e1:SetTarget(s.handtg)
	e1:SetCondition(s.handcon)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--Activate SAO Traps from the hand
	----------------------------------------------------------
	local e2=e1:Clone()
	e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--Marker used by the activation-cost effect
	----------------------------------------------------------
	local e3=e1:Clone()
	e3:SetCode(id)
	c:RegisterEffect(e3)

	----------------------------------------------------------
	--Additional activation cost:
	--Remove 2 En-Counters
	----------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_ACTIVATE_COST)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(1,0)
	e4:SetCost(s.costchk)
	e4:SetTarget(s.costtg)
	e4:SetOperation(s.costop)
	c:RegisterEffect(e4)

	----------------------------------------------------------
	--(2) If this attacking card destroys an opponent's
	--monster by battle:
	--Detach 1 material; it can attack again.
	----------------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_BATTLED)
	e5:SetCondition(s.aacon)
	e5:SetCost(s.aacost)
	e5:SetOperation(s.aaop)
	c:RegisterEffect(e5)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) HAND ACTIVATION
----------------------------------------------------------

function s.handtg(e,c)
	return c:IsSetCard(SET_SAO)
end

function s.handcon(e)
	local tp=e:GetHandlerPlayer()

	return Duel.GetTurnPlayer()~=tp
		and Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			2,
			REASON_COST
		)
end

----------------------------------------------------------
--Check En-Counter cost
----------------------------------------------------------
function s.costchk(e,te_or_c,tp)
	return Duel.IsCanRemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)
end

----------------------------------------------------------
--Only charge LLENN's additional activation cost
--when activating an SAO Quick-Play Spell/Trap
--from the hand through her permission.
----------------------------------------------------------
function s.costtg(e,te,tp)
	local tc=te:GetHandler()

	if Duel.GetTurnPlayer()==tp then
		return false
	end

	if not tc:IsLocation(LOCATION_HAND) then
		return false
	end

	if not tc:IsSetCard(SET_SAO) then
		return false
	end

	if tc:GetEffectCount(id)<=0 then
		return false
	end

	if tc:IsType(TYPE_QUICKPLAY) then
		return tc:GetEffectCount(EFFECT_QP_ACT_IN_NTPHAND)
			<=tc:GetEffectCount(id)
	end

	if tc:IsType(TYPE_TRAP) then
		return tc:GetEffectCount(EFFECT_TRAP_ACT_IN_HAND)
			<=tc:GetEffectCount(id)
	end

	return false
end

----------------------------------------------------------
--Remove 2 En-Counters
----------------------------------------------------------
function s.costop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)
end

----------------------------------------------------------
--(2) ATTACK AGAIN
----------------------------------------------------------

----------------------------------------------------------
--EVENT_BATTLED occurs after the battle.
--
--LLENN must:
--1. Have been the attacker.
--2. Have battled an opponent's monster.
--3. Have destroyed that monster by battle.
----------------------------------------------------------
function s.aacon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if Duel.GetAttacker()~=c then
		return false
	end

	local bc=c:GetBattleTarget()

	if not bc then
		return false
	end

	return bc:IsControler(1-tp)
		and bc:IsStatus(STATUS_BATTLE_DESTROYED)
		and bc:IsReason(REASON_BATTLE)
end

----------------------------------------------------------
--Detach 1 Xyz Material
----------------------------------------------------------
function s.aacost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--Give LLENN 1 additional attack this Battle Phase.
----------------------------------------------------------
function s.aaop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup() then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetValue(1)
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD+
		RESET_PHASE+PHASE_BATTLE
	)
	c:RegisterEffect(e1)
end