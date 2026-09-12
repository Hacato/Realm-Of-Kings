--Laxen, Generalord of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--If discarded by card effect: Fusion Summon
	--If discarded by opponent's card effect: also optionally Set 1 Spell/Trap from their GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--==================================================
-- Dark World discard condition
--==================================================

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_HAND)
		and c:IsReason(REASON_DISCARD)
		and c:IsReason(REASON_EFFECT)
end

--==================================================
-- Fusion handling
--==================================================

--Any monster from hand / field / Deck / GY
--that can legally be banished
function s.matfilter(c)
	return c:IsMonster()
		and c:IsAbleToRemove()
end

--Fiend Fusion Monster that can be Fusion Summoned
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION)
		and c:IsRace(RACE_FIEND)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_FUSION,
			tp,
			false,
			false
		)
		and c:CheckFusionMaterial(
			mg,
			nil,
			tp
		)
end

--Opponent's Spell/Trap that can be Set
function s.setfilter(c)
	return c:IsSpellTrap()
		and c:IsSSetable()
end

--==================================================
-- Target
--==================================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	--If this effect has already targeted a card,
	--allow normal target checking
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.setfilter(chkc)
	end

	--Build possible Fusion Material pool
	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND
			|LOCATION_MZONE
			|LOCATION_DECK
			|LOCATION_GRAVE,
		0,
		nil
	)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fusfilter,
			tp,
			LOCATION_EXTRA,
			0,
			1,
			nil,
			e,
			tp,
			mg
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)

	--==================================================
	-- Opponent-discard bonus
	--==================================================

	--rp is the player responsible for the effect
	--that discarded Laxen
	local oppdiscard=(rp==1-tp)

	--Store whether opponent caused the discard
	e:SetLabel(oppdiscard and 1 or 0)

	if oppdiscard
		and Duel.IsExistingTarget(
			s.setfilter,
			tp,
			0,
			LOCATION_GRAVE,
			1,
			nil
		)
		and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.SelectYesNo(
			tp,
			aux.Stringid(id,1)
		)
	then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_SET
		)

		Duel.SelectTarget(
			tp,
			s.setfilter,
			tp,
			0,
			LOCATION_GRAVE,
			1,
			1,
			nil
		)
	end
end

--==================================================
-- Operation
--==================================================

function s.operation(e,tp,eg,ep,ev,re,r,rp)

	--==================================================
	-- Build complete Fusion Material pool
	--==================================================

	local mg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_HAND
			|LOCATION_MZONE
			|LOCATION_DECK
			|LOCATION_GRAVE,
		0,
		nil
	)

	--Find Fiend Fusion Monsters whose material
	--requirements can currently be fulfilled
	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		mg
	)

	if #fg>0 then

		--Choose Fusion Monster
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_SPSUMMON
		)

		local fc=fg:Select(
			tp,
			1,
			1,
			nil
		):GetFirst()

		if fc then

			--Let the selected Fusion Monster's
			--own Fusion procedure determine its materials
			local mat=Duel.SelectFusionMaterial(
				tp,
				fc,
				mg,
				nil,
				tp
			)

			if mat
				and #mat>0
				and fc:CheckFusionMaterial(
					mat,
					nil,
					tp
				)
			then

				--==================================================
				-- IMPORTANT:
				-- Check the Extra Deck summon zone while treating
				-- selected field materials as leaving the field.
				--==================================================

				if Duel.GetLocationCountFromEx(
					tp,
					tp,
					mat,
					fc
				)>0
				then

					fc:SetMaterial(mat)

					--Banish only the selected Fusion Materials
					if Duel.Remove(
						mat,
						POS_FACEUP,
						REASON_EFFECT
							|REASON_MATERIAL
							|REASON_FUSION
					)==#mat
					then

						if Duel.SpecialSummon(
							fc,
							SUMMON_TYPE_FUSION,
							tp,
							tp,
							false,
							false,
							POS_FACEUP
						)>0
						then
							fc:CompleteProcedure()
						end
					end
				end
			end
		end
	end

	--==================================================
	-- Opponent-discard bonus
	-- Set targeted Spell/Trap from opponent's GY
	--==================================================

	if e:GetLabel()~=1 then
		return
	end

	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsControler(1-tp)
		and tc:IsLocation(LOCATION_GRAVE)
		and tc:IsSSetable()
		and Duel.GetLocationCount(
			tp,
			LOCATION_SZONE
		)>0
	then
		Duel.BreakEffect()

		Duel.SSet(
			tp,
			tc
		)
	end
end