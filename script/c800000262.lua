--Sky Striker Maneuver - Final Slash!
local s,id=GetID()

local SET_SKY_STRIKER=0x115
local SET_SKY_STRIKER_ACE=0x1115

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------
--You must control no monsters in your
--Main Monster Zones
--------------------------------------------------

function s.mmzfilter(c)
	return c:IsLocation(LOCATION_MZONE)
		and c:GetSequence()<5
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(
		s.mmzfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

--------------------------------------------------
--Send 1 "Sky Striker Ace" Link Monster
--from the Extra Deck to the GY
--------------------------------------------------

function s.costfilter(c)
	return c:IsType(TYPE_LINK)
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
		and c:IsAbleToGraveAsCost()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,
			tp,
			LOCATION_EXTRA,
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
		s.costfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()

	if tc then
		--Store the original ATK of the monster sent
		e:SetLabel(tc:GetBaseAttack())

		Duel.SendtoGrave(
			tc,
			REASON_COST
		)
	end
end

--------------------------------------------------
--Target 1 face-up monster your opponent controls
--------------------------------------------------

function s.targetfilter(c)
	return c:IsFaceup()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.targetfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.targetfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_FACEUP
	)

	local g=Duel.SelectTarget(
		tp,
		s.targetfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)

	local atk=e:GetLabel()

	Duel.SetOperationInfo(
		0,
		CATEGORY_ATKCHANGE,
		g,
		1,
		0,
		-atk
	)
end

--------------------------------------------------
--Count Spells in your GY
--------------------------------------------------

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
end

--------------------------------------------------
--Your "Sky Striker Ace" Link Monsters
--------------------------------------------------

function s.linkfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_LINK)
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
end

--------------------------------------------------
--Get opponent Main Monster Zones that are:
--
--1. Linked to one of your "Sky Striker Ace"
--   Link Monsters
--2. Currently unused
--
--Returns a 5-bit zone mask
--------------------------------------------------

function s.getmovezone(tp)
	local zone=0

	local g=Duel.GetMatchingGroup(
		s.linkfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	for lc in aux.Next(g) do
		--Get zones on the opponent's field
		--that this Link Monster points to
		zone=zone | (lc:GetLinkedZone(1-tp) & 0x1f)
	end

	--Only keep currently unused Main Monster Zones
	local usable=0

	for seq=0,4 do
		if (zone & (1<<seq))~=0
			and Duel.CheckLocation(
				1-tp,
				LOCATION_MZONE,
				seq
			) then

			usable=usable | (1<<seq)
		end
	end

	return usable
end

--------------------------------------------------
--Resolve
--------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsFaceup()
		or not tc:IsRelateToEffect(e) then
		return
	end

	local atk=e:GetLabel()

	--------------------------------------------------
	--Target loses ATK equal to the original ATK
	--of the Link Monster sent as cost
	--------------------------------------------------

	if atk>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-atk)
		e1:SetReset(
			RESET_EVENT|
			RESETS_STANDARD|
			RESET_PHASE|
			PHASE_END
		)
		tc:RegisterEffect(e1)
	end

	--------------------------------------------------
	--If you have 3 or more Spells in your GY,
	--you can move the targeted monster
	--------------------------------------------------

	if Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)<3 then
		return
	end

	--Target must still be in opponent's Monster Zone
	if not tc:IsFaceup()
		or not tc:IsControler(1-tp)
		or not tc:IsLocation(LOCATION_MZONE) then
		return
	end

	local zone=s.getmovezone(tp)

	if zone==0 then
		return
	end

	--Moving the monster is optional
	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,1)
	) then
		return
	end

	--------------------------------------------------
	--Select one of the opponent's available
	--linked Main Monster Zones
	--------------------------------------------------

	local selected=zone

	if (zone & (zone-1))~=0 then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_TOZONE
		)

		--Opponent's zones occupy the upper field-zone
		--bits when selected by the activating player
		local fieldzone=Duel.SelectDisableField(
			tp,
			1,
			0,
			LOCATION_MZONE,
			~(zone<<16)
		)

		selected=(fieldzone>>16)&0x1f
	end

	if selected==0 then
		return
	end

	--------------------------------------------------
	--Convert selected zone bit into its sequence
	--------------------------------------------------

	local seq=0

	for i=0,4 do
		if (selected & (1<<i))~=0 then
			seq=i
			break
		end
	end

	--------------------------------------------------
	--Move the opponent's monster
	--------------------------------------------------

	Duel.MoveSequence(tc,seq)
end