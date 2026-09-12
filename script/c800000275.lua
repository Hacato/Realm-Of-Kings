--Graphack, Chaos Dragon of Dark World
local s,id=GetID()

local CARD_GATES=33017655
local CARD_GRAPHA=34230233

function s.initial_effect(c)
	c:EnableReviveLimit()

	--2+ Fiend monsters, including a "Dark World" monster
	Link.AddProcedure(c,s.matfilter,2,99,s.lcheck)

	--When this card is Link Summoned:
	--Activate 1 "The Gates of Dark World" from hand, Deck or GY.
	--If "The Gates of Dark World" is already face-up in your Field Zone,
	--add 1 "Dark World" card from your Deck to your hand instead.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.gatecon)
	e1:SetTarget(s.gatetg)
	e1:SetOperation(s.gateop)
	c:RegisterEffect(e1)

	--If this card would be destroyed by battle or card effect,
	--discard 1 "Dark World" card instead.
	--If the discarded card is a monster,
	--this card gains ATK equal to half its original ATK.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	--GY revival
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_DARK_WORLD}
s.listed_names={CARD_GATES,CARD_GRAPHA}

--==================================================
-- Link Materials
-- 2+ Fiend monsters, including a Dark World monster
--==================================================

function s.matfilter(c,lc,sumtype,tp)
	return c:IsRace(RACE_FIEND,lc,sumtype,tp)
end

function s.dwmatfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
end

function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(s.dwmatfilter,1,nil)
end

--==================================================
-- Effect 1
-- Link Summon:
-- Activate Gates, or search if Gates is already active
--==================================================

function s.gatecon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.faceupgates(c)
	return c:IsFaceup()
		and c:IsCode(CARD_GATES)
end

function s.gatesfilter(c)
	return c:IsCode(CARD_GATES)
		and c:IsType(TYPE_FIELD)
end

function s.searchfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsAbleToHand()
end

function s.gatetg(e,tp,eg,ep,ev,re,r,rp,chk)
	local hasgates=Duel.IsExistingMatchingCard(
		s.faceupgates,
		tp,
		LOCATION_FZONE,
		0,
		1,
		nil
	)

	if hasgates then
		if chk==0 then
			return Duel.IsExistingMatchingCard(
				s.searchfilter,
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
	else
		if chk==0 then
			return Duel.IsExistingMatchingCard(
				s.gatesfilter,
				tp,
				LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,
				0,
				1,
				nil
			)
		end
	end
end

function s.gateop(e,tp,eg,ep,ev,re,r,rp)

	--Check again at resolution
	if Duel.IsExistingMatchingCard(
		s.faceupgates,
		tp,
		LOCATION_FZONE,
		0,
		1,
		nil
	) then

		if not Duel.IsExistingMatchingCard(
			s.searchfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		) then
			return
		end

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_ATOHAND
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.searchfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			1,
			nil
		)

		if #g>0 then
			Duel.SendtoHand(
				g,
				nil,
				REASON_EFFECT
			)

			Duel.ConfirmCards(
				1-tp,
				g
			)
		end

		return
	end

	local g=Duel.GetMatchingGroup(
		s.gatesfilter,
		tp,
		LOCATION_HAND|LOCATION_DECK|LOCATION_GRAVE,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TOFIELD
	)

	local tc=g:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not tc then
		return
	end

	--Remove the current Field Spell if necessary
	local fc=Duel.GetFieldCard(
		tp,
		LOCATION_FZONE,
		0
	)

	if fc then
		Duel.SendtoGrave(
			fc,
			REASON_RULE
		)
	end

	--Place "The Gates of Dark World" face-up
	--in the Field Zone
	Duel.MoveToField(
		tc,
		tp,
		tp,
		LOCATION_FZONE,
		POS_FACEUP,
		true
	)
end

--==================================================
-- Effect 2
-- Destruction replacement
--==================================================

function s.repfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsDiscardable()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return not c:IsReason(REASON_REPLACE)
			and Duel.IsExistingMatchingCard(
				s.repfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				nil
			)
	end

	return Duel.SelectEffectYesNo(
		tp,
		c,
		aux.Stringid(id,2)
	)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.repfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	local ismonster=tc:IsMonster()
	local atk=0

	if ismonster then
		atk=tc:GetBaseAttack()

		if atk<0 then
			atk=0
		end
	end

	--Discard by card effect
	local sent=Duel.SendtoGrave(
		tc,
		REASON_EFFECT|REASON_DISCARD|REASON_REPLACE
	)

	if sent>0
		and ismonster
		and atk>0 then

		local val=math.floor(atk/2)

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(val)

		--Until the end of the opponent's next turn
		e1:SetReset(
			RESET_EVENT|RESETS_STANDARD|
			RESET_PHASE|PHASE_END,
			2
		)

		c:RegisterEffect(e1)
	end
end

--==================================================
-- Effect 3
-- Return 2 Dark World cards you control to hand,
-- then send Grapha to the GY;
-- Special Summon Graphack from GY.
--
-- If Special Summoned this way,
-- return it to the Deck if it leaves the field.
-- Since Graphack is a Link Monster,
-- it should be forced back to the Extra Deck.
--==================================================

function s.retfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsAbleToHandAsCost()
end

function s.graphafilter(c)
	return c:IsFaceup()
		and c:IsCode(CARD_GRAPHA)
		and c:IsAbleToGraveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then

		local gg=Duel.GetMatchingGroup(
			s.graphafilter,
			tp,
			LOCATION_MZONE,
			0,
			nil
		)

		return gg:IsExists(
			function(gc,tp)

				return Duel.GetMatchingGroupCount(
					function(c,gc)
						return s.retfilter(c)
							and c~=gc
					end,
					tp,
					LOCATION_ONFIELD,
					0,
					nil,
					gc
				)>=2

			end,
			1,
			nil,
			tp
		)
	end

	--Choose Grapha
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TOGRAVE
	)

	local gg=Duel.SelectMatchingCard(
		tp,
		s.graphafilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)

	local gc=gg:GetFirst()

	if not gc then
		return
	end

	--Return 2 other "Dark World" cards you control
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_RTOHAND
	)

	local rg=Duel.SelectMatchingCard(
		tp,
		function(c,gc)
			return s.retfilter(c)
				and c~=gc
		end,
		tp,
		LOCATION_ONFIELD,
		0,
		2,
		2,
		nil,
		gc
	)

	if #rg<2 then
		return
	end

	Duel.SendtoHand(
		rg,
		nil,
		REASON_COST
	)

	--Then send "Grapha, Dragon Lord of Dark World"
	--to the GY
	Duel.SendtoGrave(
		gc,
		REASON_COST
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(
			tp,
			LOCATION_MZONE
		)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or Duel.GetLocationCount(
			tp,
			LOCATION_MZONE
		)<=0 then
		return
	end

	if Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		--If this revived Graphack leaves the field,
		--redirect it to the Deck.
		--As a Link Monster, it should return
		--to the Extra Deck instead.
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(LOCATION_DECKSHF)
		e1:SetReset(
			RESET_EVENT|RESETS_REDIRECT
		)
		c:RegisterEffect(e1,true)
	end
end