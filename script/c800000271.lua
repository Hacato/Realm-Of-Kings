--Emerad, General of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--Xyz Summon: 2+ Level 4 DARK monsters
	Xyz.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),
		4,
		2,
		nil,
		nil,
		Xyz.InfiniteMats
	)
	c:EnableReviveLimit()

	--If Xyz Summoned: declare card names
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.nmcon)
	e1:SetOperation(s.nmop)
	c:RegisterEffect(e1)

	--Count the "Dark World" monsters used as Xyz Material
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_MATERIAL_CHECK)
	e0:SetValue(s.matcheck)
	e0:SetLabelObject(e1)
	c:RegisterEffect(e0)

	--Destroy replacement
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.reptg)
	c:RegisterEffect(e2)

	--During the End Phase, if destruction replacement was applied
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Count "Dark World" Xyz Materials used
--==================================================

function s.matcheck(e,c)
	local g=c:GetMaterial()
	local ct=g:FilterCount(Card.IsSetCard,nil,SET_DARK_WORLD)

	e:GetLabelObject():SetLabel(ct)
end

--==================================================
-- Declare names
--==================================================

function s.nmcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
		and e:GetLabel()>0
end

function s.nmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()

	--The lingering name-changing effect only exists
	--while this Xyz Summoned copy remains on the field
	if not c:IsFaceup()
		or not c:IsLocation(LOCATION_MZONE)
		or not c:IsRelateToEffect(e) then
		return
	end

	--Choose how many card names to declare
	local nums={}
	for i=1,ct do
		table.insert(nums,i)
	end

	local num=Duel.AnnounceNumber(tp,table.unpack(nums))

	local declared={}

	for i=1,num do
		local code

		--Do not allow the exact same name
		--to be declared twice
		repeat
			code=Duel.AnnounceCard(tp)
		until not declared[code]

		declared[code]=true

		--Create a continuous effect for this declared name
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_CHAINING)
		e1:SetRange(LOCATION_MZONE)
		e1:SetLabel(code)
		e1:SetCondition(s.chcon)
		e1:SetOperation(s.chop)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end

--==================================================
-- Replace activated effects of declared cards
--==================================================

function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	return rc
		and rc:IsCode(e:GetLabel())
end

function s.chop(e,tp,eg,ep,ev,re,r,rp)
	--Remove the original effect's targets
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)

	--Replace its resolving effect
	Duel.ChangeChainOperation(ev,s.repop)
end

--The declared card's new activated effect:
--"Your opponent discards 1 card of their choice
--from their hand."
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then
		Duel.DiscardHand(
			1-tp,
			nil,
			1,
			1,
			REASON_EFFECT|REASON_DISCARD
		)
	end
end

--==================================================
-- Destruction replacement
--
-- If this card would be destroyed by battle or
-- card effect, detach 1 material instead.
--==================================================

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsReason(REASON_BATTLE|REASON_EFFECT)
			and not c:IsReason(REASON_REPLACE)
			and c:CheckRemoveOverlayCard(
				tp,
				1,
				REASON_EFFECT
			)
	end

	--Mandatory replacement
	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_EFFECT
	)

	--Remember that this replacement effect
	--was applied this turn
	c:RegisterFlagEffect(
		id,
		RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,
		0,
		1
	)

	return true
end

--==================================================
-- End Phase search
--==================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
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
		Duel.ConfirmCards(1-tp,g)
	end
end