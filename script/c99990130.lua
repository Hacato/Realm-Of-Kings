--SAO Boss, Illfang the Kobold Lord
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
	--1 "SAO" monster from your GY,
	--except an "SAO Boss" monster
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
	--(2) Once per turn:
	--Special Summon 1 Ruin Kobold Sentinel Token,
	--or up to 2 if opponent controls more monsters
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
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
s.listed_names={99990135}
s.counter_place_list={0x1994}

----------------------------------------------------------
--(1) SPECIAL SUMMON FROM HAND
----------------------------------------------------------

--Must be an "SAO" monster,
--but NOT an "SAO Boss" monster.
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
		and Duel.IsExistingMatchingCard(
			s.hspfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
end

function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.hspfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_COST
		)
	end
end

----------------------------------------------------------
--(2) RUIN KOBOLD SENTINEL TOKEN
--
--Token ID: 99990135
--DARK / Beast-Warrior / Level 4
--ATK 1000 / DEF 1000
----------------------------------------------------------

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(
				tp,
				99990135,
				0x999,
				TYPE_TOKEN,
				1000,
				1000,
				4,
				RACE_BEASTWARRIOR,
				ATTRIBUTE_DARK
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOKEN,
		nil,
		1,
		tp,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		0
	)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)

	if ft<=0 then
		return
	end

	if not Duel.IsPlayerCanSpecialSummonMonster(
		tp,
		99990135,
		0x999,
		TYPE_TOKEN,
		1000,
		1000,
		4,
		RACE_BEASTWARRIOR,
		ATTRIBUTE_DARK
	) then
		return
	end

	------------------------------------------------------
	--Normally summon exactly 1.
	------------------------------------------------------
	local ct=1

	------------------------------------------------------
	--If opponent controls more monsters than you,
	--you may summon up to 2 instead.
	------------------------------------------------------
	local yourmon=Duel.GetFieldGroupCount(
		tp,
		LOCATION_MZONE,
		0
	)

	local oppmon=Duel.GetFieldGroupCount(
		tp,
		0,
		LOCATION_MZONE
	)

	if oppmon>yourmon and ft>=2 then
		--------------------------------------------------
		--String 3 can be:
		--"Special Summon 2 Tokens?"
		--
		--If you don't have String 3 yet, this can
		--instead use a generic option later.
		--------------------------------------------------
		if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			ct=2
		end
	end

	------------------------------------------------------
	--Never exceed available Monster Zones
	------------------------------------------------------
	ct=math.min(ct,ft)

	------------------------------------------------------
	--Special Summon the selected number of Tokens
	------------------------------------------------------
	for i=1,ct do
		local token=Duel.CreateToken(tp,99990135)

		Duel.SpecialSummonStep(
			token,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end

	Duel.SpecialSummonComplete()
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