--SAO Confront Battle
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	--During damage calculation, if your "SAO" monster
	--battles an opponent's monster:
	--It gains ATK equal to half that monster's current ATK,
	--also 100 ATK for each En-Counter on your field.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e1:SetCondition(s.atkcon)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--GET OUR BATTLING "SAO" MONSTER
--AND THE OPPONENT'S BATTLING MONSTER
----------------------------------------------------------

function s.getbattlemonsters(tp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return nil,nil
	end

	--If our monster is the attacker
	if a:IsControler(tp) then
		return a,d
	end

	--If our monster is the attack target
	if d:IsControler(tp) then
		return d,a
	end

	return nil,nil
end

----------------------------------------------------------
--ACTIVATION CONDITION
----------------------------------------------------------

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local mc,oc=s.getbattlemonsters(tp)

	return mc
		and oc
		and mc:IsFaceup()
		and oc:IsFaceup()
		and mc:IsSetCard(0x999)
		and mc:IsRelateToBattle()
		and oc:IsRelateToBattle()
end

----------------------------------------------------------
--RESOLUTION
----------------------------------------------------------

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local mc,oc=s.getbattlemonsters(tp)

	if not mc
		or not oc
		or not mc:IsRelateToBattle()
		or not oc:IsRelateToBattle()
		or not mc:IsFaceup()
		or not oc:IsFaceup()
		or not mc:IsSetCard(0x999) then
		return
	end

	------------------------------------------------------
	--Gain half the CURRENT ATK of the opponent's
	--battling monster.
	------------------------------------------------------
	local atk=oc:GetAttack()

	if atk<0 then
		atk=0
	end

	local gain1=math.floor(atk/2)

	if gain1>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(gain1)
		e1:SetReset(
			RESET_EVENT
			|RESETS_STANDARD
			|RESET_PHASE
			|PHASE_DAMAGE
		)
		mc:RegisterEffect(e1)
	end

	------------------------------------------------------
	--Gain another 100 ATK for each En-Counter
	--on your field.
	--
	--0x1994 = En-Counter
	------------------------------------------------------
	local ct=Duel.GetCounter(
		tp,
		1,
		0,
		0x1994
	)

	local gain2=ct*100

	if gain2>0 then
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(gain2)
		e2:SetReset(
			RESET_EVENT
			|RESETS_STANDARD
			|RESET_PHASE
			|PHASE_DAMAGE
		)
		mc:RegisterEffect(e2)
	end
end