--Traitor of The Ashened City
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.ffilter,aux.FilterBoolFunction(Card.IsRace,RACE_PYRO))
	
	--Alternative Special Summon procedure
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	
	--Quick Effect: Special Summon from GY during opponent's Main or Battle Phase
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Opponent cannot respond to your DARK/Pyro monsters or "Obsidim"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	e2:SetCondition(s.accon)
	c:RegisterEffect(e2)

	--Cannot be destroyed by effects while "Veidos" monster is on field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetCondition(s.indcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
end

-- "Ashened" monster fusion requirement
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x1a5,fc,sumtype,tp) -- adjust set code if needed
end

--Alternative Special Summon condition
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.fzonefilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end
function s.desfilter(c)
	return c:IsSetCard(0x1a5) and c:IsDestructable()
end
function s.fzonefilter(c)
	return c:IsFaceup() and c:IsCode(03055018)
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g1=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g2=Duel.SelectMatchingCard(tp,s.fzonefilter,tp,LOCATION_FZONE,LOCATION_FZONE,1,1,nil)
	g1:Merge(g2)
	Duel.Destroy(g1,REASON_COST)
end

--Quick effect condition
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp and (Duel.IsMainPhase() or Duel.IsBattlePhase())
end

--Targeting for special summon
function s.spfilter(c,e,tp)
	return (c:IsRace(RACE_PYRO) or c:IsAttribute(ATTRIBUTE_DARK))
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and not c:IsCode(id)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--Inflict damage equal to ATK
		local atk=tc:GetAttack()
		if atk<0 then atk=0 end
		Duel.Damage(tp,atk,REASON_EFFECT)
		--Prevent summoning monster with same name this turn
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_CANNOT_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(function(e,c) return c:IsCode(tc:GetCode()) end)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		Duel.RegisterEffect(e2,tp)
	end
end

--Opponent cannot respond to your Dark/Pyro monsters or your "Obsidim"
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	if rc:GetControler()~=e:GetHandlerPlayer() then return false end
	return (re:IsActiveType(TYPE_MONSTER) and (rc:IsAttribute(ATTRIBUTE_DARK) or rc:IsRace(RACE_PYRO)))
		or rc:IsCode(03055018)
end
function s.accon(e)
	return Duel.GetTurnPlayer()~=e:GetHandlerPlayer()
end

--Indestructible if "Veidos" monster exists
function s.indcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0xF29),e:GetHandlerPlayer(),LOCATION_MZONE,LOCATION_MZONE,1,nil)
end
