--SAO Hidden Potential Leafa - ALO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	--Synchro Summon
	Synchro.AddProcedure(c,nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,SET_SAO),1,99)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) If Synchro Summoned:
	--Target 1 other SAO monster;
	--gain LP equal to half its current ATK,
	--then this card gains ATK equal to half the LP gained
	--until the end of the next turn.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_RECOVER+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.reccon)
	e1:SetTarget(s.rectg)
	e1:SetOperation(s.recop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) During the turn this card was Special Summoned:
	--Remove 1 En-Counter;
	--return another SAO Synchro to Extra Deck,
	--then optionally revive all of its original materials
	--if all of them are currently in your GY.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.retcon)
	e2:SetCost(s.retcost)
	e2:SetTarget(s.rettg)
	e2:SetOperation(s.retop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) LP RECOVERY / ATK GAIN
----------------------------------------------------------

function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

function s.recfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:GetAttack()>0
end

function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and chkc~=c
			and s.recfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.recfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			c
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	local g=Duel.SelectTarget(
		tp,
		s.recfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		c
	)

	local tc=g:GetFirst()

	if tc then
		Duel.SetOperationInfo(
			0,
			CATEGORY_RECOVER,
			nil,
			0,
			tp,
			math.floor(tc:GetAttack()/2)
		)
	end
end

function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
	then
		return
	end

	local atk=tc:GetAttack()

	if atk<=0 then
		return
	end

	------------------------------------------------------
	--Gain LP equal to half the target's current ATK.
	------------------------------------------------------
	local amount=math.floor(atk/2)

	local recovered=Duel.Recover(
		tp,
		amount,
		REASON_EFFECT
	)

	------------------------------------------------------
	--"and if you do"
	--Leafa gains ATK equal to half the amount actually
	--recovered.
	------------------------------------------------------
	if recovered<=0
		or not c:IsFaceup()
		or not c:IsRelateToEffect(e)
	then
		return
	end

	local gain=math.floor(recovered/2)

	if gain<=0 then
		return
	end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(gain)

	------------------------------------------------------
	--End of the next turn.
	--RESET_SELF_TURN/RESET_OPPO_TURN is intentionally
	--not used here; count two End Phases beginning with
	--the current turn.
	------------------------------------------------------
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,
		2
	)

	c:RegisterEffect(e1)
end

----------------------------------------------------------
--(2) RETURN SYNCHRO / REVIVE MATERIALS
----------------------------------------------------------

--Only during the turn Leafa was Special Summoned.
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:GetTurnID()==Duel.GetTurnCount()
end

----------------------------------------------------------
--Remove 1 En-Counter.
----------------------------------------------------------

function s.retcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--Another SAO Synchro Monster.
----------------------------------------------------------

function s.retfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_SYNCHRO)
		and c:IsAbleToExtra()
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and chkc~=c
			and s.retfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.retfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			c
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)

	local g=Duel.SelectTarget(
		tp,
		s.retfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		c
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		g,
		1,
		tp,
		LOCATION_MZONE
	)
end

----------------------------------------------------------
--Check an original Synchro Material.
----------------------------------------------------------

function s.matfilter(c,e,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_GRAVE)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
	then
		return
	end

	------------------------------------------------------
	--Save its original Synchro Material group BEFORE
	--returning the Synchro Monster to the Extra Deck.
	------------------------------------------------------
	local mg=tc:GetMaterial()

	------------------------------------------------------
	--Return the targeted Synchro Monster to Extra Deck.
	------------------------------------------------------
	if Duel.SendtoDeck(
		tc,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==0 then
		return
	end

	if not tc:IsLocation(LOCATION_EXTRA) then
		return
	end

	------------------------------------------------------
	--"and if you do, if all Synchro Materials..."
	--
	--No materials recorded = nothing to revive.
	------------------------------------------------------
	if not mg or #mg==0 then
		return
	end

	local ct=#mg

	------------------------------------------------------
	--Every original material must currently:
	--  * be in your GY
	--  * still be controlled/owned as appropriate
	--  * be capable of being Special Summoned
	------------------------------------------------------
	if mg:FilterCount(
		aux.NecroValleyFilter(s.matfilter),
		nil,
		e,
		tp
	)~=ct then
		return
	end

	------------------------------------------------------
	--Need enough available Monster Zones for ALL of them.
	------------------------------------------------------
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<ct then
		return
	end

	------------------------------------------------------
	--The Special Summon is optional: "you can".
	------------------------------------------------------
	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	) then
		return
	end

	Duel.SpecialSummon(
		mg,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)
end