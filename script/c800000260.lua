--Sky Striker Ace - Chikara
local s,id=GetID()

local SET_SKY_STRIKER=0x115

function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(
		c,
		s.xyzfilter,
		4,
		2,
		s.ovfilter,
		aux.Stringid(id,0),
		2
	)

	--You can only Special Summon "Sky Striker Ace - Chikara" once per turn
	c:SetSPSummonOnce(id)

	--Once per turn:
	--Detach 1 material; excavate the top 3 cards of your Deck.
	--You can add 1 excavated "Sky Striker" card to your hand,
	--then send the remaining cards to the GY.
	--Otherwise, shuffle all excavated cards into the Deck.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DECKDES+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.excost)
	e1:SetTarget(s.extg)
	e1:SetOperation(s.exop)
	c:RegisterEffect(e1)

	--A "Sky Striker" Link Monster that was Link Summoned
	--using this card as material cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.indcon)
	e2:SetOperation(s.indop)
	c:RegisterEffect(e2)
end

--------------------------------------------------
-- Xyz Summon
-- 2 Level 4 "Sky Striker" monsters
--------------------------------------------------

function s.xyzfilter(c,xyzc,sumtype,tp)
	return c:IsSetCard(SET_SKY_STRIKER)
end

--------------------------------------------------
-- Alternative Xyz Summon
-- Use 1 EARTH "Sky Striker" Link Monster
--------------------------------------------------

function s.ovfilter(c,tp,xyzc)
	return c:IsFaceup()
		and c:IsSetCard(SET_SKY_STRIKER)
		and c:IsAttribute(ATTRIBUTE_EARTH)
		and c:IsType(TYPE_LINK)
end

--------------------------------------------------
-- Cost
-- Detach 1 material
--------------------------------------------------

function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

--------------------------------------------------
-- Excavation target
--------------------------------------------------

function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3
	end
end

--------------------------------------------------
-- "Sky Striker" card that can be added
--------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(SET_SKY_STRIKER)
		and c:IsAbleToHand()
end

--------------------------------------------------
-- Excavate top 3
--------------------------------------------------

function s.exop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then
		return
	end

	--Get and reveal the top 3 cards
	local g=Duel.GetDecktopGroup(tp,3)
	Duel.ConfirmCards(1-tp,g)

	--Find excavated "Sky Striker" cards that can be added
	local sg=g:Filter(s.thfilter,nil)

	--If there is at least 1 valid "Sky Striker" card,
	--player may choose to add one
	if sg:GetCount()>0
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_ATOHAND
		)

		local tc=sg:Select(tp,1,1,nil):GetFirst()

		if tc then
			--Add selected card to hand
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)

			--Send remaining excavated cards to the GY
			g:RemoveCard(tc)

			if g:GetCount()>0 then
				Duel.SendtoGrave(g,REASON_EFFECT)
			end

			return
		end
	end

	--If no card was added, shuffle all excavated cards
	--back into the Deck
	Duel.SendtoDeck(
		g,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)

	Duel.ShuffleDeck(tp)
end

--------------------------------------------------
-- Used as Link Material for a "Sky Striker"
-- Link Monster
--------------------------------------------------

function s.indcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if (r&REASON_LINK)==0 then
		return false
	end

	local rc=c:GetReasonCard()

	return rc
		and rc:IsType(TYPE_LINK)
		and rc:IsSetCard(SET_SKY_STRIKER)
end

--------------------------------------------------
-- Link Monster cannot be destroyed by card effects
--------------------------------------------------

function s.indop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()

	if not rc
		or not rc:IsFaceup()
		or not rc:IsType(TYPE_LINK)
		or not rc:IsSetCard(SET_SKY_STRIKER) then
		return
	end

	local e1=Effect.CreateEffect(rc)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	rc:RegisterEffect(e1)
end