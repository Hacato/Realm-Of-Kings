--Super Sonic, Last Resort of Team Sonic
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c,false)
	-- Corrected Synchro procedure: 1 Synchro Tuner + 1+ non-Tuner Pendulum Synchro monsters
	Synchro.AddProcedure(c,s.tunerfilter,1,1,s.nontunerfilter,1,99)
	
	--Pendulum Effect: Pendulum Synchro cards you control are unaffected by opponent's card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.datg)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	
	--Monster Effect 1: Place in Pendulum Zone when Synchro Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.tftg)
	e2:SetOperation(s.tfop)
	c:RegisterEffect(e2)
	
	--Monster Effect 2: Destroy all opponent's cards at Battle Phase start
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.target)
	e3:SetOperation(s.activate)
	c:RegisterEffect(e3)
	
	--Monster Effect 3: Special Summon when leaving field
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCondition(s.sumcon)
	e4:SetTarget(s.sumtg)
	e4:SetOperation(s.sumop)
	c:RegisterEffect(e4)
end

-- Synchro material filters
function s.tunerfilter(c,scard,sumtype,tp)
	return c:IsType(TYPE_SYNCHRO,scard,sumtype,tp) and c:IsType(TYPE_TUNER,scard,sumtype,tp)
end
function s.nontunerfilter(c,scard,sumtype,tp)
	return c:IsType(TYPE_PENDULUM,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp) and not c:IsType(TYPE_TUNER,scard,sumtype,tp)
end

-- Pendulum Effect functions
function s.datg(e,c)
	return c:IsType(TYPE_PENDULUM) and c:IsType(TYPE_SYNCHRO)
end
function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Monster Effect 1: Place in Pendulum Zone
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.pcfilter(c)
	return c:IsCode(id) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1))
		and Duel.IsExistingMatchingCard(s.pcfilter,tp,LOCATION_EXTRA,0,1,nil) end
end
function s.tfop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.pcfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g>0 then
		Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

-- Monster Effect 2: Destroy all opponent's cards
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) end
	local sg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,sg,#sg,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local sg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
	Duel.Destroy(sg,REASON_EFFECT)
end

-- Monster Effect 3: Special Summon when leaving field
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousPosition(POS_FACEUP) and e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end
function s.filter(c,e,tp)
	return c:IsType(TYPE_PENDULUM) and c:IsType(TYPE_SYNCHRO) and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup()) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,true)
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local loc=LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED
	if Duel.GetLocationCountFromEx(tp,tp)<=0 then
		loc=LOCATION_GRAVE+LOCATION_REMOVED
	end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.filter,tp,loc,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,loc)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local loc=LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED
	if Duel.GetLocationCountFromEx(tp,tp)<=0 then
		loc=LOCATION_GRAVE+LOCATION_REMOVED
	end
	local tg=Duel.SelectMatchingCard(tp,s.filter,tp,loc,0,1,1,nil,e,tp)
	if tg then
		Duel.SpecialSummon(tg,0,tp,tp,false,true,POS_FACEUP)
	end
end