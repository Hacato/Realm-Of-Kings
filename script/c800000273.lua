--Grae, Heterotypic of Dark World
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--2 DARK Fiend monsters
	Link.AddProcedure(c,s.matfilter,2,2)

	--If Link Summoned: draw, then discard
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	--Recover a Dark World card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_HANDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--Tribute Grae; apply discard replacement this turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCost(s.graecost)
	e3:SetOperation(s.graeop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Link Material
--==================================================

function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp)
		and c:IsRace(RACE_FIEND,lc,sumtype,tp)
end

--==================================================
-- Effect 1
--==================================================

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.dwcontrolfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(
		s.dwcontrolfilter,
		tp,
		LOCATION_MZONE,
		0,
		nil
	)

	if chk==0 then
		return ct>0
			and Duel.IsPlayerCanDraw(tp,ct)
	end

	e:SetLabel(ct)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		ct
	)
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()

	if ct<=0 then
		return
	end

	if Duel.Draw(tp,ct,REASON_EFFECT)~=ct then
		return
	end

	if Duel.GetMatchingGroupCount(
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		nil
	)<ct then
		return
	end

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		ct,
		ct,
		nil
	)

	if #g>0 then
		Duel.SendtoGrave(
			g,
			REASON_EFFECT|REASON_DISCARD
		)
	end
end

--==================================================
-- Effect 2
--==================================================

function s.fiendfilter(c)
	return c:IsRace(RACE_FIEND)
		and c:IsDiscardable()
end

function s.thfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingMatchingCard(
				s.fiendfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				nil
			)
			and Duel.IsExistingTarget(
				s.thfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		0,
		0
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local dg=Duel.SelectMatchingCard(
		tp,
		s.fiendfilter,
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

	if Duel.SendtoGrave(
		dg,
		REASON_EFFECT|REASON_DISCARD
	)==0 then
		return
	end

	if tc:IsRelateToEffect(e) then
		Duel.BreakEffect()

		if Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)>0 then
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end

--==================================================
-- Effect 3
-- Tribute Grae
--==================================================

function s.graecost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsReleasable()
	end

	Duel.Release(c,REASON_COST)
end

function s.graeop(e,tp,eg,ep,ev,re,r,rp)
	--Create a lingering send replacement
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EFFECT_SEND_REPLACE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTarget(s.reptg)
	e1:SetValue(s.repval)
	e1:SetOperation(s.repop)
	e1:SetReset(RESET_PHASE|PHASE_END)

	--Group used to remember which cards are being replaced
	local g=Group.CreateGroup()
	g:KeepAlive()
	e1:SetLabelObject(g)

	Duel.RegisterEffect(e1,tp)
end

--==================================================
-- Replacement filter
--
-- Must be:
-- Dark World monster
-- controlled by Grae's player
-- currently in that player's hand
-- being sent to GY
-- because of EFFECT + DISCARD
-- and NOT already being resent by Grae
--==================================================

function s.repfilter(c,tp)
	return c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
		and c:IsControler(tp)
		and c:IsLocation(LOCATION_HAND)
		and c:GetDestination()==LOCATION_GRAVE
		and c:IsReason(REASON_EFFECT)
		and c:IsReason(REASON_DISCARD)
		and not c:IsReason(REASON_REPLACE)
		and c:GetFlagEffect(id)==0
end

--==================================================
-- Replacement target
--==================================================

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

--==================================================
-- Cards actually replaced
--==================================================

function s.repval(e,c)
	local g=e:GetLabelObject()
	return g:IsContains(c)
end

--==================================================
-- Replacement operation
--
-- The original send is replaced.
-- We send the cards again, but explicitly set
-- the opponent as the reason player.
--==================================================

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local container=e:GetLabelObject()

	if not container
		or #container==0
	then
		return
	end

	local g=container:Clone()
	container:Clear()

	--Mark cards temporarily so Grae's replacement
	--doesn't catch its own replacement send.
	for tc in aux.Next(g) do
		tc:RegisterFlagEffect(
			id,
			RESET_CHAIN,
			0,
			1
		)
	end

	--Important:
	--3rd argument = destination player
	--4th argument = reason player
	--
	--PLAYER_NONE means normal GY destination.
	--1-tp makes the opponent the reason player.
	Duel.SendtoGrave(
		g,
		REASON_EFFECT|REASON_DISCARD|REASON_REPLACE,
		PLAYER_NONE,
		1-tp
	)
end