--Sky Striker Ace - Kagari Fast Mode
local s,id=GetID()

local SET_SKY_STRIKER_ACE=0x1115

function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(
		c,
		s.matfilter,
		1,
		1
	)

	--You can only Special Summon
	--"Sky Striker Ace - Kagari Fast Mode" once per turn
	c:SetSPSummonOnce(id)

	--If this card battles, your opponent cannot activate
	--cards or effects until the end of the Damage Step
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--Also apply the activation lock if this card
	--is attacked by an opponent's monster
	local e2=e1:Clone()
	e2:SetCode(EVENT_BE_BATTLE_TARGET)
	c:RegisterEffect(e2)

	--Once per battle, during damage calculation,
	--if this card battles an opponent's monster linked to this card:
	--Gain ATK equal to the total ATK of all
	--"Sky Striker Ace" Link Monsters in your GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.atkcon)
	e3:SetCost(s.atkcost)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
-- Link Material
-- 1 "Sky Striker Ace" Link Monster
--------------------------------------------------

function s.matfilter(c,lc,sumtype,tp)
	return c:IsType(TYPE_LINK)
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
-- Opponent cannot activate cards/effects
-- while this card battles
--------------------------------------------------

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	return a==c or d==c
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(0,1)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE|PHASE_DAMAGE)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------------------------
-- ATK gain condition
--------------------------------------------------

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Already used during this battle
	if c:GetFlagEffect(id)>0 then
		return false
	end

	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return false
	end

	--This card must be one of the battling monsters
	if a~=c and d~=c then
		return false
	end

	--Get the opponent's battling monster
	local tc

	if a==c then
		tc=d
	else
		tc=a
	end

	if not tc or not tc:IsControler(1-tp) then
		return false
	end

	--The opponent's monster must be linked to this card
	return c:IsLinked(tc)
end

--------------------------------------------------
-- Once per battle lock
--------------------------------------------------

function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:GetFlagEffect(id)==0
	end

	--Prevent another activation during this same battle
	c:RegisterFlagEffect(
		id,
		RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_DAMAGE,
		0,
		1
	)
end

--------------------------------------------------
-- "Sky Striker Ace" Link Monsters in GY
--------------------------------------------------

function s.atkfilter(c)
	return c:IsSetCard(SET_SKY_STRIKER_ACE)
		and c:IsType(TYPE_LINK)
end

--------------------------------------------------
-- Gain ATK equal to their total ATK
--------------------------------------------------

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsRelateToBattle() then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.atkfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if g:GetCount()==0 then
		return
	end

	local atk=0

	for tc in aux.Next(g) do
		local catk=tc:GetAttack()

		if catk>0 then
			atk=atk+catk
		end
	end

	if atk<=0 then
		return
	end

	--Gain ATK during this damage calculation only
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_PHASE|PHASE_DAMAGE_CAL)
	c:RegisterEffect(e1)
end