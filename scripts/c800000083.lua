--Fate The Holy Army
--Scripted by Leshun & Astra
local s,id=GetID()
function s.initial_effect(c)
	--(1) Activate: Remains on field like Different Dimension Capsule
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(aux.RemainFieldCost) -- This line ensures it remains face-up on the field
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--(2) Place Relic Counter when "Fate" monster(s) are Special Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
	--(3) "Fate" monsters gain 300 ATK/DEF for each Relic Counter on your field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.statfilter)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
	--(4) If you control a "Ruler" monster, battle positions of "Fate" monsters cannot be changed by opponent
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_CHANGE_POS_E)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetRange(LOCATION_SZONE)
	e5:SetTargetRange(0,LOCATION_MZONE)
	e5:SetCondition(s.poscon)
	e5:SetTarget(s.postg)
	c:RegisterEffect(e5)
end

--(1) Activation Operation: stay on field, send to GY at opponent’s End Phase then draw 1
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and not c:IsStatus(STATUS_LEAVE_CONFIRMED) then
		-- Register effect to trigger at opponent's End Phase
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetCondition(s.tgcon)
		e1:SetOperation(s.tgop)
		e1:SetLabelObject(c)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
		Duel.RegisterEffect(e1,tp)
	else
		c:CancelToGrave(false) -- Keep on field if activation resolves incorrectly
	end
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if not c or not c:IsFaceup() then return end
	if Duel.SendtoGrave(c,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

--(2) Place 1 Relic Counter on your "Fate" Field Spell when you Special Summon a "Fate" monster
function s.ctfilter(c,tp)
	return c:IsSetCard(0x989) and c:IsSummonPlayer(tp)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if not eg:IsExists(s.ctfilter,1,nil,tp) then return end
	local g=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_FZONE,0,nil)
	for tc in g:Iter() do
		tc:AddCounter(0x1997,1)
	end
end
function s.fieldfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x989)
end

--(3) ATK/DEF gain for "Fate" monsters
function s.statfilter(e,c)
	return c:IsSetCard(0x989)
end
function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,0,nil)
	local ct=0
	for tc in g:Iter() do
		ct=ct+tc:GetCounter(0x1997)
	end
	return ct*300
end

--(4) Battle position lock if you control a "Ruler" monster
function s.rulerfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xF81)
end
function s.poscon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.rulerfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.postg(e,c)
	return c:IsControler(e:GetHandlerPlayer()) and c:IsSetCard(0x989)
end
