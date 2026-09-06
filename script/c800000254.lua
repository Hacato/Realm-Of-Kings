--Sky Striker Ace - Hagane
local s,id=GetID()

local SET_SKY_STRIKER=0x115
local CARD_SKY_STRIKER_ACE_KAINA=12421694

function s.initial_effect(c)
	--Fusion Summon
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CARD_SKY_STRIKER_ACE_KAINA,s.matfilter)

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

	--If this card battles an opponent's monster,
	--use that monster's original ATK and DEF during damage calculation
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SET_ATTACK_FINAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.statcon)
	e2:SetTarget(s.stattg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	local e3=e2:Clone()
	e3:SetCode(EFFECT_SET_DEFENSE_FINAL)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)

	--If this card battles an opponent's monster,
	--negate that monster's effects until the end of the Battle Phase
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_BATTLE_START)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCondition(s.selfnegcon)
	e4:SetOperation(s.selfnegop)
	c:RegisterEffect(e4)

	--If a "Sky Striker" monster you control battles an opponent's monster,
	--negate that opponent's monster's effects until the end of the Damage Step
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_BATTLE_START)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.negcon)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)

	--If an opponent's monster is destroyed by battle with
	--a "Sky Striker" monster you control, banish it
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_BATTLE_DESTROYING)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.rmcon)
	e6:SetOperation(s.rmop)
	c:RegisterEffect(e6)
end

--------------------------------------------------
-- Fusion Material
-- "Sky Striker Ace - Kaina"
-- + 1 non-EARTH "Sky Striker" monster
--------------------------------------------------

function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER)
		and c:IsMonster()
		and not c:IsAttribute(ATTRIBUTE_EARTH)
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

--Can only use the alternative summon during a turn
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
-- Original ATK / DEF during Hagane's battle
--------------------------------------------------

function s.statcon(e)
	local c=e:GetHandler()

	if Duel.GetCurrentPhase()~=PHASE_DAMAGE then
		return false
	end

	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	return a
		and d
		and (a==c or d==c)
end

function s.stattg(e,c)
	local hc=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return false
	end

	if a==hc then
		return c==d
	elseif d==hc then
		return c==a
	end

	return false
end

function s.atkval(e,c)
	return c:GetBaseAttack()
end

function s.defval(e,c)
	return c:GetBaseDefense()
end

--------------------------------------------------
-- Hagane battles:
-- negate opponent until end of Battle Phase
--------------------------------------------------

function s.selfnegcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	return a
		and d
		and (a==c or d==c)
end

function s.selfnegop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	local tc=nil

	if a==c then
		tc=d
	elseif d==c then
		tc=a
	end

	if not tc or tc:IsControler(tp) then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT|RESETS_STANDARD|
		RESET_PHASE|PHASE_BATTLE
	)
	tc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	tc:RegisterEffect(e2)
end

--------------------------------------------------
-- Any "Sky Striker" monster you control battles:
-- negate opposing monster until end of Damage Step
--------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return false
	end

	if a:IsControler(tp)
		and a:IsSetCard(SET_SKY_STRIKER)
		and a:IsMonster()
		and d:IsControler(1-tp) then
		return true
	end

	if d:IsControler(tp)
		and d:IsSetCard(SET_SKY_STRIKER)
		and d:IsMonster()
		and a:IsControler(1-tp) then
		return true
	end

	return false
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	local tc=nil

	if a:IsControler(tp)
		and a:IsSetCard(SET_SKY_STRIKER) then
		tc=d
	elseif d:IsControler(tp)
		and d:IsSetCard(SET_SKY_STRIKER) then
		tc=a
	end

	if not tc then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT|RESETS_STANDARD|
		RESET_PHASE|PHASE_DAMAGE
	)
	tc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	tc:RegisterEffect(e2)
end

--------------------------------------------------
-- Banish opponent's monster if destroyed
-- by battle with your "Sky Striker" monster
--------------------------------------------------

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return false
	end

	if a:IsControler(tp)
		and a:IsSetCard(SET_SKY_STRIKER)
		and a:IsMonster()
		and d:IsControler(1-tp)
		and d:IsStatus(STATUS_BATTLE_DESTROYED) then
		return true
	end

	if d:IsControler(tp)
		and d:IsSetCard(SET_SKY_STRIKER)
		and d:IsMonster()
		and a:IsControler(1-tp)
		and a:IsStatus(STATUS_BATTLE_DESTROYED) then
		return true
	end

	return false
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	local tc=nil

	if a:IsControler(tp)
		and a:IsSetCard(SET_SKY_STRIKER)
		and d:IsStatus(STATUS_BATTLE_DESTROYED) then
		tc=d

	elseif d:IsControler(tp)
		and d:IsSetCard(SET_SKY_STRIKER)
		and a:IsStatus(STATUS_BATTLE_DESTROYED) then
		tc=a
	end

	if tc then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_BATTLE_DESTROY_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end