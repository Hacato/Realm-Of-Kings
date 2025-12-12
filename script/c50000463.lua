--Refractor Shield
local s,id=GetID()
function s.initial_effect(c)
	--Negate damage and boost ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	-- Check if the chaining effect would inflict damage to the player
	if rp==1-tp then
		local ex,cg,ct,cp,cv=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
		if ex and cv>0 and (cp==tp or cp==PLAYER_ALL) then
			e:SetLabel(cv)
			return true
		end
	end
	return false
end

function s.atkfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO) and c:IsType(TYPE_PENDULUM)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.atkfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atkfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.atkfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local damage_amount=e:GetLabel()
	
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and damage_amount>0 then
		-- Negate the damage from the current chain
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CHANGE_DAMAGE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetLabel(ev) -- Use the chain link number
		e1:SetValue(s.damval)
		e1:SetReset(RESET_CHAIN)
		Duel.RegisterEffect(e1,tp)
		
		-- Increase target's ATK by half the damage
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(math.floor(damage_amount/2))
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end

function s.damval(e,re,val,r,rp,rc)
	if Duel.GetCurrentChain()==e:GetLabel() then
		return 0
	end
	return val
end