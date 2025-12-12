--Dark Eclipse Lunar Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Ritual monster
	c:EnableReviveLimit()
	--Ritual Summon by "Eclipse Ritual"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.ritlimit)
	c:RegisterEffect(e0)
	
	--Effect 1: Change opponent's Level 5+ monster ATK to 0
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.atkcon)
	e1:SetTarget(s.atktg)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	
	--Effect 2: Take control of 0 ATK monster when destroyed
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_CONTROL)
	e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.ctrlcon)
	e2:SetTarget(s.ctrltg)
	e2:SetOperation(s.ctrlop)
	c:RegisterEffect(e2)
end

--Effect 1: ATK change effect
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL)
end

function s.atkfilter(c)
	return c:IsFaceup() and c:IsLevelAbove(5)
end

function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.atkfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.atkfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.atkfilter,tp,0,LOCATION_MZONE,1,1,nil)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--Effect 2: Control effect
function s.ctrlcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_RITUAL)
		and c:IsReason(REASON_DESTROY)
end

function s.ctrlfilter(c)
	return c:IsFaceup() and c:IsAttack(0) and c:IsControlerCanBeChanged()
end

function s.ctrltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.ctrlfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.ctrlfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	Duel.SelectTarget(tp,s.ctrlfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,0,0)
end

function s.ctrlop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		if Duel.GetControl(tc,tp,PHASE_END,2) then
			--Negate effects
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e2)
			--Change Level to 7
			local e3=Effect.CreateEffect(e:GetHandler())
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_CHANGE_LEVEL)
			e3:SetValue(7)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e3)
			--Change ATK to 2500
			local e4=Effect.CreateEffect(e:GetHandler())
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_SET_ATTACK)
			e4:SetValue(2500)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e4)
			--Change DEF to 2000
			local e5=Effect.CreateEffect(e:GetHandler())
			e5:SetType(EFFECT_TYPE_SINGLE)
			e5:SetCode(EFFECT_SET_DEFENSE)
			e5:SetValue(2000)
			e5:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e5)
		end
	end
end