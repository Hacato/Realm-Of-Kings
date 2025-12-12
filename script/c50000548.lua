--Fountain Lord Jabu-Jabu
local s,id=GetID()
function s.initial_effect(c)
	--Synchro summon: 1 Fish Tuner + 1+ non-Tuner WATER monsters
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FISH),1,1,Synchro.NonTunerEx(Card.IsAttribute,ATTRIBUTE_WATER),1,99)
	c:EnableReviveLimit()
	
	--Cannot be destroyed by battle
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	
	--Cannot be destroyed by card effects
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e2)
	
	--All opponent's monsters are changed to Attack Position
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_SET_POSITION)
	e3:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetValue(POS_FACEUP_ATTACK)
	c:RegisterEffect(e3)
	
	--Banish any monster this card battles at the end of the Damage Step
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_DAMAGE_STEP_END)
	e4:SetCondition(s.bancon)
	e4:SetOperation(s.banop)
	c:RegisterEffect(e4)
	
	--Force attack effect (opponent's Main Phase)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetHintTiming(0,TIMING_MAIN_END)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.forcecon)
	e5:SetTarget(s.forcetg)
	e5:SetOperation(s.forceop)
	c:RegisterEffect(e5)
end

--Banish condition
function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()
	return tc and tc:IsRelateToBattle()
end

--Banish operation
function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()
	if tc and tc:IsRelateToBattle() then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

--Force attack condition (opponent's Main Phase)
function s.forcecon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
end

--Opponent's monster filter
function s.oppfilter(c)
	return c:IsFaceup()
end

--Your Synchro monster filter
function s.syncfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO)
end

--Force attack target
function s.forcetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then return Duel.IsExistingTarget(s.oppfilter,tp,0,LOCATION_MZONE,1,nil)
		and Duel.IsExistingTarget(s.syncfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g1=Duel.SelectTarget(tp,s.oppfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g2=Duel.SelectTarget(tp,s.syncfilter,tp,LOCATION_MZONE,0,1,1,nil)
	g1:Merge(g2)
end

--Force attack operation
function s.forceop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local tc1,tc2=g:GetFirst(),g:GetNext()
	local oppmon,syncmon
	
	--Determine which is which
	if tc1:IsControler(1-tp) and tc2:IsControler(tp) then
		oppmon,syncmon=tc1,tc2
	elseif tc1:IsControler(tp) and tc2:IsControler(1-tp) then
		oppmon,syncmon=tc2,tc1
	else
		return
	end
	
	if oppmon:IsRelateToEffect(e) and syncmon:IsRelateToEffect(e) then
		--Can only attack the targeted Synchro monster
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetTargetRange(0,LOCATION_MZONE)
		e1:SetValue(s.atlimit)
		e1:SetLabel(syncmon:GetRealFieldID())
		e1:SetReset(RESET_PHASE+PHASE_END)
		oppmon:RegisterEffect(e1)
		
		--Must attack if able
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_MUST_ATTACK)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetReset(RESET_PHASE+PHASE_END)
		oppmon:RegisterEffect(e2)
		
		--Must attack the targeted monster
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_MUST_ATTACK_MONSTER)
		e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e3:SetValue(s.atktarget)
		e3:SetLabel(syncmon:GetRealFieldID())
		e3:SetReset(RESET_PHASE+PHASE_END)
		oppmon:RegisterEffect(e3)
	end
end

--Attack limitation function
function s.atlimit(e,c)
	return c:GetRealFieldID()~=e:GetLabel()
end

--Attack target function
function s.atktarget(e,c)
	return c:GetRealFieldID()==e:GetLabel()
end