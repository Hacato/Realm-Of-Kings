--========================================================
-- SHADDOLL PHANTOM
--========================================================

--========================================================
-- GLOBAL FUSION ATTRIBUTE REQUIREMENT TRACKER
--
-- Records Attribute-based requirements passed into
-- Fusion.AddProcMix.
--
-- Example:
--
-- Construct:
--   Shaddoll + LIGHT
--   -> LIGHT
--
-- Meshahrail:
--   Shaddoll + DARK + EARTH
--   -> DARK | EARTH
--
-- Python:
--   Shaddoll + Wyrm
--   -> no Attribute requirement
--========================================================

if not Fusion.PhantomAttributeTrackerInstalled then

	Fusion.PhantomAttributeTrackerInstalled=true

	Fusion.PhantomRequiredAttributes=
		Fusion.PhantomRequiredAttributes or {}

	local old_AddProcMix=Fusion.AddProcMix

	--====================================================
	-- ALL ATTRIBUTES
	--====================================================

	local attributes={
		ATTRIBUTE_EARTH,
		ATTRIBUTE_WATER,
		ATTRIBUTE_FIRE,
		ATTRIBUTE_WIND,
		ATTRIBUTE_LIGHT,
		ATTRIBUTE_DARK,
		ATTRIBUTE_DIVINE
	}

	local ALL_ATTRIBUTES=
		ATTRIBUTE_EARTH|
		ATTRIBUTE_WATER|
		ATTRIBUTE_FIRE|
		ATTRIBUTE_WIND|
		ATTRIBUTE_LIGHT|
		ATTRIBUTE_DARK|
		ATTRIBUTE_DIVINE

	--====================================================
	-- TEST ONE MATERIAL FILTER AGAINST ONE ATTRIBUTE
	--====================================================

	local function CheckFilterAttribute(filter,fc,att)

		if type(filter)~="function" then
			return false
		end

		Duel.AssumeReset()

		--Preserve only the Attribute being tested.
		fc:AssumeProperty(ASSUME_ATTRIBUTE,att)

		--Neutralize other common material properties.
		--
		--This is specifically important for cards like:
		--
		-- Shaddoll + Wyrm
		--
		--which should NOT be interpreted as an
		--Attribute requirement.
		fc:AssumeProperty(ASSUME_RACE,RACE_DIVINE)
		fc:AssumeProperty(ASSUME_LEVEL,1)
		fc:AssumeProperty(ASSUME_ATTACK,0)
		fc:AssumeProperty(ASSUME_DEFENSE,0)

		local ok,res=pcall(
			filter,
			fc,
			fc,
			SUMMON_TYPE_FUSION,
			0
		)

		Duel.AssumeReset()

		return ok and res==true
	end

	--====================================================
	-- REPLACE Fusion.AddProcMix WITH TRACKING WRAPPER
	--====================================================

	Fusion.AddProcMix=function(c,sub,insf,...)

		--Save ORIGINAL individual material filters.
		local filters={...}

		--================================================
		-- REGISTER REAL FUSION PROCEDURE
		--
		--Nothing about the actual Fusion Summon is
		--changed.
		--================================================

		old_AddProcMix(c,sub,insf,...)

		local mask=0

		--================================================
		-- INSPECT EACH INDIVIDUAL MATERIAL REQUIREMENT
		--================================================

		for _,filter in ipairs(filters) do

			if type(filter)=="function" then

				local accepted=0

				for _,att in ipairs(attributes) do

					if CheckFilterAttribute(
						filter,
						c,
						att
					) then

						accepted=accepted|att
					end
				end

				--================================================
				-- ATTRIBUTE FILTER?
				--
				--An Attribute requirement should accept at
				--least one Attribute, but shouldn't simply
				--accept every possible Attribute.
				--
				--Example:
				--
				-- Card.IsAttribute(LIGHT)
				--     accepted = LIGHT
				--
				-- Meshahrail DARK filter
				--     accepted = DARK
				--
				-- Generic monster filter
				--     accepted = ALL
				--
				-- Wyrm filter
				--     accepted = 0
				--================================================

				if accepted~=0
					and accepted~=ALL_ATTRIBUTES then

					mask=mask|accepted
				end
			end
		end

		--================================================
		-- SAVE RESULT BY CARD CODE
		--================================================

		Fusion.PhantomRequiredAttributes[c:GetCode()]=mask
	end
end


--========================================================
-- CARD SCRIPT
--========================================================

local s,id=GetID()

function s.initial_effect(c)

	--====================================================
	-- ALWAYS TREATED AS A "PHANTOM KNIGHTS" CARD
	--====================================================

	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(
		EFFECT_FLAG_CANNOT_DISABLE+
		EFFECT_FLAG_UNCOPYABLE
	)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_PHANTOM_KNIGHTS)
	c:RegisterEffect(e0)


	--====================================================
	-- TARGET -> ATK 0 -> SHADDOLL FUSION
	--====================================================

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(
		CATEGORY_ATKCHANGE+
		CATEGORY_SPECIAL_SUMMON+
		CATEGORY_FUSION_SUMMON+
		CATEGORY_DESTROY
	)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)

	--You can only activate 1
	--"Shaddoll Phantom" per turn.
	e1:SetCountLimit(
		1,
		id,
		EFFECT_COUNT_CODE_OATH
	)

	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)

	c:RegisterEffect(e1)
end

s.listed_series={
	SET_SHADDOLL,
	SET_PHANTOM_KNIGHTS
}


--========================================================
-- MATCHING SHADDOLL FUSION
--========================================================

function s.attrfilter(c,e,tp,att)

	if not c:IsSetCard(SET_SHADDOLL) then
		return false
	end

	if not c:IsType(TYPE_FUSION) then
		return false
	end

	if not c:IsCanBeSpecialSummoned(
		e,
		SUMMON_TYPE_FUSION,
		tp,
		false,
		false
	) then
		return false
	end

	--====================================================
	-- GET ATTRIBUTE REQUIREMENTS RECORDED WHEN
	-- Fusion.AddProcMix WAS CALLED
	--====================================================

	local mask=
		Fusion.PhantomRequiredAttributes
		and Fusion.PhantomRequiredAttributes[c:GetCode()]
		or 0

	--====================================================
	-- DOES AT LEAST ONE MATERIAL REQUIRE THIS ATTRIBUTE?
	--====================================================

	return (mask&att)~=0
end


--========================================================
-- VALID OPPONENT TARGET
--========================================================

function s.tgfilter(c,e,tp)

	--Must be face-up.
	if not c:IsFaceup() then
		return false
	end

	--====================================================
	-- ALREADY 0 ATK?
	--
	--Not a legal target.
	--====================================================

	if c:GetAttack()==0 then
		return false
	end

	local att=c:GetAttribute()

	if att==0 then
		return false
	end

	--====================================================
	-- THERE MUST BE AT LEAST ONE SHADDOLL FUSION
	-- REQUIRING THIS ATTRIBUTE
	--====================================================

	return Duel.IsExistingMatchingCard(
		s.attrfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		nil,
		e,
		tp,
		att
	)
end


--========================================================
-- TARGET
--========================================================

function s.target(
	e,tp,eg,ep,ev,re,r,rp,
	chk,chkc
)

	if chkc then

		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.tgfilter(chkc,e,tp)
	end


	if chk==0 then

		return Duel.IsExistingTarget(
			s.tgfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil,
			e,
			tp
		)
	end


	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_FACEUP
	)


	local g=Duel.SelectTarget(
		tp,
		s.tgfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil,
		e,
		tp
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


--========================================================
-- RESOLUTION
--========================================================

function s.activate(
	e,tp,eg,ep,ev,re,r,rp
)

	local tc=Duel.GetFirstTarget()


	--====================================================
	-- TARGET MUST STILL EXIST
	--====================================================

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup() then

		return
	end


	--====================================================
	-- ANOTHER EFFECT ALREADY MADE IT 0?
	--
	--If yes, Phantom did NOT make its ATK become 0.
	--Therefore the Fusion Summon does not happen.
	--====================================================

	if tc:GetAttack()==0 then
		return
	end


	--====================================================
	-- REMEMBER ATTRIBUTE BEFORE CHANGING ATK
	--====================================================

	local att=tc:GetAttribute()

	if att==0 then
		return
	end


	--====================================================
	-- MAKE TARGET'S ATK BECOME 0
	--====================================================

	local e1=Effect.CreateEffect(
		e:GetHandler()
	)

	e1:SetType(
		EFFECT_TYPE_SINGLE
	)

	e1:SetCode(
		EFFECT_SET_ATTACK_FINAL
	)

	e1:SetValue(0)

	e1:SetReset(
		RESET_EVENT|
		RESETS_STANDARD
	)

	tc:RegisterEffect(e1)


	--====================================================
	-- "AND IF IT DOES"
	--
	--The target must:
	--
	--  * still exist
	--  * still be face-up
	--  * still be related to Phantom
	--  * actually have 0 ATK
	--====================================================

	if not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or tc:GetAttack()~=0 then

		return
	end


	--====================================================
	-- EXTRA DECK SPACE
	--====================================================

	if Duel.GetLocationCountFromEx(
		tp,
		tp,
		nil,
		nil
	)<=0 then

		return
	end


	--====================================================
	-- FIND SHADDOLL FUSIONS WHOSE MATERIAL REQUIREMENTS
	-- INCLUDE THE TARGET'S ATTRIBUTE
	--====================================================

	local g=Duel.GetMatchingGroup(
		s.attrfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		att
	)


	if #g==0 then
		return
	end


	--====================================================
	-- SELECT FUSION
	--====================================================

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)


	local sc=g:Select(
		tp,
		1,
		1,
		nil
	):GetFirst()


	if not sc then
		return
	end


	--====================================================
	-- SPECIAL SUMMON
	--
	--THIS IS TREATED AS A FUSION SUMMON
	--====================================================

	if Duel.SpecialSummon(
		sc,
		SUMMON_TYPE_FUSION,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)>0 then


		--Properly summoned.
		sc:CompleteProcedure()


		--================================================
		-- MARK EXACT MONSTER SUMMONED BY PHANTOM
		--================================================

		local fid=sc:GetFieldID()


		sc:RegisterFlagEffect(
			id,
			RESET_EVENT|
			RESETS_STANDARD,
			0,
			1,
			fid
		)


		--================================================
		-- DESTROY IT DURING THE END PHASE
		--================================================

		local e2=Effect.CreateEffect(
			e:GetHandler()
		)

		e2:SetType(
			EFFECT_TYPE_FIELD+
			EFFECT_TYPE_CONTINUOUS
		)

		e2:SetCode(
			EVENT_PHASE+
			PHASE_END
		)

		e2:SetLabel(fid)
		e2:SetLabelObject(sc)

		e2:SetCondition(
			s.descon
		)

		e2:SetOperation(
			s.desop
		)

		e2:SetReset(
			RESET_PHASE|
			PHASE_END
		)

		Duel.RegisterEffect(
			e2,
			tp
		)
	end
end


--========================================================
-- END PHASE DESTRUCTION CHECK
--========================================================

function s.descon(
	e,tp,eg,ep,ev,re,r,rp
)

	local tc=e:GetLabelObject()

	return tc
		and tc:IsOnField()
		and tc:GetFlagEffectLabel(id)
			==e:GetLabel()
end


--========================================================
-- END PHASE DESTRUCTION
--========================================================

function s.desop(
	e,tp,eg,ep,ev,re,r,rp
)

	local tc=e:GetLabelObject()

	if tc
		and tc:IsOnField()
		and tc:GetFlagEffectLabel(id)
			==e:GetLabel() then

		Duel.Destroy(
			tc,
			REASON_EFFECT
		)
	end
end