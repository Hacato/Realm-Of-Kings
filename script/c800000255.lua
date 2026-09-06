--Sky Striker Ace - Ushio
local s,id=GetID()

local SET_SKY_STRIKER=0x115
local SET_SKY_STRIKER_ACE=0x1115
local CARD_SKY_STRIKER_ACE_SHIZUKU=90673288

function s.initial_effect(c)
	--Fusion Summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CARD_SKY_STRIKER_ACE_SHIZUKU,s.matfilter)

	--Alternative Special Summon
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit,s.contactcon)

	--Track activation of "Sky Striker" Spell Cards
	--while this card is in the Extra Deck
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_CHAINING)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetOperation(s.checkop)
	c:RegisterEffect(e0)

	--Cannot be used as Link Material the turn it is Special Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.linkreg)
	c:RegisterEffect(e1)

	--Gains ATK equal to the difference between both players' LP
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	--Once per turn, when your "Sky Striker Ace" monster
	--inflicts battle damage to your opponent: Gain LP equal to that damage
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.reccon)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end

--------------------------------------------------
-- Fusion Material
-- "Sky Striker Ace - Shizuku"
-- + 1 non-WATER "Sky Striker" monster
--------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER)
		and c:IsMonster()
		and not c:IsAttribute(ATTRIBUTE_WATER)
end

--------------------------------------------------
-- Alternative Special Summon
--------------------------------------------------

function s.contactmat(c)
	return c:IsMonster()
		and c:IsAbleToRemoveAsCost()
end

function s.contactfil(tp)
	return Duel.GetMatchingGroup(
		s.contactmat,
		tp,
		LOCATION_MZONE|LOCATION_GRAVE,
		0,
		nil
	)
end

--Banish the materials
function s.contactop(g,tp,c)
	Duel.Remove(
		g,
		POS_FACEUP,
		REASON_COST|REASON_MATERIAL
	)
end

--Only allow Fusion Summons or this card's
--own Extra Deck Special Summon procedure
function s.splimit(e,se,sp,st)
	if (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION then
		return true
	end

	return se
		and se:GetHandler()==e:GetHandler()
		and se:GetCode()==EFFECT_SPSUMMON_PROC
end

--Alternative summon can only be used during a turn
--you activated a "Sky Striker" Spell Card
function s.contactcon(tp)
	return Duel.GetFlagEffect(tp,id)>0
end

--------------------------------------------------
-- Track "Sky Striker" Spell activation
--------------------------------------------------

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	if not re then
		return
	end

	local rc=re:GetHandler()
	if not rc then
		return
	end

	if re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and rc:IsType(TYPE_SPELL)
		and rc:IsSetCard(SET_SKY_STRIKER) then

		Duel.RegisterFlagEffect(
			rp,
			id,
			RESET_PHASE|PHASE_END,
			0,
			1
		)
	end
end

--------------------------------------------------
-- Cannot be Link Material this turn
--------------------------------------------------

function s.linkreg(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e1:SetValue(1)
	e1:SetReset(
		RESET_EVENT|RESETS_STANDARD|
		RESET_PHASE|PHASE_END
	)
	c:RegisterEffect(e1)
end

--------------------------------------------------
-- Gains ATK equal to the difference
-- between both players' LP
--------------------------------------------------

function s.atkval(e,c)
	return math.abs(Duel.GetLP(0)-Duel.GetLP(1))
end

--------------------------------------------------
-- LP recovery
--------------------------------------------------

--Check that your "Sky Striker Ace" monster
--inflicted battle damage to the opponent
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	if ep~=1-tp or ev<=0 then
		return false
	end

	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if a
		and a:IsControler(tp)
		and a:IsSetCard(SET_SKY_STRIKER_ACE) then
		return true
	end

	if d
		and d:IsControler(tp)
		and d:IsSetCard(SET_SKY_STRIKER_ACE) then
		return true
	end

	return false
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(ev)
	Duel.SetOperationInfo(
		0,
		CATEGORY_RECOVER,
		nil,
		0,
		tp,
		ev
	)
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER,
		CHAININFO_TARGET_PARAM
	)

	if p and d and d>0 then
		Duel.Recover(p,d,REASON_EFFECT)
	end
end