--Laphite, Dragon Knight of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--Special Summon itself from hand or GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--If discarded by card effect, copy a "Dark World" Normal/Quick-Play Spell
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.cpcon)
	e2:SetTarget(s.cptg)
	e2:SetOperation(s.cpop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Special Summon effect
--==================================================

function s.lv8filter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsMonster()
		and c:IsLevel(8)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.lv8filter,tp,LOCATION_GRAVE,0,1,nil
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.SpecialSummon(
			c,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

--==================================================
-- Discard / copy effect
--==================================================

function s.cpcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Store previous controller for Dark World opponent-discard check
	e:SetLabel(c:GetPreviousControler())

	return c:IsPreviousLocation(LOCATION_HAND)
		and r&(REASON_DISCARD|REASON_EFFECT)
			==REASON_DISCARD|REASON_EFFECT
end

--"Dark World" Normal or Quick-Play Spell
function s.spfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsSpell()
		and (
			c:GetType()==TYPE_SPELL
			or c:IsType(TYPE_QUICKPLAY)
		)
		and c:GetActivateEffect()~=nil
end

--Normal route:
--Banish from GY
function s.gyfilter(c)
	return s.spfilter(c)
		and c:IsAbleToRemove()
end

--Opponent bonus route:
--Send from hand or Deck to GY
function s.hdfilter(c)
	return s.spfilter(c)
		and c:IsAbleToGrave()
end

function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)

	local oppdiscard=
		tp~=rp and tp==e:GetLabel()

	local gyok=Duel.IsExistingMatchingCard(
		s.gyfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil
	)

	local hdok=oppdiscard
		and Duel.IsExistingMatchingCard(
			s.hdfilter,
			tp,
			LOCATION_HAND+LOCATION_DECK,
			0,
			1,
			nil
		)

	if chk==0 then
		return gyok or hdok
	end

	local option=0

	--If discarded by opponent and both choices are available
	if gyok and hdok then
		option=Duel.SelectOption(
			tp,
			aux.Stringid(id,2),
			aux.Stringid(id,3)
		)

	elseif hdok and not gyok then
		option=1
	end

	local tc=nil

	--==================================================
	-- Normal Dark World route
	-- Banish Spell from GY
	--==================================================
	if option==0 then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.gyfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			1,
			nil
		)

		tc=g:GetFirst()

		if not tc then
			return
		end

		if Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)==0 then
			return
		end

	--==================================================
	-- Opponent-discard bonus route
	-- Send Spell from hand/Deck to GY
	--==================================================
	else

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_TOGRAVE
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.hdfilter,
			tp,
			LOCATION_HAND+LOCATION_DECK,
			0,
			1,
			1,
			nil
		)

		tc=g:GetFirst()

		if not tc then
			return
		end

		if Duel.SendtoGrave(
			tc,
			REASON_EFFECT
		)==0 then
			return
		end
	end

	--Store selected Spell
	e:SetLabelObject(tc)

	--Get that Spell's activation effect
	local te=tc:GetActivateEffect()

	if not te then
		return
	end

	--Copy category information
	e:SetCategory(te:GetCategory())

	--Use that Spell's targeting procedure
	local tg=te:GetTarget()

	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end
end

function s.cpop(e,tp,eg,ep,ev,re,r,rp)

	local tc=e:GetLabelObject()

	if not tc then
		return
	end

	local te=tc:GetActivateEffect()

	if not te then
		return
	end

	local op=te:GetOperation()

	if op then
		op(e,tp,eg,ep,ev,re,r,rp)
	end
end