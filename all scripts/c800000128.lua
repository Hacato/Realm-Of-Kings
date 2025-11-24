--SZS Gungnir X-Drive - Hibiki
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99,s.tunermat)
	--Must be Synchro Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.synlimit)
	c:RegisterEffect(e0)
	--Cannot be negated if Synchro Summoned during opponent's turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_DISABLE_SPSUMMON)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCondition(s.effcon)
	c:RegisterEffect(e2)
	local e2b=Effect.CreateEffect(c)
	e2b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2b:SetCondition(s.sumcon)
	e2b:SetOperation(s.sumop)
	c:RegisterEffect(e2b)
	--Quick battle during opponent's turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCondition(s.battlecon)
	e3:SetTarget(s.battletg)
	e3:SetOperation(s.battleop)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OPPONENT_TURN)
	c:RegisterEffect(e3)
	--Register Synchro Summon during opponent's turn
	local e3b=Effect.CreateEffect(c)
	e3b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3b:SetCondition(s.regcon)
	e3b:SetOperation(s.regop)
	c:RegisterEffect(e3b)
	--Inflict damage and destroy adjacent monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_DAMAGE+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_BATTLE_DESTROYING)
	e4:SetCondition(s.damcon)
	e4:SetTarget(s.damtg)
	e4:SetOperation(s.damop)
	c:RegisterEffect(e4)
end
s.listed_series={0x2406}

--Synchro material filter - allow Level 4 "SZS" to be treated as Tuner
function s.tunermat(c,scard,sumtype,tp)
	return c:IsSetCard(0x2406,scard,sumtype,tp) or (c:IsSetCard(0x2406,scard,sumtype,tp) and c:IsLevel(4,scard,sumtype,tp))
end

--Cannot be negated if summoned during opponent's turn
function s.effcon(e)
	return Duel.GetTurnPlayer()==1-e:GetHandlerPlayer()
end
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler()) and Duel.GetTurnPlayer()==1-tp
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetChainLimitTillChainEnd(function() return false end)
end

--Register Synchro Summon during opponent's turn
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO) and Duel.GetTurnPlayer()==1-tp
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
end

--Quick battle during opponent's turn
function s.battlecon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp and e:GetHandler():GetFlagEffect(id)>0
		and e:GetHandler():IsAttackPos()
end
function s.battletg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
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

--Inflict damage and destroy adjacent monsters
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	local atk=bc:GetBaseAttack()
	if atk<0 then atk=0 end
	Duel.SetTargetCard(bc)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,atk)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local bc=Duel.GetFirstTarget()
	if bc and bc:IsRelateToEffect(e) then
		local atk=bc:GetBaseAttack()
		if atk<0 then atk=0 end
		if Duel.Damage(1-tp,atk,REASON_EFFECT)>0 then
			--Destroy adjacent monsters
			local seq=bc:GetPreviousSequence()
			local dg=Group.CreateGroup()
			if seq>0 then
				local tc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq-1)
				if tc then dg:AddCard(tc) end
			end
			if seq<4 then
				local tc=Duel.GetFieldCard(1-tp,LOCATION_MZONE,seq+1)
				if tc then dg:AddCard(tc) end
			end
			if #dg>0 then
				Duel.BreakEffect()
				Duel.Destroy(dg,REASON_EFFECT)
			end
		end
	end
end