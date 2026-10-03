--SAO Kirito - ALO B.
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--Synchro Summon
	--1 Tuner + 1 non-Tuner "SAO" monster
	----------------------------------------------------------
	Synchro.AddProcedure(
		c,
		nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,0x999),1,1
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) If Special Summoned:
	--Equip 1 "SAO Boss" monster from your hand or Deck,
	--and if you do, this card gains 500 ATK
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--Store Kirito's complete Equip Group immediately
	--before it leaves the field
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EVENT_LEAVE_FIELD_P)
	e2:SetOperation(s.eqcheck)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(2) If this face-up card leaves the field:
	--remove 1 EN-Counter;
	--Special Summon an SAO monster from your GY
	--that was equipped to this card
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetCountLimit(1,id)
	e3:SetLabelObject(e2)
	e3:SetCondition(s.spcon)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

----------------------------------------------------------
--(1) EQUIP "SAO BOSS"
----------------------------------------------------------

--0x1999 = SAO Boss
function s.eqfilter(c)
	return c:IsMonster()
		and c:IsSetCard(0x1999)
		and not c:IsForbidden()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.eqfilter,
				tp,
				LOCATION_HAND+LOCATION_DECK,
				0,
				1,
				nil
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		nil,
		1,
		tp,
		LOCATION_HAND+LOCATION_DECK
	)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or c:IsFacedown()
		or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)

	local g=Duel.SelectMatchingCard(
		tp,
		s.eqfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then
		return
	end

	if Duel.Equip(tp,tc,c,true) then

		--------------------------------------------------
		--Equip Limit
		--------------------------------------------------
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(c)
		tc:RegisterEffect(e1)

		--------------------------------------------------
		--And if you do, gain 500 ATK
		--------------------------------------------------
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(500)
		e2:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

----------------------------------------------------------
--CAPTURE COMPLETE EQUIP GROUP
----------------------------------------------------------

function s.eqcheck(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--This now follows Red-Eyes Slash Dragon's
	--implementation directly.
	------------------------------------------------------
	if e:GetLabelObject() then
		e:GetLabelObject():DeleteGroup()
	end

	local g=e:GetHandler():GetEquipGroup()

	------------------------------------------------------
	--DO NOT filter the group here.
	--Preserve the original Equip Group itself.
	------------------------------------------------------
	g:KeepAlive()

	e:SetLabelObject(g)
end

----------------------------------------------------------
--(2) LEAVE FIELD CONDITION
----------------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--Already confirmed working by our LP test.
	------------------------------------------------------
	return e:GetHandler():IsPreviousPosition(POS_FACEUP)
end

----------------------------------------------------------
--REMOVE 1 EN-COUNTER AS COST
----------------------------------------------------------

--0x1994 = EN-Counter
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			0x1994,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--TARGET
----------------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		--------------------------------------------------
		--Do not check the saved group here.
		--Allow the known-working leave-field trigger.
		--------------------------------------------------
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--FORMER EQUIPPED MONSTER FILTER
----------------------------------------------------------

function s.spfilter(c,e,tp)
	------------------------------------------------------
	--This group ALREADY consists exclusively of cards
	--that were equipped to this Kirito.
	--
	--Now we only care whether the card:
	--1. reached our GY
	--2. is a monster
	--3. is an SAO monster
	--4. can be Special Summoned
	------------------------------------------------------
	return c:IsLocation(LOCATION_GRAVE)
		and c:IsControler(tp)
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false,
			POS_FACEUP_DEFENSE
		)
end

----------------------------------------------------------
--SPECIAL SUMMON
----------------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--Retrieve EVENT_LEAVE_FIELD_P effect
	------------------------------------------------------
	local pe=e:GetLabelObject()

	if not pe then
		return
	end

	------------------------------------------------------
	--Retrieve the preserved Equip Group
	------------------------------------------------------
	local g=pe:GetLabelObject()

	if not g then
		return
	end

	------------------------------------------------------
	--Filter that original Equip Group NOW,
	--after Kirito and its Equip Cards have left.
	------------------------------------------------------
	local sg=g:Filter(
		s.spfilter,
		nil,
		e,
		tp
	)

	if #sg==0 then
		g:DeleteGroup()
		pe:SetLabelObject(nil)
		return
	end

	------------------------------------------------------
	--Need an open Monster Zone
	------------------------------------------------------
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		g:DeleteGroup()
		pe:SetLabelObject(nil)
		return
	end

	------------------------------------------------------
	--Select 1 former equipped SAO monster
	------------------------------------------------------
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local tc=sg:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if tc then
		--------------------------------------------------
		--Special Summon in Defense Position
		--------------------------------------------------
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP_DEFENSE
		)
	end

	------------------------------------------------------
	--Clean up preserved group
	------------------------------------------------------
	g:DeleteGroup()
	pe:SetLabelObject(nil)
end