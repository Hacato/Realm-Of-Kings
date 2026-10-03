--SAO Silica - ALO
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
	--(1) Quick Effect:
	--Remove 1 En-Counter, then target 1 "SAO" monster
	--you control; equip 1 "SAO Pina" from Deck/GY to it.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCost(s.eqcost)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) If your "SAO" monster battles an opponent's
	--monster, opponent cannot activate Spell/Trap Cards
	--that are already on the field until end Damage Step.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.actcon)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.listed_names={99990110}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--TARGET 1 "SAO" MONSTER YOU CONTROL
----------------------------------------------------------

function s.eqtgfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
end

----------------------------------------------------------
--"SAO Pina"
--ID: 99990110
----------------------------------------------------------

function s.eqfilter(c)
	return c:IsCode(99990110)
		and not c:IsForbidden()
end

----------------------------------------------------------
--TARGET
----------------------------------------------------------

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.eqtgfilter(chkc)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(
				s.eqtgfilter,
				tp,
				LOCATION_MZONE,
				0,
				1,
				nil
			)
			and Duel.IsExistingMatchingCard(
				aux.NecroValleyFilter(s.eqfilter),
				tp,
				LOCATION_DECK|LOCATION_GRAVE,
				0,
				1,
				nil
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	local g=Duel.SelectTarget(
		tp,
		s.eqtgfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		nil,
		1,
		tp,
		LOCATION_DECK|LOCATION_GRAVE
	)
end

----------------------------------------------------------
--EQUIP "SAO PINA"
----------------------------------------------------------

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsControler(tp)
		or not tc:IsLocation(LOCATION_MZONE) then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		aux.NecroValleyFilter(s.eqfilter),
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,
		1,
		nil
	) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)

	local g=Duel.SelectMatchingCard(
		tp,
		aux.NecroValleyFilter(s.eqfilter),
		tp,
		LOCATION_DECK|LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	local ec=g:GetFirst()

	if not ec then
		return
	end

	------------------------------------------------------
	--Equip Pina to the targeted "SAO" monster.
	------------------------------------------------------
	if not Duel.Equip(tp,ec,tc,true) then
		return
	end

	------------------------------------------------------
	--Pina can only remain equipped to that exact monster.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(s.eqlimit)
	e1:SetLabelObject(tc)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	ec:RegisterEffect(e1)
end

----------------------------------------------------------
--EQUIP LIMIT
----------------------------------------------------------

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

----------------------------------------------------------
--(2) CHECK IF YOUR "SAO" MONSTER IS BATTLING
--AN OPPONENT'S MONSTER
----------------------------------------------------------

function s.actcon(e)
	local tp=e:GetHandlerPlayer()

	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	if not a or not d then
		return false
	end

	------------------------------------------------------
	--Your monster is attacking opponent's monster.
	------------------------------------------------------
	if a:IsControler(tp)
		and d:IsControler(1-tp)
		and a:IsFaceup()
		and a:IsMonster()
		and a:IsSetCard(0x999) then
		return true
	end

	------------------------------------------------------
	--Opponent's monster is attacking your "SAO" monster.
	------------------------------------------------------
	if a:IsControler(1-tp)
		and d:IsControler(tp)
		and d:IsFaceup()
		and d:IsMonster()
		and d:IsSetCard(0x999) then
		return true
	end

	return false
end

----------------------------------------------------------
--OPPONENT CANNOT ACTIVATE SPELL/TRAP CARDS
--THAT ARE ON THE FIELD
----------------------------------------------------------

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()

	return re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and rc:IsLocation(LOCATION_ONFIELD)
end