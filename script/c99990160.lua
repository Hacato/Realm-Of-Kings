--SAO Boss, The Skull Reaper
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--You can only control 1 "SAO Boss" monster
	--0x1999 = SAO Boss
	----------------------------------------------------------
	c:SetUniqueOnField(
		1,0,
		aux.FilterBoolFunction(Card.IsSetCard,0x1999),
		LOCATION_MZONE
	)

	----------------------------------------------------------
	--(1) Special Summon from hand by banishing
	--3 "SAO" monsters from your GY,
	--except "SAO Boss" monsters
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.hspcon)
	e1:SetOperation(s.hspop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2a) Opponent cannot target your OTHER
	--"SAO" monsters with card effects
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.prottg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(2b) Opponent's monsters cannot target your OTHER
	--"SAO" monsters for attacks
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetValue(s.atlimit)
	c:RegisterEffect(e3)

	----------------------------------------------------------
	--(3) If destroyed by battle or card effect:
	--Place 1 En-Counter on your "SAO" Field Spell
	----------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_COUNTER)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetCondition(s.ctcon)
	e4:SetTarget(s.cttg)
	e4:SetOperation(s.ctop)
	c:RegisterEffect(e4)
end

s.listed_series={0x999,0x1999}
s.counter_place_list={0x1994}

----------------------------------------------------------
--(1) SPECIAL SUMMON FROM HAND
----------------------------------------------------------

--"SAO" monster, except an "SAO Boss" monster
function s.hspfilter(c)
	return c:IsMonster()
		and c:IsSetCard(0x999)
		and not c:IsSetCard(0x1999)
		and c:IsAbleToRemoveAsCost()
end

function s.hspcon(e,c)
	if c==nil then
		return true
	end

	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetMatchingGroupCount(
			s.hspfilter,
			tp,
			LOCATION_GRAVE,
			0,
			nil
		)>=3
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.hspfilter,
		tp,
		LOCATION_GRAVE,
		0,
		3,
		3,
		nil
	)

	if #g==3 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_COST
		)
	end
end

----------------------------------------------------------
--(2a) EFFECT-TARGETING PROTECTION
----------------------------------------------------------

--Protect OTHER "SAO" monsters.
--Skull Reaper itself remains targetable.
function s.prottg(e,c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c~=e:GetHandler()
end

----------------------------------------------------------
--(2b) BATTLE-TARGETING PROTECTION
----------------------------------------------------------

--The opponent cannot select another face-up "SAO"
--monster as an attack target.
--
--Skull Reaper itself remains a legal attack target.
function s.atlimit(e,c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c~=e:GetHandler()
end

----------------------------------------------------------
--(3) DESTROYED BY BATTLE OR CARD EFFECT
----------------------------------------------------------

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&(REASON_BATTLE|REASON_EFFECT))~=0
end

----------------------------------------------------------
--Find your face-up "SAO" Field Spell
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_FIELD)
		and c:IsSetCard(0x999)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fieldfilter,
			tp,
			LOCATION_FZONE,
			0,
			1,
			nil
		)
	end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(
		s.fieldfilter,
		tp,
		LOCATION_FZONE,
		0,
		nil
	)

	if tc then
		tc:AddCounter(0x1994,1)
	end
end