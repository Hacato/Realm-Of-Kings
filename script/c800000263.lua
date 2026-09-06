--Sky Striker Mecha - Scorpion Gladius
local s,id=GetID()

local SET_SKY_STRIKER_ACE=0x1115

function s.initial_effect(c)
	--Equip procedure
	--Activate only if you control no monsters
	--in your Main Monster Zone
	aux.AddEquipProcedure(c,nil,nil,nil,nil,nil,nil,s.condition)

	--Piercing battle damage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_EQUIP)
	e1:SetCode(EFFECT_PIERCE)
	c:RegisterEffect(e1)

	--If you have 3 or more Spells in your GY,
	--double the battle damage inflicted
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e2:SetCondition(s.damcon)
	e2:SetValue(DOUBLE_DAMAGE)
	c:RegisterEffect(e2)

	--When the equipped monster inflicts battle damage:
	--Draw 1 card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)

	--When a card or effect is activated that would destroy
	--a "Sky Striker Ace" monster(s) you control:
	--Send this equipped card to the GY;
	--negate the activation, and if you do, destroy that card
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

--------------------------------------------------
--Sky Striker activation condition
--------------------------------------------------

function s.cfilter(c)
	return c:GetSequence()<5
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(
		s.cfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

--------------------------------------------------
--3 or more Spells in your GY
--------------------------------------------------

function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
end

function s.damcon(e)
	local tp=e:GetHandlerPlayer()

	return Duel.GetMatchingGroupCount(
		s.spellfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)>=3
end

--------------------------------------------------
--Draw 1 card when equipped monster
--inflicts battle damage
--------------------------------------------------

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	if ep~=1-tp or ev<=0 then
		return false
	end

	local ec=e:GetHandler():GetEquipTarget()

	if not ec then
		return false
	end

	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()

	return a==ec or d==ec
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
	local p,ct=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER,
		CHAININFO_TARGET_PARAM
	)

	Duel.Draw(
		p,
		ct,
		REASON_EFFECT
	)
end

--------------------------------------------------
--Check whether an activated card/effect would
--destroy a "Sky Striker Ace" monster you control
--------------------------------------------------

function s.acefilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(SET_SKY_STRIKER_ACE)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainNegatable(ev) then
		return false
	end

	if not re:IsHasCategory(CATEGORY_DESTROY) then
		return false
	end

	local ex,g,ct,p,loc=Duel.GetOperationInfo(
		ev,
		CATEGORY_DESTROY
	)

	if not ex then
		return false
	end

	--If the destruction effect has determined cards
	if g then
		return g:IsExists(
			s.acefilter,
			1,
			nil,
			tp
		)
	end

	--Fallback for non-targeting destruction effects
	return Duel.IsExistingMatchingCard(
		function(c)
			return c:IsFaceup()
				and c:IsSetCard(SET_SKY_STRIKER_ACE)
		end,
		tp,
		LOCATION_MZONE,
		0,
		1,
		nil
	)
end

--------------------------------------------------
--Send this equipped card to the GY as cost
--------------------------------------------------

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToGraveAsCost()
	end

	Duel.SendtoGrave(
		c,
		REASON_COST
	)
end

--------------------------------------------------
--Negate activation and destroy that card
--------------------------------------------------

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)

	local rc=re:GetHandler()

	if rc and rc:IsDestructable() then
		Duel.SetOperationInfo(
			0,
			CATEGORY_DESTROY,
			rc,
			1,
			0,
			0
		)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if Duel.NegateActivation(ev)
		and rc
		and rc:IsRelateToEffect(re) then

		Duel.Destroy(
			rc,
			REASON_EFFECT
		)
	end
end