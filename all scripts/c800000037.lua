--Aquamarine Glaucus
local s,id=GetID()
function s.initial_effect(c)
	--Fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunction(Card.IsType,TYPE_FUSION),aux.FilterBoolFunction(Card.IsSetCard,0x30cd))
	
	--Banish from opponent's GY when Special Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
	
	--Reduce ATK to 0 and gain ATK (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetHintTiming(TIMING_DAMAGE_STEP,TIMING_DAMAGE_STEP+TIMINGS_CHECK_MONSTER)
	e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_CHAIN)
	e2:SetCondition(s.atkcon)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
	
	--Reset usage counter at start of each turn
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_TURN_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.resetcon)
	e3:SetOperation(s.resetcount)
	c:RegisterEffect(e3)
end
s.listed_series={0x30cd}
s.listed_names={id}

--Count "Aquamarine" monsters except this card for banish effect
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and not c:IsCode(id)
end

--Count Level 7+ "Aquamarine" monsters except this card for ATK effect limit
function s.countfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and c:IsLevelAbove(7) and not c:IsCode(id)
end

--Banish from opponent's GY target
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.cfilter,tp,LOCATION_MZONE,0,nil)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
	if chk==0 then return ct>0 and #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

--Banish from opponent's GY operation
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if ct<=0 then return end
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg=g:Select(tp,1,math.min(ct,#g),nil)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
end

--Condition for ATK reduction (includes usage limit check)
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetCurrentPhase()==PHASE_DAMAGE and Duel.IsDamageCalculated() then return false end
	local c=e:GetHandler()
	local max_uses=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_MZONE,0,nil)
	local current_uses=c:GetFlagEffect(id+100)
	return max_uses>0 and current_uses<max_uses
end

--ATK reduction target
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	local c=e:GetHandler()
	local max_uses=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_MZONE,0,nil)
	local current_uses=c:GetFlagEffect(id+100)
	if chk==0 then 
		return max_uses>0 and current_uses<max_uses and Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
end

--ATK reduction operation
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- Double-check usage limit before proceeding
		local max_uses=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_MZONE,0,nil)
		local current_uses=c:GetFlagEffect(id+100)
		if current_uses>=max_uses then
			return
		end
		
		local atk=tc:GetBaseAttack()
		--Reduce target's ATK to 0
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		--This card gains half the original ATK
		if atk>0 then
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_UPDATE_ATTACK)
			e2:SetValue(math.floor(atk/2))
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e2)
		end
		--Register that this effect was used this turn
		c:RegisterFlagEffect(id+100,0,0,1)
	end
end

--Reset condition: any turn (both players)
function s.resetcon(e,tp,eg,ep,ev,re,r,rp)
	return true
end

--Reset the usage counter at start of any turn
function s.resetcount(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():ResetFlagEffect(id+100)
end