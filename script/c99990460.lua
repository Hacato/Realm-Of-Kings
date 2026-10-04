--SAO The World Tree
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Enable En-Counters
	----------------------------------------------------------
	c:EnableCounterPermit(COUNTER_EN)

	----------------------------------------------------------
	--(0) Activate
	----------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	----------------------------------------------------------
	--(1) Place En-Counters
	--Each time you Special Summon "SAO" monster(s)
	--from your Extra Deck, place 1 for each.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_FZONE)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Level change
	--Remove 1 En-Counter from your field;
	--increase or reduce 1 SAO monster's Level by up to 2.
	--Up to twice per turn.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(2,id)
	e2:SetCost(s.lvcost)
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(3) Destruction replacement
	--Once per turn, if this card would be destroyed
	--by a card effect, remove 3 En-Counters from
	--this card instead.
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.reptg)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) PLACE EN-COUNTERS
----------------------------------------------------------

function s.ctfilter(c,tp)
	return c:IsControler(tp)
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:GetSummonPlayer()==tp
		and c:GetSummonLocation()==LOCATION_EXTRA
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--World Tree must still be face-up.
	if not c:IsFaceup() then
		return
	end

	------------------------------------------------------
	--Count every SAO monster successfully Special
	--Summoned from your Extra Deck in this event.
	------------------------------------------------------
	local ct=eg:FilterCount(
		s.ctfilter,
		nil,
		tp
	)

	if ct>0 then
		c:AddCounter(COUNTER_EN,ct)
	end
end

----------------------------------------------------------
--(2) LEVEL CHANGE
----------------------------------------------------------

function s.lvcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--Only SAO monsters that actually have Levels.
--Xyz and Link Monsters are naturally excluded.
----------------------------------------------------------

function s.lvfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:HasLevel()
		and c:GetLevel()>0
end

function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.lvfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.lvfilter,
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
		s.lvfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_LVCHANGE,
		g,
		1,
		0,
		0
	)
end

----------------------------------------------------------
--Increase or reduce its Level by up to 2.
--
--Options:
-- +1
-- +2
-- -1 if legal
-- -2 if legal
----------------------------------------------------------

function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:HasLevel()
	then
		return
	end

	local lv=tc:GetLevel()

	if lv<=0 then
		return
	end

	local opts={}
	local vals={}

	------------------------------------------------------
	--Increase Level by 1
	------------------------------------------------------
	table.insert(
		opts,
		aux.Stringid(id,1)
	)
	table.insert(
		vals,
		1
	)

	------------------------------------------------------
	--Increase Level by 2
	------------------------------------------------------
	table.insert(
		opts,
		aux.Stringid(id,2)
	)
	table.insert(
		vals,
		2
	)

	------------------------------------------------------
	--Reduce Level by 1
	--Only available if Level will remain at least 1.
	------------------------------------------------------
	if lv>=2 then
		table.insert(
			opts,
			aux.Stringid(id,3)
		)
		table.insert(
			vals,
			-1
		)
	end

	------------------------------------------------------
	--Reduce Level by 2
	--Only available if Level will remain at least 1.
	------------------------------------------------------
	if lv>=3 then
		table.insert(
			opts,
			aux.Stringid(id,4)
		)
		table.insert(
			vals,
			-2
		)
	end

	local op=Duel.SelectOption(
		tp,
		table.unpack(opts)
	)

	local val=vals[op+1]

	if not val then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_LEVEL)
	e1:SetValue(val)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

----------------------------------------------------------
--(3) DESTRUCTION REPLACEMENT
----------------------------------------------------------

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return not c:IsReason(REASON_REPLACE+REASON_RULE)
			and c:IsReason(REASON_EFFECT)
			and c:IsCanRemoveCounter(
				tp,
				COUNTER_EN,
				3,
				REASON_EFFECT
			)
	end

	return Duel.SelectEffectYesNo(
		tp,
		c,
		aux.Stringid(id,5)
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	c:RemoveCounter(
		tp,
		COUNTER_EN,
		3,
		REASON_EFFECT
	)
end