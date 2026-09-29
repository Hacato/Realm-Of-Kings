--Apao Shaddoll Leviathan
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--==================================================
	-- FUSION MATERIAL
	-- 1 "Shaddoll" monster + 1 Dragon monster
	--==================================================
	Fusion.AddProcMix(
		c,
		true,
		true,
		aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SHADDOLL),
		aux.FilterBoolFunctionEx(Card.IsRace,RACE_DRAGON)
	)

	--Must first be Fusion Summoned
	c:AddMustBeFusionSummoned()

	--==================================================
	-- TARGET 1 SPELL/TRAP; DESTROY IT,
	-- THEN IF IT WAS A TRAP, SEARCH A SHADDOLL MONSTER
	--==================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	--==================================================
	-- BANISH THIS CARD FROM GY;
	-- FUSION SUMMON A SHADDOLL USING MONSTERS
	-- FROM EITHER SIDE OF THE FIELD
	--==================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.fuscost)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SHADDOLL}
s.material_setcode=SET_SHADDOLL

--==================================================
-- FIRST EFFECT
-- SPELL/TRAP TARGET
--==================================================

function s.desfilter(c)
	return c:IsSpellTrap()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)

	if chkc then
		return chkc:IsOnField()
			and s.desfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.desfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DESTROY
	)

	local g=Duel.SelectTarget(
		tp,
		s.desfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		1,
		0,
		0
	)
end

--==================================================
-- SHADDOLL SEARCH FILTER
--==================================================

function s.thfilter(c)
	return c:IsSetCard(SET_SHADDOLL)
		and c:IsMonster()
		and c:IsAbleToHand()
end

--==================================================
-- DESTROY -> IF TRAP -> SEARCH
--==================================================

function s.desop(e,tp,eg,ep,ev,re,r,rp)

	local tc=Duel.GetFirstTarget()

	--Target must still be related to the effect.
	if not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	--==================================================
	-- REMEMBER WHETHER IT WAS A TRAP
	-- BEFORE DESTROYING IT
	--==================================================

	local wastrap=tc:IsType(TYPE_TRAP)

	--==================================================
	-- IT MUST ACTUALLY BE DESTROYED
	--==================================================

	if Duel.Destroy(
		tc,
		REASON_EFFECT
	)==0 then
		return
	end

	--==================================================
	-- ONLY CONTINUE IF THE DESTROYED CARD WAS A TRAP
	--==================================================

	if not wastrap then
		return
	end

	--==================================================
	-- OPTIONAL SEARCH
	--
	-- "you can add"
	--==================================================

	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	) then
		return
	end

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

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
end

--==================================================
-- SECOND EFFECT COST
-- BANISH LEVIATHAN FROM GY
--==================================================

function s.fuscost(e,tp,eg,ep,ev,re,r,rp,chk)

	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

--==================================================
-- FUSION MATERIAL POOL
--
--ALL MONSTERS ON BOTH SIDES OF THE FIELD
--==================================================

function s.fusmatfilter(c)
	return c:IsFaceup()
		and c:IsCanBeFusionMaterial()
end

--==================================================
-- SHADDOLL FUSION FILTER
--==================================================

function s.fusfilter(c,e,tp,mg)

	return c:IsSetCard(SET_SHADDOLL)
		and c:IsType(TYPE_FUSION)
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

--==================================================
-- FUSION TARGET
--==================================================

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)

	--==================================================
	-- BUILD MATERIAL GROUP FROM BOTH FIELDS
	--==================================================

	local mg=Duel.GetMatchingGroup(
		s.fusmatfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	if chk==0 then
		return Duel.GetLocationCountFromEx(
			tp,
			tp,
			nil,
			nil
		)>0
			and Duel.IsExistingMatchingCard(
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
end

--==================================================
-- FUSION SUMMON
--==================================================

function s.fusop(e,tp,eg,ep,ev,re,r,rp)

	--==================================================
	-- REBUILD MATERIAL POOL AT RESOLUTION
	--
	--This matters if monsters left/entered the field
	--between activation and resolution.
	--==================================================

	local mg=Duel.GetMatchingGroup(
		s.fusmatfilter,
		tp,
		LOCATION_MZONE,
		LOCATION_MZONE,
		nil
	)

	if #mg==0 then
		return
	end

	--==================================================
	-- FIND VALID SHADDOLL FUSIONS
	--==================================================

	local sg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		mg
	)

	if #sg==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local fc=sg:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()

	if not fc then
		return
	end

	--==================================================
	-- SELECT THE ACTUAL FUSION MATERIALS
	--
	--The Fusion Monster's own procedure determines
	--which monsters from the combined field pool
	--are legal materials.
	--==================================================

	local mat=Duel.SelectFusionMaterial(
		tp,
		fc,
		mg,
		nil,
		tp
	)

	if not mat
		or #mat==0 then
		return
	end

	fc:SetMaterial(mat)

	--==================================================
	-- SEND MATERIALS TO GY
	--
	--They are being used as Fusion Material.
	--==================================================

	Duel.SendtoGrave(
		mat,
		REASON_EFFECT+
		REASON_MATERIAL+
		REASON_FUSION
	)

	--==================================================
	-- FUSION SUMMON
	--==================================================

	if Duel.SpecialSummon(
		fc,
		SUMMON_TYPE_FUSION,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then

		fc:CompleteProcedure()
	end
end