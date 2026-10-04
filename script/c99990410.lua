--SAO Asuna - OS
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
	--(1) During the turn this card was Link Summoned:
	--Excavate cards equal to the total Link Rating of
	--your "SAO" Link Monsters.
	--Add all excavated Level 4 or lower "SAO" monsters,
	--then banish the rest.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.excacon)
	e1:SetTarget(s.excatg)
	e1:SetOperation(s.excaop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) If this card OR a monster it points to
	--destroys an opponent's monster by battle:
	--Place 1 En-Counter on your "SAO" Field Spell.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_COUNTER)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.pctcon)
	e2:SetTarget(s.pcttg)
	e2:SetOperation(s.pctop)
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
--(1) EXCAVATE
----------------------------------------------------------

--Only during the turn this card was Link Summoned.
function s.excacon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsSummonType(SUMMON_TYPE_LINK)
		and c:GetTurnID()==Duel.GetTurnCount()
end

----------------------------------------------------------
--Face-up "SAO" Link Monsters you control.
----------------------------------------------------------

function s.linkfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_LINK)
end

----------------------------------------------------------
--Cards that get added from the excavated cards.
----------------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:HasLevel()
		and c:IsLevelBelow(4)
		and c:IsAbleToHand()
end

----------------------------------------------------------
--Get total Link Rating.
----------------------------------------------------------

function s.getlinkrating(tp)
	local g=Duel.GetMatchingGroup(
		s.linkfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	return g:GetSum(Card.GetLink)
end

function s.excatg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=s.getlinkrating(tp)

	if chk==0 then
		return ct>0
			and Duel.GetFieldGroupCount(
				tp,
				LOCATION_DECK,
				0
			)>=ct
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		0,
		tp,
		LOCATION_DECK
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		0,
		tp,
		LOCATION_DECK
	)
end

function s.excaop(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--Recalculate the total Link Rating at resolution.
	------------------------------------------------------
	local ct=s.getlinkrating(tp)

	if ct<=0 then
		return
	end

	if Duel.GetFieldGroupCount(
		tp,
		LOCATION_DECK,
		0
	)<ct then
		return
	end

	------------------------------------------------------
	--Excavate the top cards.
	------------------------------------------------------
	Duel.ConfirmDecktop(tp,ct)

	local g=Duel.GetDecktopGroup(tp,ct)

	if #g==0 then
		return
	end

	------------------------------------------------------
	--Add ALL Level 4 or lower "SAO" monsters among them.
	------------------------------------------------------
	local sg=g:Filter(s.thfilter,nil)

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

		--------------------------------------------------
		--Remove the cards that went to the hand from
		--the group that will be banished.
		--------------------------------------------------
		g:Sub(sg)
	end

	------------------------------------------------------
	--Banish everything else.
	------------------------------------------------------
	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

----------------------------------------------------------
--(2) PLACE EN-COUNTER
----------------------------------------------------------

function s.pctcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	------------------------------------------------------
	--Find a monster in the EVENT_BATTLE_DESTROYING group
	--that is either:
	--
	--1. Asuna herself
	--OR
	--2. A monster currently in a zone Asuna points to.
	------------------------------------------------------
	for ec in aux.Next(eg) do
		if ec:IsControler(tp) then
			local bc=ec:GetBattleTarget()

			if bc
				and bc:IsMonster()
				and bc:IsControler(1-tp)
				and (
					ec==c
					or c:GetLinkedGroup():IsContains(ec)
				)
			then
				return true
			end
		end
	end

	return false
end

----------------------------------------------------------
--Must have an appropriate "SAO" Field Spell.
----------------------------------------------------------

function s.pcttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local fc=Duel.GetFieldCard(
		tp,
		LOCATION_SZONE,
		5
	)

	if chk==0 then
		return fc
			and fc:IsFaceup()
			and fc:IsSetCard(SET_SAO)
			and fc:IsCanAddCounter(COUNTER_EN,1)
	end
end

function s.pctop(e,tp,eg,ep,ev,re,r,rp)
	local fc=Duel.GetFieldCard(
		tp,
		LOCATION_SZONE,
		5
	)

	if fc
		and fc:IsFaceup()
		and fc:IsSetCard(SET_SAO)
		and fc:IsCanAddCounter(COUNTER_EN,1)
	then
		fc:AddCounter(
			COUNTER_EN,
			1
		)
	end
end