--Fate Chaldea Master Fujimaru Ritsuka
local s,id=GetID()
function s.initial_effect(c)
	--If Normal or Special Summoned: Add 1 "Fate" Ritual Monster from GY to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--Can be used as entire Ritual requirement (once per turn)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_RITUAL_MATERIAL)
	e3:SetValue(1)
	e3:SetCondition(s.rcon)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_RITUAL_LEVEL)
	e4:SetValue(s.rituallv)
	e4:SetCondition(s.rcon)
	c:RegisterEffect(e4)
	--Register when used as Ritual Material
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_BE_MATERIAL)
	e5:SetCondition(s.regcon)
	e5:SetOperation(s.regop)
	c:RegisterEffect(e5)
	--Quick Effect: Discard this card, then target 1 "Fate" monster you control
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e6:SetRange(LOCATION_HAND)
	e6:SetCountLimit(1,{id,1})
	e6:SetCost(s.qcost)
	e6:SetTarget(s.qtg)
	e6:SetOperation(s.qop)
	c:RegisterEffect(e6)
end
s.listed_series={0x989}

--Add "Fate" Ritual Monster from GY
function s.thfilter(c)
	return c:IsSetCard(0x989) and c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

--Can be used as entire Ritual requirement (once per turn check)
function s.rcon(e)
	return Duel.GetFlagEffect(e:GetHandlerPlayer(),id+100)==0
end
function s.rituallv(e,c)
	local lv=e:GetHandler():GetLevel()
	if c:IsSetCard(0x989) and c:IsType(TYPE_RITUAL) then
		return lv|RITPROC_GREATER|RITPROC_EQUAL
	else
		return lv
	end
end
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_RITUAL
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RegisterFlagEffect(tp,id+100,RESET_PHASE+PHASE_END,0,1)
end

--Quick Effect
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.qtgfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x989) and not c:IsCode(id)
end
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.qtgfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.qtgfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.qtgfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.ritfilter(c,tc)
	return c:IsSetCard(0x989) and c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAbleToHand() and not c:IsCode(tc:GetCode())
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	local op=Duel.SelectEffect(tp,
		{true,aux.Stringid(id,2)},
		{true,aux.Stringid(id,3)},
		{true,aux.Stringid(id,4)})
	if op==1 then
		--Return to hand and add 1 "Fate" Ritual Monster with different name
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_DECK,0,1,1,nil,tc)
			if #g>0 then
				Duel.SendtoHand(g,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g)
			end
		end
	elseif op==2 then
		--Gains ATK/DEF equal to half its original ATK/DEF
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(math.floor(tc:GetBaseAttack()/2))
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		e2:SetValue(math.floor(tc:GetBaseDefense()/2))
		tc:RegisterEffect(e2)
	elseif op==3 then
		--Cannot be targeted by opponent's card effects
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
		e1:SetValue(aux.tgoval)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end