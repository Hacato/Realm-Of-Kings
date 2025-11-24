-- Wyrm Excavator the Heavy Cavalry Draco [CENTER]
local s,id=GetID()

-- REQUIRED for Maximum Monsters
s.MaximumAttack = 4000

function s.initial_effect(c)
	-- Maximum Summon Procedure
	Maximum.AddProcedure(c, nil, s.left_filter, s.right_filter)

	----------------------------------------------------
	-- Effect 1: Cannot be destroyed by opponent's Trap
	----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.maxmode_center)
	e1:SetValue(s.indval)
	c:RegisterEffect(e1)
	c:AddCenterToSideEffectHandler(e1)

	----------------------------------------------------
	-- Effect 2: Negate & destroy Quick Effect
	----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.maxmode_center_negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
	c:AddCenterToSideEffectHandler(e2)

	----------------------------------------------------
	-- ✔ Maximum ATK handler restored
	----------------------------------------------------
	c:AddMaximumAtkHandler()

	----------------------------------------------------
	-- Effect 3: Replacement protection for Max monsters
	----------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)

	----------------------------------------------------
	-- Effect 4: Bounce S/T (fixed)
	----------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetCountLimit(1)
	e5:SetCondition(s.maxmode_center)
	e5:SetTarget(s.bouncetg)
	e5:SetOperation(s.bounceop)
	c:RegisterEffect(e5)
	c:AddCenterToSideEffectHandler(e5)
end

----------------------------------------------------
-- Filters
----------------------------------------------------
function s.left_filter(c) return c:IsCode(800000119) end
function s.right_filter(c) return c:IsCode(800000121) end

----------------------------------------------------
-- Conditions
----------------------------------------------------
function s.maxmode_center(e)
	return e:GetHandler():IsMaximumModeCenter()
end

function s.maxmode_center_negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsMaximumModeCenter() 
		and rp==1-tp 
		and Duel.IsChainNegatable(ev)
end

----------------------------------------------------
-- Effect 1: Trap indestructible
----------------------------------------------------
function s.indval(e,re,rp)
	return re:IsActiveType(TYPE_TRAP) and rp~=e:GetHandlerPlayer()
end

----------------------------------------------------
-- Effect 2: Negate & destroy
----------------------------------------------------
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) 
	end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) 
		and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

----------------------------------------------------
-- Replacement protection
----------------------------------------------------
function s.repfilter(c)
	return c:IsCode(800000119,800000121) and c:IsAbleToRemove()
end

function s.repfilter2(c,tp)
	return c:IsControler(tp) and c:IsFaceup()
		and c:IsSummonType(SUMMON_TYPE_MAXIMUM)
		and (c:IsReason(REASON_EFFECT) or c:IsReason(REASON_BATTLE))
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return e:GetHandler():IsMaximumModeCenter()
			and eg:IsExists(s.repfilter2,1,nil,tp)
			and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	return Duel.SelectYesNo(tp,aux.Stringid(id,2))
end

function s.repval(e,c)
	return c:IsFaceup()
		and c:IsControler(e:GetHandlerPlayer())
		and c:IsSummonType(SUMMON_TYPE_MAXIMUM)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	end
end

----------------------------------------------------
-- Effect 4: Bounce S/T (fixed)
----------------------------------------------------
function s.bouncefilter(c)
    return c:IsSpellTrap()
        and c:IsAbleToHand()
        and not c:IsStatus(STATUS_LEAVE_CONFIRMED)
end

function s.bouncetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsOnField() 
			and chkc:IsControler(1-tp) 
			and s.bouncefilter(chkc)
	end
	if chk==0 then 
		return Duel.IsExistingTarget(s.bouncefilter,tp,0,LOCATION_ONFIELD,1,nil) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.bouncefilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.bounceop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end
