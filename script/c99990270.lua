--SAO Guns and Swords
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) At the end of the Damage Step, if your "SAO"
	--non-Xyz monster battled an opponent's monster and
	--was not destroyed by that battle:
	--Target it; Special Summon 1 "SAO" Xyz Monster
	--using that target as material.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_DAMAGE_STEP_END)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.xyzcon)
	e1:SetTarget(s.xyztg)
	e1:SetOperation(s.xyzop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) During your Main Phase, except the turn this
	--card was sent to the GY:
	--Banish this card and remove 1 En-Counter,
	--then target 1 "SAO" Xyz Monster in your GY;
	--return it to the Extra Deck, and if you do,
	--add 1 Level 4 "SAO" monster from your GY
	--to your hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.reccon)
	e2:SetCost(s.reccost)
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) BATTLE CHECK
----------------------------------------------------------

--This returns YOUR SAO non-Xyz monster only if:
--  1. It actually battled an opponent's monster.
--  2. It is an SAO monster.
--  3. It is not an Xyz Monster.
--  4. It survived that battle.
--  5. It is still face-up in your Monster Zone.
function s.getbattlemonster(tp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	------------------------------------------------------
	--There must have actually been 2 battling monsters.
	--This prevents direct attacks from qualifying.
	------------------------------------------------------
	if not a or not d then
		return nil
	end

	------------------------------------------------------
	--CASE 1:
	--Your SAO monster was the attacker.
	------------------------------------------------------
	if a:IsControler(tp)
		and d:IsControler(1-tp)
		and a:IsSetCard(SET_SAO)
		and a:IsMonster()
		and not a:IsType(TYPE_XYZ)
		and a:IsFaceup()
		and a:IsLocation(LOCATION_MZONE)
		and not a:IsStatus(STATUS_BATTLE_DESTROYED)
	then
		return a
	end

	------------------------------------------------------
	--CASE 2:
	--Your SAO monster was attacked.
	------------------------------------------------------
	if d:IsControler(tp)
		and a:IsControler(1-tp)
		and d:IsSetCard(SET_SAO)
		and d:IsMonster()
		and not d:IsType(TYPE_XYZ)
		and d:IsFaceup()
		and d:IsLocation(LOCATION_MZONE)
		and not d:IsStatus(STATUS_BATTLE_DESTROYED)
	then
		return d
	end

	return nil
end

----------------------------------------------------------
--ACTIVATION CONDITION
----------------------------------------------------------

function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	return s.getbattlemonster(tp)~=nil
end

----------------------------------------------------------
--VALID "SAO" XYZ MONSTER
----------------------------------------------------------

function s.xyzfilter(c,e,tp,mc)
	return c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_XYZ)
		and mc:IsCanBeXyzMaterial(c,tp)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_XYZ,
			tp,
			false,
			false
		)
end

----------------------------------------------------------
--TARGET THE SAO MONSTER THAT ACTUALLY BATTLED
----------------------------------------------------------

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local tc=s.getbattlemonster(tp)

	if chkc then
		return tc and chkc==tc
	end

	if chk==0 then
		if not tc then
			return false
		end

		return tc:IsCanBeEffectTarget(e)
			and Duel.GetLocationCountFromEx(tp,tp,tc)>0
			and Duel.IsExistingMatchingCard(
				s.xyzfilter,
				tp,
				LOCATION_EXTRA,
				0,
				1,
				nil,
				e,
				tp,
				tc
			)
	end

	------------------------------------------------------
	--The battling monster is the target.
	------------------------------------------------------
	Duel.SetTargetCard(tc)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end

----------------------------------------------------------
--SPECIAL SUMMON THE XYZ
----------------------------------------------------------

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	------------------------------------------------------
	--The targeted SAO monster must still be valid.
	------------------------------------------------------
	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsControler(tp)
		or not tc:IsLocation(LOCATION_MZONE)
		or not tc:IsSetCard(SET_SAO)
		or tc:IsType(TYPE_XYZ)
	then
		return
	end

	if Duel.GetLocationCountFromEx(tp,tp,tc)<=0 then
		return
	end

	------------------------------------------------------
	--Find SAO Xyz Monsters capable of using this monster
	--as material.
	------------------------------------------------------
	local g=Duel.GetMatchingGroup(
		s.xyzfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		tc
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local sc=g:Select(tp,1,1,nil):GetFirst()

	if not sc then
		return
	end

	------------------------------------------------------
	--Transfer existing Xyz materials if relevant.
	--Normally this won't matter because the target
	--cannot itself be an Xyz Monster.
	------------------------------------------------------
	local og=tc:GetOverlayGroup()

	if #og>0 then
		Duel.Overlay(sc,og)
	end

	------------------------------------------------------
	--Use ONLY the targeted battling SAO monster
	--as the material.
	------------------------------------------------------
	local mg=Group.FromCards(tc)

	sc:SetMaterial(mg)
	Duel.Overlay(sc,mg)

	------------------------------------------------------
	--Special Summon it as a proper Xyz Summon.
	------------------------------------------------------
	if Duel.SpecialSummon(
		sc,
		SUMMON_TYPE_XYZ,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)~=0 then
		sc:CompleteProcedure()
	end
end

----------------------------------------------------------
--(2) GY EFFECT
----------------------------------------------------------

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	------------------------------------------------------
	--Cannot use this effect during the turn this card
	--was sent to the GY.
	------------------------------------------------------
	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--COST
--Banish this card and remove 1 En-Counter.
----------------------------------------------------------

function s.reccost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
			and Duel.IsCanRemoveCounter(
				tp,
				1,
				0,
				COUNTER_EN,
				1,
				REASON_COST
			)
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)

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
--"SAO" XYZ MONSTER IN GY
----------------------------------------------------------

function s.exfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_XYZ)
		and c:IsMonster()
		and c:IsAbleToExtra()
end

----------------------------------------------------------
--LEVEL 4 "SAO" MONSTER IN GY
----------------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:HasLevel()
		and c:IsLevel(4)
		and c:IsAbleToHand()
end

----------------------------------------------------------
--TARGET SAO XYZ
----------------------------------------------------------

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.exfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.exfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
			and Duel.IsExistingMatchingCard(
				s.thfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local g=Duel.SelectTarget(
		tp,
		s.exfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--RETURN XYZ TO EXTRA DECK,
--THEN ADD LEVEL 4 SAO MONSTER
----------------------------------------------------------

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	if Duel.SendtoDeck(
		tc,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==0 then
		return
	end

	------------------------------------------------------
	--The Xyz must actually reach the Extra Deck.
	------------------------------------------------------
	if not tc:IsLocation(LOCATION_EXTRA) then
		return
	end

	------------------------------------------------------
	--"and if you do"
	------------------------------------------------------
	local g=Duel.GetMatchingGroup(
		s.thfilter,
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
		HINTMSG_ATOHAND
	)

	local sg=g:Select(tp,1,1,nil)

	if #sg>0 then
		Duel.SendtoHand(
			sg,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			sg
		)
	end
end