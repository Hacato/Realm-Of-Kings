--SAO Tense Strategy
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Remove all En-Counters from your field;
	--apply effects based on the number removed.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--COST
--Remove ALL En-Counters from your field.
----------------------------------------------------------

function s.counterfilter(c)
	return c:GetCounter(COUNTER_EN)>0
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetCounter(
		tp,
		1,
		0,
		COUNTER_EN
	)

	if chk==0 then
		return ct>0
	end

	------------------------------------------------------
	--Remember exactly how many counters existed.
	------------------------------------------------------
	e:SetLabel(ct)

	------------------------------------------------------
	--Remove every En-Counter from every card
	--on our field.
	------------------------------------------------------
	local g=Duel.GetMatchingGroup(
		s.counterfilter,
		tp,
		LOCATION_ONFIELD,
		0,
		nil
	)

	for tc in aux.Next(g) do
		local cct=tc:GetCounter(COUNTER_EN)

		if cct>0 then
			tc:RemoveCounter(
				tp,
				COUNTER_EN,
				cct,
				REASON_COST
			)
		end
	end
end

----------------------------------------------------------
--SAO MONSTER FILTER
----------------------------------------------------------

function s.saofilter(e,c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
end

----------------------------------------------------------
--RESOLUTION
----------------------------------------------------------

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()

	if ct<=0 then
		return
	end

	------------------------------------------------------
	--1+
	--All SAO monsters you control gain 200 ATK
	--for each En-Counter removed.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.saofilter)
	e1:SetValue(ct*200)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	------------------------------------------------------
	--3+
	--SAO monsters you control cannot be destroyed
	--by card effects.
	------------------------------------------------------
	if ct>=3 then
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetTargetRange(LOCATION_MZONE,0)
		e2:SetTarget(s.saofilter)
		e2:SetValue(1)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end

	------------------------------------------------------
	--5+
	--If your SAO monster battles, opponent cannot
	--activate cards or effects.
	------------------------------------------------------
	if ct>=5 then
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e3:SetCode(EFFECT_CANNOT_ACTIVATE)
		e3:SetTargetRange(0,1)
		e3:SetCondition(s.actcon)
		e3:SetValue(s.actlimit)
		e3:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e3,tp)
	end
end

----------------------------------------------------------
--5+ EFFECT
--Check whether one of our SAO monsters is currently
--involved in the battle.
----------------------------------------------------------

function s.battlefilter(c,tp)
	return c
		and c:IsFaceup()
		and c:IsControler(tp)
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
end

function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	------------------------------------------------------
	--A battle must actually be occurring.
	--
	--A direct attack still counts as a battle involving
	--our SAO monster, which is intentional.
	------------------------------------------------------
	if not a then
		return false
	end

	return s.battlefilter(a,tp)
		or s.battlefilter(d,tp)
end

function s.actlimit(e,re,tp)
	return true
end