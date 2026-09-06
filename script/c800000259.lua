--Sky Striker Ace - Asahi
local s,id=GetID()

local SET_SKY_STRIKER_ACE=0x1115

function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(
		c,
		s.xyzfilter,
		4,
		2,
		s.ovfilter,
		aux.Stringid(id,0),
		2
	)

	--You can only Special Summon "Sky Striker Ace - Asahi" once per turn
	c:SetSPSummonOnce(id)

	--Once per turn:
	--Detach 1 material; this turn, double battle damage inflicted
	--by your "Sky Striker Ace" monsters, also they inflict piercing battle damage
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.dmcost)
	e1:SetOperation(s.dmop)
	c:RegisterEffect(e1)

	--A "Sky Striker Ace" monster that was Link Summoned
	--using this card as material cannot be destroyed by battle
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.indcon)
	e2:SetOperation(s.indop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Xyz Summon
-- 2 Level 4 "Sky Striker Ace" monsters
--------------------------------------------------

function s.xyzfilter(c,xyzc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
-- Alternative Xyz Summon
-- Use 1 FIRE "Sky Striker Ace" Link Monster
--------------------------------------------------

function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
		and c:IsAttribute(ATTRIBUTE_FIRE)
		and c:IsType(TYPE_LINK)
end

--------------------------------------------------
-- Cost
-- Detach 1 material
--------------------------------------------------

function s.dmcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

--------------------------------------------------
-- "Sky Striker Ace" filter
--------------------------------------------------

function s.skyfilter(e,c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
-- Double battle damage + piercing
--------------------------------------------------

function s.dmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Double battle damage inflicted by your
	--"Sky Striker Ace" monsters this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.skyfilter)
	e1:SetValue(DOUBLE_DAMAGE)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)

	--Your "Sky Striker Ace" monsters inflict
	--piercing battle damage this turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_PIERCE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.skyfilter)
	e2:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

--------------------------------------------------
-- Used as Link Material for a "Sky Striker Ace"
--------------------------------------------------

function s.indcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if (r&REASON_LINK)==0 then
		return false
	end

	local rc=c:GetReasonCard()

	return rc
		and rc:IsType(TYPE_LINK)
		and rc:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
-- Link Monster cannot be destroyed by battle
--------------------------------------------------

function s.indop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc
		or not rc:IsFaceup()
		or not rc:IsType(TYPE_LINK)
		or not rc:IsSetCard(SET_SKY_STRIKER_ACE) then
		return
	end

	local e1=Effect.CreateEffect(rc)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)
end