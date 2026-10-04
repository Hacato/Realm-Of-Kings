--SAO Limitless Combat
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Remove any number of En-Counters from your field,
	--then target 1 "SAO" monster you control;
	--it gains that many additional attacks this turn,
	--but your opponent takes no battle damage from
	--battles involving that monster.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.aacost)
	e1:SetTarget(s.aatg)
	e1:SetOperation(s.aaop)
	c:RegisterEffect(e1)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--COST:
--REMOVE ANY NUMBER OF EN-COUNTERS
----------------------------------------------------------

function s.aacost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetCounter(
		tp,
		1,
		0,
		COUNTER_EN
	)

	if chk==0 then
		return ct>0
	end

	------------------------------------------------------
	--Choose how many En-Counters to remove.
	------------------------------------------------------
	local ac=1

	if ct>1 then
		local t={}

		for i=1,ct do
			t[i]=i
		end

		ac=Duel.AnnounceNumber(
			tp,
			table.unpack(t)
		)
	end

	------------------------------------------------------
	--Remove exactly the chosen number.
	------------------------------------------------------
	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		ac,
		REASON_COST
	)

	------------------------------------------------------
	--Remember how many were removed.
	------------------------------------------------------
	e:SetLabel(ac)
end

----------------------------------------------------------
--TARGET 1 FACE-UP "SAO" MONSTER YOU CONTROL
----------------------------------------------------------

function s.aafilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(SET_SAO)
end

function s.aatg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.aafilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.aafilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local g=Duel.SelectTarget(
		tp,
		s.aafilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_ATKCHANGE,
		g,
		1,
		0,
		0
	)
end

----------------------------------------------------------
--APPLY EFFECTS
----------------------------------------------------------

function s.aaop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
	then
		return
	end

	local ct=e:GetLabel()

	if ct<=0 then
		return
	end

	------------------------------------------------------
	--GAIN 1 ADDITIONAL ATTACK FOR EACH EN-COUNTER
	--REMOVED.
	--
	--EFFECT_EXTRA_ATTACK allows additional attacks
	--including direct attacks.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK)
	e1:SetValue(ct)
	e1:SetReset(
		RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END
	)
	tc:RegisterEffect(e1)

	------------------------------------------------------
	--OPPONENT TAKES NO BATTLE DAMAGE FROM BATTLES
	--INVOLVING THIS MONSTER FOR THE REST OF THIS TURN.
	------------------------------------------------------
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_NO_BATTLE_DAMAGE)
	e2:SetReset(
		RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END
	)
	tc:RegisterEffect(e2)
end