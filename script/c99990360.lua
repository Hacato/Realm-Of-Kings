--SAO Edge of The World
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) When activated:
	--You can place 1 En-Counter on your "SAO" Field Spell.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Remove 1 En-Counter;
	--excavate the top 3 cards of your Deck,
	--optionally add 1 excavated SAO card,
	--then shuffle the rest into the Deck.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.excost)
	e2:SetTarget(s.extg)
	e2:SetOperation(s.exop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) PLACE EN-COUNTER
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_FIELD)
		and c:IsCanAddCounter(COUNTER_EN,1)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	local tc=Duel.GetFieldCard(
		tp,
		LOCATION_FZONE,
		0
	)

	------------------------------------------------------
	--Counter placement is optional.
	------------------------------------------------------
	if tc
		and s.fieldfilter(tc)
		and Duel.SelectYesNo(tp,aux.Stringid(id,0))
	then
		e:SetLabel(1)

		Duel.SetOperationInfo(
			0,
			CATEGORY_COUNTER,
			tc,
			1,
			tp,
			COUNTER_EN
		)
	else
		e:SetLabel(0)
	end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()~=1 then
		return
	end

	if not e:GetHandler():IsRelateToEffect(e) then
		return
	end

	local tc=Duel.GetFieldCard(
		tp,
		LOCATION_FZONE,
		0
	)

	if tc
		and s.fieldfilter(tc)
	then
		tc:AddCounter(
			COUNTER_EN,
			1
		)
	end
end

----------------------------------------------------------
--(2) EXCAVATE
----------------------------------------------------------

function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--Need at least 3 cards remaining in the Deck.
----------------------------------------------------------

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(
			tp,
			LOCATION_DECK,
			0
		)>=3
	end
end

----------------------------------------------------------
--Any excavated SAO card can be added.
--Monster, Spell, or Trap.
----------------------------------------------------------

function s.exfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsAbleToHand()
end

function s.exop(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--Must still have at least 3 cards to excavate.
	------------------------------------------------------
	if Duel.GetFieldGroupCount(
		tp,
		LOCATION_DECK,
		0
	)<3 then
		return
	end

	------------------------------------------------------
	--Excavate top 3.
	------------------------------------------------------
	Duel.ConfirmDecktop(
		tp,
		3
	)

	local g=Duel.GetDecktopGroup(
		tp,
		3
	)

	------------------------------------------------------
	--If at least 1 excavated card is an SAO card,
	--player may add exactly 1 of them.
	------------------------------------------------------
	local sg=g:Filter(
		s.exfilter,
		nil
	)

	if #sg>0
		and Duel.SelectYesNo(
			tp,
			aux.Stringid(id,2)
		)
	then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_ATOHAND
		)

		local tg=sg:Select(
			tp,
			1,
			1,
			nil
		)

		if #tg>0 then
			Duel.SendtoHand(
				tg,
				nil,
				REASON_EFFECT
			)

			Duel.ConfirmCards(
				1-tp,
				tg
			)
		end
	end

	------------------------------------------------------
	--Shuffle the remaining excavated cards back
	--into the Deck.
	------------------------------------------------------
	Duel.ShuffleDeck(tp)
end