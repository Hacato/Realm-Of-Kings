--SAO Illusion Incantation
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local SET_SAO_BOSS=0x1999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) Send 1 SAO monster Special Summoned from the
	--Extra Deck to the GY; Special Summon 1 SAO Boss
	--from the GY and copy the sent monster's original
	--ATK/DEF.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) GY effect
	--During your Main Phase, except the turn this card
	--was sent to the GY:
	--Banish this card + remove 1 En-Counter;
	--add 1 SAO Boss from GY to hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO,SET_SAO_BOSS}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) SPECIAL SUMMON SAO BOSS
----------------------------------------------------------

----------------------------------------------------------
--Monster to send:
--Must be:
-- • face-up
-- • controlled by you
-- • an SAO monster
-- • originally Special Summoned from the Extra Deck
-- • able to be sent to the GY as cost
----------------------------------------------------------

function s.spcostfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:GetSummonLocation()==LOCATION_EXTRA
		and c:IsAbleToGraveAsCost()
end

----------------------------------------------------------
--COST
--
--Send the SAO monster and remember its ORIGINAL
--ATK and DEF before it changes location.
----------------------------------------------------------

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.spcostfilter,
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
		HINTMSG_TOGRAVE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spcostfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	------------------------------------------------------
	--Store original ATK/DEF before sending it.
	------------------------------------------------------

	e:SetLabel(
		tc:GetBaseAttack(),
		tc:GetBaseDefense()
	)

	Duel.SendtoGrave(
		tc,
		REASON_COST
	)
end

----------------------------------------------------------
--SAO BOSS FILTER
----------------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SAO_BOSS)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

----------------------------------------------------------
--TARGET SAO BOSS IN GY
----------------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.spfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectTarget(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--SPECIAL SUMMON THE SAO BOSS
--Then set its ATK/DEF to the sent monster's
--original ATK/DEF.
----------------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	local atk,def=e:GetLabel()

	if Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	------------------------------------------------------
	--Its ATK becomes the original ATK of the sent monster.
	------------------------------------------------------

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK)
	e1:SetValue(atk)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	------------------------------------------------------
	--Its DEF becomes the original DEF of the sent monster.
	------------------------------------------------------

	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SET_DEFENSE)
	e2:SetValue(def)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)
end

----------------------------------------------------------
--(2) GY EFFECT
----------------------------------------------------------

----------------------------------------------------------
--Except the turn this card was sent to the GY.
----------------------------------------------------------

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--COST
--Banish this card + remove 1 En-Counter.
----------------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--SAO BOSS THAT CAN BE ADDED
----------------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(SET_SAO_BOSS)
		and c:IsMonster()
		and c:IsAbleToHand()
end

----------------------------------------------------------
--TARGET SAO BOSS
----------------------------------------------------------

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
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
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--ADD SAO BOSS TO HAND
----------------------------------------------------------

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	if Duel.SendtoHand(
		tc,
		nil,
		REASON_EFFECT
	)~=0 then
		Duel.ConfirmCards(
			1-tp,
			tc
		)
	end
end