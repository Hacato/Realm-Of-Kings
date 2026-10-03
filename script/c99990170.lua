--SAO Klein - SAO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) Once per turn:
	--Remove 1 En-Counter;
	--for the rest of this turn, all "SAO" monsters
	--you control gain 300 ATK.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.atkcost)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) If this card on the field is sent to the GY:
	--Draw 1 card.
	--HOPT
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			0x1994,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--"SAO" MONSTER FILTER
----------------------------------------------------------

function s.atkfilter(e,c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
end

----------------------------------------------------------
--ALL "SAO" MONSTERS YOU CONTROL GAIN 300 ATK
--FOR THE REST OF THIS TURN
----------------------------------------------------------

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.atkfilter)
	e1:SetValue(300)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

----------------------------------------------------------
--(2) SENT FROM THE FIELD TO THE GY
----------------------------------------------------------

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER,
		CHAININFO_TARGET_PARAM
	)

	Duel.Draw(
		p,
		d,
		REASON_EFFECT
	)
end