--Red Dragon Archfiend - Absolute Powerforce
local s,id=GetID()

local CARD_RED_DRAGON_ARCHFIEND=70902743

function s.initial_effect(c)
	c:EnableReviveLimit()

	--1 Tuner + 1+ non-Tuner monsters
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)

	--This card's name becomes "Red Dragon Archfiend"
	--while on the field or in the GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE|LOCATION_GRAVE)
	e1:SetValue(CARD_RED_DRAGON_ARCHFIEND)
	c:RegisterEffect(e1)

	--If this card battles a Defense Position monster,
	--inflict piercing battle damage
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e2)

	--At the start of the Damage Step, if this card battles:
	--banish any number of Tuners from your GY;
	--gain 1000 ATK for each until the end of the Damage Step
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
	--banish this card;
	--destroy all Defense Position monsters
	--your opponent controls
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
-- EFFECT 1
-- ATK GAIN
--==================================================

function s.tunerfilter(c)
	return c:IsMonster()
		and c:IsType(TYPE_TUNER)
		and c:IsAbleToRemove()
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetBattleTarget()~=nil
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.tunerfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
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
-- EFFECT 2
-- GY QUICK EFFECT
--
-- (Quick Effect):
-- You can banish this card from your GY;
-- destroy all Defense Position monsters your
-- opponent controls, also you cannot Special
-- Summon from the Extra Deck until your next
-- End Phase, except DARK Dragon Synchro Monsters.
--
-- IMPORTANT:
-- This effect can only be activated if the
-- opponent currently controls at least 1
-- destructible Defense Position monster.
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
	--Do not allow activation if there is nothing
	--for this effect to destroy
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.defilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
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

--==================================================
-- EXTRA DECK RESTRICTION
--
-- Only DARK Dragon Synchro Monsters can be
-- Special Summoned from the Extra Deck.
--==================================================

function s.extralimit(e,c,sump,sumtype,sumpos,targetp,se)
	if not c:IsLocation(LOCATION_EXTRA) then
		return false
	end

	return not (
		c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsAttribute(ATTRIBUTE_DARK)
	)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)

	--Destroy all Defense Position monsters
	--the opponent currently controls
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
	-- Apply Extra Deck restriction
	-- until YOUR next End Phase
	--==================================================

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.extralimit)

	--If activated during your turn:
	--the restriction ends during this End Phase.
	--
	--If activated during the opponent's turn:
	--it survives their End Phase and ends during
	--your following End Phase.
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