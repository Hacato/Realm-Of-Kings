--Blod, Wicked Lord of Dark World
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--3 DARK monsters
	Link.AddProcedure(c,s.matfilter,3,3)

	--While this card is in the Extra Monster Zone,
	--cards discarded from your hand to the GY by a card effect
	--are treated as discarded by your opponent's card effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EFFECT_SEND_REPLACE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCondition(s.repcon)
	e1:SetTarget(s.reptg)
	e1:SetValue(s.repval)
	e1:SetOperation(s.repop)

	local g=Group.CreateGroup()
	g:KeepAlive()
	e1:SetLabelObject(g)

	c:RegisterEffect(e1)

	--When an opponent's card or effect is activated:
	--discard 1 monster, negate the activation, and destroy it
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_HANDES+CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.negcon)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)

	--If this Link Summoned card is destroyed and sent to the GY:
	--add 1 "Dark World" card from your Deck to your hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Link Materials
-- 3 DARK monsters
--==================================================

function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp)
end

--==================================================
-- Effect 1
-- Extra Monster Zone discard replacement
--==================================================

function s.repcon(e)
	local c=e:GetHandler()

	--Extra Monster Zones are sequences 5 and 6
	return c:IsLocation(LOCATION_MZONE)
		and c:GetSequence()>=5
end

function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_HAND)
		and c:GetDestination()==LOCATION_GRAVE
		and c:GetReason()&(REASON_EFFECT|REASON_DISCARD)
			==REASON_EFFECT|REASON_DISCARD
		and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(
			s.repfilter,
			1,
			nil,
			tp
		)
	end

	local rg=eg:Filter(
		s.repfilter,
		nil,
		tp
	)

	if #rg==0 then
		return false
	end

	local container=e:GetLabelObject()
	container:Clear()
	container:Merge(rg)

	return true
end

function s.repval(e,c)
	local g=e:GetLabelObject()

	return g
		and g:IsContains(c)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local container=e:GetLabelObject()

	if not container or #container==0 then
		return
	end

	local g=container:Clone()
	container:Clear()

	--Perform the discard again with the opponent
	--as the reason player
	Duel.SendtoGrave(
		g,
		REASON_EFFECT|REASON_DISCARD|REASON_REPLACE,
		PLAYER_NONE,
		1-tp
	)
end

--==================================================
-- Effect 2
--
-- When an opponent activates a card or effect:
-- discard 1 monster, negate the activation,
-- and if you do, destroy it.
--
-- Uses per turn =
-- number of "Dark World" monsters this card
-- points to + 1
--==================================================

function s.linkdwfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
end

function s.getnegcount(c)
	return c:GetLinkedGroup():FilterCount(
		s.linkdwfilter,
		nil
	)+1
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Must be opponent's activation
	if rp~=1-tp then
		return false
	end

	--Activation must be negatable
	if not Duel.IsChainNegatable(ev) then
		return false
	end

	local used=c:GetFlagEffect(id)
	local max=s.getnegcount(c)

	return used<max
end

function s.discmonfilter(c)
	return c:IsMonster()
		and c:IsDiscardable()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.discmonfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_HANDES,
		nil,
		1,
		tp,
		LOCATION_HAND
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	local rc=re:GetHandler()

	if rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then

		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			Group.FromCards(rc),
			1,
			0,
			0
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()

	--There must still be a monster available to discard
	if not Duel.IsExistingMatchingCard(
		s.discmonfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local dg=Duel.SelectMatchingCard(
		tp,
		s.discmonfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	if #dg==0 then
		return
	end

	--Register one use of Blod's negate this turn
	c:RegisterFlagEffect(
		id,
		RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,
		0,
		1
	)

	--Negate the original activation first.
	--This avoids Blod's discard replacement interfering
	--with the Chain Link we are trying to negate.
	local negated=Duel.NegateActivation(ev)

	--Discard 1 monster as part of Blod's effect.
	--If Blod is still in the Extra Monster Zone,
	--its first effect changes this into an
	--opponent-caused discard.
	Duel.SendtoGrave(
		dg,
		REASON_EFFECT|REASON_DISCARD
	)

	--If the activation was successfully negated,
	--destroy the card whose activation/effect was negated
	if negated
		and rc
		and rc:IsRelateToEffect(re)
		and rc:IsDestructable() then

		Duel.Destroy(
			rc,
			REASON_EFFECT
		)
	end
end

--==================================================
-- Effect 3
-- If this Link Summoned card is destroyed
-- and sent to the GY:
-- add 1 "Dark World" card from Deck
--==================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsReason(REASON_DESTROY)
		and c:IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
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
	local g=Duel.GetMatchingGroup(
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		nil
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local sg=g:Select(
		tp,
		1,
		1,
		nil
	)

	if #sg>0 then
		Duel.SendtoHand(
			sg,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			sg
		)
	end
end