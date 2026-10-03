--SAO Klein - ALO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local SET_SAO_BOSS=6553
local COUNTER_EN=0x1994

function s.initial_effect(c)
	--Synchro Summon
	--1 Tuner + 1 non-Tuner "SAO" monster
	Synchro.AddProcedure(
		c,
		nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,SET_SAO),1,1
	)
	c:EnableReviveLimit()

	--(1) During the turn this card was Special Summoned:
	--Draw 1 card and reveal it.
	--If it is a non-Boss "SAO" monster, you can Special Summon it.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	--(2) If you Special Summon another "SAO" monster:
	--Remove 1 En-Counter, then target 1 of those monsters;
	--equip this card to it.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.eqcon)
	e2:SetCost(s.eqcost)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO,SET_SAO_BOSS}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) DRAW EFFECT
----------------------------------------------------------

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetTurnID()==Duel.GetTurnCount()
		and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER
	)

	if Duel.Draw(p,1,REASON_EFFECT)==0 then
		return
	end

	local g=Duel.GetOperatedGroup()
	local tc=g:GetFirst()

	if not tc then
		return
	end

	--Reveal the drawn card
	Duel.ConfirmCards(1-tp,tc)

	--It must still be in our hand
	if not tc:IsLocation(LOCATION_HAND)
		or not tc:IsControler(tp) then
		return
	end

	--Must be an "SAO" monster
	--and NOT an "SAO Boss" monster
	if not tc:IsMonster()
		or not tc:IsSetCard(SET_SAO)
		or tc:IsSetCard(SET_SAO_BOSS) then

		Duel.ShuffleHand(tp)
		return
	end

	--Check if it can be Special Summoned
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not tc:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		) then

		Duel.ShuffleHand(tp)
		return
	end

	--Optional Special Summon
	if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end

	Duel.ShuffleHand(tp)
end

----------------------------------------------------------
--(2) EQUIP EFFECT
----------------------------------------------------------

--Must be another "SAO" monster that was just
--Special Summoned by this card's controller.
function s.eqfilter(c,tp,sc)
	return c~=sc
		and c:IsFaceup()
		and c:IsControler(tp)
		and c:GetSummonPlayer()==tp
		and c:IsMonster()
		and c:IsSetCard(SET_SAO)
end

----------------------------------------------------------
--CHECK THE SPECIAL SUMMON EVENT
----------------------------------------------------------

function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return eg:IsExists(
		s.eqfilter,
		1,
		nil,
		tp,
		c
	)
end

----------------------------------------------------------
--REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--TARGET 1 OF THOSE SPECIAL SUMMONED "SAO" MONSTERS
----------------------------------------------------------

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return eg:IsContains(chkc)
			and s.eqfilter(chkc,tp,c)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and eg:IsExists(
				s.eqfilter,
				1,
				nil,
				tp,
				c
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local g=eg:FilterSelect(
		tp,
		s.eqfilter,
		1,
		1,
		nil,
		tp,
		c
	)

	Duel.SetTargetCard(g)

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		c,
		1,
		tp,
		LOCATION_MZONE
	)
end

----------------------------------------------------------
--EQUIP KLEIN TO TARGET
----------------------------------------------------------

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	--Target must still be valid
	if not tc
		or tc==c
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsControler(tp)
		or not tc:IsLocation(LOCATION_MZONE) then
		return
	end

	--Klein must still be face-up in the Monster Zone
	if not c:IsFaceup()
		or not c:IsRelateToEffect(e)
		or not c:IsLocation(LOCATION_MZONE) then
		return
	end

	--Need an available Spell/Trap Zone
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	------------------------------------------------------
	--Remember Klein's original ATK BEFORE equipping him.
	------------------------------------------------------
	local atk=c:GetBaseAttack()

	------------------------------------------------------
	--Equip Klein to the selected monster
	------------------------------------------------------
	if not Duel.Equip(tp,c,tc,true) then
		return
	end

	------------------------------------------------------
	--Equip limit
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(s.eqlimit)
	e1:SetLabelObject(tc)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e1)

	------------------------------------------------------
	--Equipped monster gains half Klein's original ATK
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(math.floor(atk/2))
	e2:SetReset(RESET_EVENT|RESETS_STANDARD)
	c:RegisterEffect(e2)
end

----------------------------------------------------------
--EQUIP LIMIT
----------------------------------------------------------

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end