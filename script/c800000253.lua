--Sky Striker Ace - Oboro
local s,id=GetID()

local SET_SKY_STRIKER=0x115
local SET_SKY_STRIKER_ACE=0x1115
local CARD_SKY_STRIKER_ACE_HAYATE=8491308

function s.initial_effect(c)
	--Fusion Summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CARD_SKY_STRIKER_ACE_HAYATE,s.matfilter)

	--Alternative Special Summon
	Fusion.AddContactProc(c,s.contactfil,s.contactop,s.splimit,s.contactcon)

	--Track activation of "Sky Striker" Spell Cards while this card is in the Extra Deck
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

	--Cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--Target 1 "Sky Striker Ace" monster you control;
	--it can attack directly this turn, but battle damage it inflicts is halved
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.dirtg)
	e3:SetOperation(s.dirop)
	c:RegisterEffect(e3)
end

--Fusion Material:
--1 non-WIND "Sky Striker Ace" monster
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER_ACE)
		and not c:IsAttribute(ATTRIBUTE_WIND)
end

--Materials available for the alternative summon
function s.contactmat(c)
	return c:IsMonster() and c:IsAbleToRemoveAsCost()
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

--Banish the materials used for the alternative summon
function s.contactop(g,tp,c)
	Duel.Remove(g,POS_FACEUP,REASON_COST|REASON_MATERIAL)
end

--Only allow Fusion Summons or this card's own Extra Deck summon procedure
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

--Register that a "Sky Striker" Spell Card was activated this turn
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

--Apply Link Material restriction until the End Phase
function s.linkreg(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	c:RegisterEffect(e1)
end

--Direct attack target
function s.dirfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
end

function s.dirtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and s.dirfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.dirfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(
		tp,
		s.dirfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)
end

function s.dirop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc
		or not tc:IsFaceup()
		or not tc:IsRelateToEffect(e) then
		return
	end

	--Can attack directly
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e1)

	--Battle damage it inflicts this turn is halved
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e2:SetValue(HALF_DAMAGE)
	e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END)
	tc:RegisterEffect(e2)
end

