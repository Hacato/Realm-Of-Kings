--SAO Kirito - OS
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Link Summon
	--2 "SAO" monsters, except Tuners
	----------------------------------------------------------
	Link.AddProcedure(c,s.linkmatfilter,2,2)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) If Link Summoned:
	--Add 1 Level 4 or lower "SAO" monster from Deck.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) If an "SAO" Link Monster is Special Summoned
	--to a zone this card points to:
	--Remove 2 En-Counters, target 1 "SAO" monster in GY;
	--Special Summon it.
	--Then lock into "SAO" monsters for the rest of turn.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--LINK MATERIAL
----------------------------------------------------------

function s.linkmatfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_SAO,lc,sumtype,tp)
		and not c:IsType(TYPE_TUNER,lc,sumtype,tp)
end

----------------------------------------------------------
--(1) SEARCH
----------------------------------------------------------

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:HasLevel()
		and c:IsLevelBelow(4)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

----------------------------------------------------------
--(2) LINK MONSTER SUMMONED TO LINKED ZONE
----------------------------------------------------------

function s.spconfilter(c,tp,lg)
	return c:IsControler(tp)
		and c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_LINK)
		and c:IsLocation(LOCATION_MZONE)
		and lg:IsContains(c)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup() then
		return false
	end

	local lg=c:GetLinkedGroup()

	return eg:IsExists(
		s.spconfilter,
		1,
		nil,
		tp,
		lg
	)
end

----------------------------------------------------------
--Remove 2 En-Counters.
----------------------------------------------------------

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			2,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)
end

----------------------------------------------------------
--GY TARGET
----------------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

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

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

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
--SPECIAL SUMMON + SAO LOCK
----------------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	then
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

	------------------------------------------------------
	--For the rest of this turn:
	--cannot Special Summon except "SAO" monsters.
	--
	--This applies after the effect resolves even if
	--the target is no longer able to be summoned.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SET_SAO)
end