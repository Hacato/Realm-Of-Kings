--SAO Boss, The Gleam Eyes
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
	--2 "SAO" monsters from your GY,
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
	--(2) If Special Summoned by the effect of an "SAO" card:
	--Target 1 monster your opponent controls; destroy it
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(3) If destroyed by battle or card effect:
	--Place 1 EN-Counter on your "SAO" Field Spell
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_COUNTER)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.ctcon)
	e3:SetTarget(s.cttg)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)
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
		)>=2
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.hspfilter,
		tp,
		LOCATION_GRAVE,
		0,
		2,
		2,
		nil
	)

	if #g==2 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_COST
		)
	end
end

----------------------------------------------------------
--(2) SPECIAL SUMMONED BY AN "SAO" CARD EFFECT
----------------------------------------------------------

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--There must actually be an effect responsible
	--for the Special Summon.
	------------------------------------------------------
	if not re then
		return false
	end

	local rc=re:GetHandler()

	------------------------------------------------------
	--The card whose effect performed the Summon
	--must be an "SAO" card.
	------------------------------------------------------
	return rc
		and rc:IsSetCard(0x999)
end

----------------------------------------------------------
--Target 1 monster opponent controls
----------------------------------------------------------

function s.desfilter(c)
	return c:IsMonster()
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.desfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.desfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)

	local g=Duel.SelectTarget(
		tp,
		s.desfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		1,
		0,
		0
	)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e) then
		Duel.Destroy(
			tc,
			REASON_EFFECT
		)
	end
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