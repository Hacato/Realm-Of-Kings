--Red Dragon Archfiend - Absolute Powerforce
local s,id=GetID()

local CARD_RED_DRAGON_ARCHFIEND=70902743

function s.initial_effect(c)
	c:EnableReviveLimit()

	--1 Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(
		c,
		nil,
		1,
		1,
		Synchro.NonTuner(nil),
		1,
		99
	)

	--This card's name becomes "Red Dragon Archfiend"
	--while on the field or in the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e1:SetValue(CARD_RED_DRAGON_ARCHFIEND)
	c:RegisterEffect(e1)

	--Piercing battle damage
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)

	--At the start of the Damage Step, if this card battles:
	--banish any number of Tuners from GY;
	--gain 1000 ATK for each
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_START)
	e3:SetCondition(s.atkcon)
	e3:SetTarget(s.atktg)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	--GY Quick Effect:
	--banish this card; destroy all opponent's
	--Defense Position monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)
end

s.listed_names={CARD_RED_DRAGON_ARCHFIEND}

--==================================================
-- ATK gain
--==================================================

function s.tunerfilter(c)
	return c:IsType(TYPE_TUNER)
		and c:IsMonster()
		and c:IsAbleToRemove()
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetBattleTarget()~=nil
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(
		s.tunerfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if chk==0 then
		return #g>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup() then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.tunerfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	--Banish any number of Tuners
	local sg=g:Select(
		tp,
		1,
		#g,
		nil
	)

	if #sg==0 then
		return
	end

	local ct=Duel.Remove(
		sg,
		POS_FACEUP,
		REASON_EFFECT
	)

	if ct>0
		and c:IsFaceup()
		and c:IsRelateToEffect(e) then

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*1000)

		--Until the end of the Damage Step
		e1:SetReset(
			RESET_EVENT|RESETS_STANDARD|
			RESET_PHASE|PHASE_DAMAGE
		)

		c:RegisterEffect(e1)
	end
end

--==================================================
-- GY Quick Effect
--
-- Banish this card;
-- destroy all Defense Position monsters
-- your opponent controls.
--
-- Also, until your next End Phase,
-- you cannot Special Summon from the Extra Deck,
-- except DARK Dragon Synchro Monsters.
--==================================================

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

function s.defilter(c)
	return c:IsDefensePos()
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	local g=Duel.GetMatchingGroup(
		s.defilter,
		tp,
		0,
		LOCATION_MZONE,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		#g,
		0,
		0
	)
end

function s.extralimit(e,c,sump,sumtype,sumpos,targetp,se)
	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	--Only DARK Dragon Synchro Monsters
	--may be Special Summoned from the Extra Deck
	return not (
		c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsAttribute(ATTRIBUTE_DARK)
	)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)

	--Destroy all opponent's Defense Position monsters
	local g=Duel.GetMatchingGroup(
		s.defilter,
		tp,
		0,
		LOCATION_MZONE,
		nil
	)

	if #g>0 then
		Duel.Destroy(
			g,
			REASON_EFFECT
		)
	end

	--==================================================
	-- Extra Deck restriction
	-- until YOUR next End Phase
	--==================================================

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.extralimit)

	--If activated during your turn:
	--reset this End Phase.
	--
	--If activated during opponent's turn:
	--pass their End Phase and reset during yours.
	local ct=1

	if Duel.GetTurnPlayer()~=tp then
		ct=2
	end

	e1:SetReset(
		RESET_PHASE|PHASE_END,
		ct
	)

	Duel.RegisterEffect(
		e1,
		tp
	)
end