--Ame no Habakiri X-Drive - Tsubasa
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(s.synfilter),1,1,s.tunermat)

	--Must be Synchro Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.synlimit)
	c:RegisterEffect(e0)

	--Cannot be negated if Synchro Summoned during opponent's turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCondition(s.effcon)
	c:RegisterEffect(e1)

	--Register that it was Synchro Summoned during opponent's turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.regcon)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)

	--Quick battle during opponent's turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCondition(s.battlecon)
	e3:SetTarget(s.battletg)
	e3:SetOperation(s.battleop)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OPPONENT_TURN)
	c:RegisterEffect(e3)

	--Gain ATK and prevent opponent from activating during battle
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_BATTLE_START)
	e4:SetCondition(s.atkcon)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
end
s.listed_series={0x2406}

--Synchro material filter - "SZS" monster
function s.synfilter(c,scard,sumtype,tp)
	return c:IsSetCard(0x2406,scard,sumtype,tp)
end

--Synchro material filter - allow Level 4 "SZS" to be treated as Tuner
function s.tunermat(c,scard,sumtype,tp)
	return c:IsSetCard(0x2406,scard,sumtype,tp) or (c:IsSetCard(0x2406,scard,sumtype,tp) and c:IsLevel(4,scard,sumtype,tp))
end

--Cannot be negated if summoned during opponent's turn
function s.effcon(e)
	return Duel.GetTurnPlayer()==1-e:GetHandlerPlayer()
end

--Register permanent flag: Synchro Summoned during opponent's turn
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) and Duel.GetTurnPlayer()==1-tp
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	--Permanent as long as it stays on field
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

--Quick battle during opponent's turn
function s.battlecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local phase=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==1-tp
		and c:GetFlagEffect(id)>0
		and c:IsAttackPos()
		and phase~=PHASE_DAMAGE and phase~=PHASE_DAMAGE_CAL
end
function s.battletg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	end
end
function s.battleop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACKTARGET)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	if #g>0 then
		Duel.CalculateDamage(c,g:GetFirst())
	end
end

--Gain ATK and prevent activation during battle
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetBattleTarget()~=nil and c:GetBattleTarget():IsControler(1-tp)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc then return end
	
	--Gain 1000 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(1000)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
	c:RegisterEffect(e1)
	
	--Opponent cannot activate cards or effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetTargetRange(0,1)
	e2:SetValue(1)
	e2:SetReset(RESET_PHASE+PHASE_DAMAGE)
	Duel.RegisterEffect(e2,tp)
end