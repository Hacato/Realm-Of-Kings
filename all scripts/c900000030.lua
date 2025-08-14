--Traitor of The Ashened City
local s,id=GetID()
function s.initial_effect(c)
	--Fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.ffilter1,1,s.ffilter2,1,99)
	
	--Alternative Fusion Summon procedure
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	e1:SetValue(SUMMON_TYPE_FUSION)
	c:RegisterEffect(e1)
	
	--Quick Effect: Special Summon DARK/Pyro from GY during opponent's Main/Battle Phase
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,0,EFFECT_COUNT_CODE_CHAIN) --Once per Chain
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e2:SetCondition(s.spsscon)
	e2:SetTarget(s.spsstarget)
	e2:SetOperation(s.spssop)
	c:RegisterEffect(e2)
	
	--Cannot activate in response to DARK/Pyro effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.chainop)
	c:RegisterEffect(e3)
	
	--Cannot activate in response to Obsidim
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetOperation(s.chainop2)
	c:RegisterEffect(e4)
	
	--Cannot be destroyed by card effects while Veidos is on field
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e5:SetCondition(s.indcon)
	e5:SetValue(1)
	c:RegisterEffect(e5)
end

s.listed_names={03055018,08540986,78783557} --Obsidim, the Ashened City; Veidos Fusion; Veidos
s.listed_series={0x1a5} --Ashened

--Fusion material filter 1: "Ashened" monster
function s.ffilter1(c,fc,sumtype,tp)
	return c:IsSetCard(0x1a5,fc,sumtype,tp)
end

--Fusion material filter 2: Pyro monster (from either field)
function s.ffilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_PYRO,fc,sumtype,tp)
end

--Alternative summon condition
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	return #g1>0 and #g2>0
end

--Filter for "Ashened" monster you control
function s.spfilter1(c)
	return c:IsSetCard(0x1a5) and c:IsFaceup()
end

--Filter for Obsidim in Field Zone
function s.spfilter2(c)
	return c:IsCode(03055018) and c:IsFaceup()
end

--Alternative summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg1=g1:Select(tp,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local sg2=g2:Select(tp,1,1,nil)
	
	sg1:Merge(sg2)
	sg1:KeepAlive()
	e:SetLabelObject(sg1)
	return true
end

--Alternative summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Destroy(g,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	g:DeleteGroup()
	--Set the summon type
	c:SetMaterial(g)
end

--Condition for Quick Effect special summon (opponent's Main Phase or Battle Phase)
function s.spsscon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()~=tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)
end

--Filter for DARK/Pyro monsters in GY
function s.spssfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
		and (c:IsAttribute(ATTRIBUTE_DARK) or c:IsRace(RACE_PYRO))
		and not c:IsCode(id)
end

--Check if monster with same name exists on field (for summoning restriction)
function s.namecheck(c,code)
	return c:IsCode(code) and c:IsFaceup()
end

--Target for Quick Effect special summon
function s.spsstarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spssfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spssfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
	local tc=g:GetFirst()
	if tc and (tc:IsAttribute(ATTRIBUTE_DARK) or tc:IsRace(RACE_PYRO)) then
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,tp,atk)
	end
end

--Operation for Quick Effect special summon
function s.spssop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	
	--Check if a monster with the same name already exists on your field
	if Duel.IsExistingMatchingCard(s.namecheck,tp,LOCATION_MZONE,0,1,nil,tc:GetCode()) then
		return
	end
	
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--Take damage equal to the monster's ATK
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		if atk>0 then
			Duel.Damage(tp,atk,REASON_EFFECT)
		end
		
		--Cannot summon monster with same name this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.sumlimit)
		e1:SetLabel(tc:GetCode())
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		
		--Register a flag to track what was summoned by this effect
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EFFECT_FLAG_CLIENT_HINT)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		
		--Allow the summoned monster to activate its ignition effects during opponent's turn
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_FIELD)
		e3:SetCode(EFFECT_BECOME_QUICK)
		e3:SetRange(LOCATION_MZONE)
		e3:SetTargetRange(LOCATION_MZONE,0)
		e3:SetTarget(s.quicktarget)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e3)
	end
end

--Summon limit function
function s.sumlimit(e,c)
	return c:IsCode(e:GetLabel())
end

--Target for becoming quick effect (monsters summoned by this card's effect)
function s.quicktarget(e,c)
	return c:GetFlagEffect(id)>0
end

--Chain operation for DARK/Pyro
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	if ep==tp and re:IsActiveType(TYPE_MONSTER) then
		local rc=re:GetHandler()
		if rc and (rc:IsAttribute(ATTRIBUTE_DARK) or rc:IsRace(RACE_PYRO)) then
			Duel.SetChainLimit(s.chainlm)
		end
	end
end

--Chain operation for Obsidim
function s.chainop2(e,tp,eg,ep,ev,re,r,rp)
	if ep==tp then
		local rc=re:GetHandler()
		if rc and rc:IsCode(03055018) then
			Duel.SetChainLimit(s.chainlm)
		end
	end
end

--Chain limit function
function s.chainlm(e,rp,tp)
	return tp==rp
end

--Condition for indestructibility (Veidos on field)
function s.indcon(e)
	return Duel.IsExistingMatchingCard(s.veidosfilter,e:GetHandlerPlayer(),LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

--Filter for Veidos monster (checks for both Veidos cards)
function s.veidosfilter(c)
	return (c:IsCode(08540986) or c:IsCode(78783557)) and c:IsFaceup()
end