--OTNN Tail Red
--c99930010
--Scripted by Hacato
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--Xyz Summon: 2+ Warrior monsters with same Level
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_WARRIOR),nil,2,nil,nil,Xyz.InfiniteMats,nil,false,function(g) return g:GetClassCount(Card.GetLevel)==1 end)

	--(1) Gain Rank per material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_RANK)
	e1:SetValue(function(e) return e:GetHandler():GetOverlayCount() end)
	c:RegisterEffect(e1)

	--(2) ATK gain on attack
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	--(3) Attach destroyed monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdocon)
	e3:SetTarget(s.atchtg)
	e3:SetOperation(s.atchop)
	c:RegisterEffect(e3)

	--(4) Negate targeting Xyz monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)

	--(5) Continuous extra attack
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_EXTRA_ATTACK)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.extracon)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

--(2) ATK gain
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		e1:SetValue(c:GetRank()*500)
		c:RegisterEffect(e1)
	end
end

--(3) Attach destroyed monster
function s.atchtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		return bc and bc:IsMonster() and bc:IsLocation(LOCATION_GRAVE)
			and bc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT)
	end
	Duel.SetTargetCard(bc)
end

function s.atchop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,tc)
	end
end

--(4) Negate targeting Xyz monsters
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp or not Duel.IsChainNegatable(ev) then return false end
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsExists(function(c) return c:IsControler(tp) and c:IsType(TYPE_XYZ) end,1,nil)
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and c:IsFaceup() then
		local atk=c:GetAttack()
		if atk>0 then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			e1:SetValue(math.floor(atk/2))
			c:RegisterEffect(e1)
		end
	end
end

--(5) Continuous extra attack condition
function s.extracon(e)
	local c=e:GetHandler()
	-- Must have opponent-owned material
	if not c:GetOverlayGroup():IsExists(function(tc)
		return tc:GetOwner()~=c:GetControler()
	end,1,nil) then
		return false
	end
	-- Must have destroyed a monster by battle this turn
	return c:GetBattledGroupCount()>0
end