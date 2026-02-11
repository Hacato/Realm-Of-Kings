--Qliphort Datamiel
--Scripted by: Assistant
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Pendulum Summon
	Pendulum.AddProcedure(c)
	--Fusion Materials: 2 "Qliphort" monsters
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xaa),aux.FilterBoolFunctionEx(Card.IsSetCard,0xaa))
	--Must be Special Summoned by Tributing
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--Special Summon procedure (Tribute 2 "Qliphort" monsters)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--Pendulum Effects
	--Cannot Special Summon except "Qli" monsters (cannot be negated)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e2:SetRange(LOCATION_PZONE)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.pslimit)
	c:RegisterEffect(e2)
	--Reduce opponent's hand size limit
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_HAND_LIMIT)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_PZONE)
	e3:SetTargetRange(0,1)
	e3:SetValue(s.handlimit)
	c:RegisterEffect(e3)
	--Prevent opponent from adding cards if over limit
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_TO_HAND)
	e4:SetRange(LOCATION_PZONE)
	e4:SetTargetRange(0,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
	e4:SetTarget(s.thlimit)
	c:RegisterEffect(e4)
	
	--Monster Effects
	--Unaffected by Spells/Traps and other Fusion monsters' effects if Special Summoned from Extra Deck
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetCode(EFFECT_IMMUNE_EFFECT)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.immcon)
	e5:SetValue(s.immval)
	c:RegisterEffect(e5)
	--Register if summoned from Extra Deck
	local e5b=Effect.CreateEffect(c)
	e5b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5b:SetCondition(s.regcon)
	e5b:SetOperation(s.regop)
	c:RegisterEffect(e5b)
	--Negate activation and place in Pendulum Zone
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_CHAINING)
	e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCondition(s.negcon)
	e6:SetTarget(s.negtg)
	e6:SetOperation(s.negop)
	c:RegisterEffect(e6)
end
s.listed_series={0xaa}

--Special Summon condition: Must be Special Summoned by own procedure or Fusion Summon
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION or se:GetHandler()==e:GetHandler()
end

--Special Summon procedure filters
function s.spfilter(c)
	return c:IsSetCard(0xaa) and c:IsReleasable() and c:IsMonster()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and #rg>=2 and aux.SelectUnselectGroup(rg,e,tp,2,2,aux.ChkfMMZ(1),0)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
	local g=aux.SelectUnselectGroup(rg,e,tp,2,2,aux.ChkfMMZ(1),1,tp,HINTMSG_RELEASE)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST)
	g:DeleteGroup()
end

--Pendulum Effects
function s.pslimit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsSetCard(0xaa)
end

--Count Tribute Summoned "Qli" monsters with different names and return modified hand limit
function s.tsfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xaa) and (c:GetSummonType()&SUMMON_TYPE_TRIBUTE)==SUMMON_TYPE_TRIBUTE
end

function s.handlimit(e)
	local tp=e:GetHandlerPlayer()
	local g=Duel.GetMatchingGroup(s.tsfilter,tp,LOCATION_MZONE,0,nil)
	local names={}
	local count=0
	for tc in aux.Next(g) do
		local code=tc:GetCode()
		if not names[code] then
			names[code]=true
			count=count+1
		end
	end
	-- Return the new hand limit (base 6 minus count)
	local new_limit=6-count
	if new_limit<0 then new_limit=0 end
	return new_limit
end

--Prevent adding if opponent has more cards than their current limit
function s.thlimit(e,c)
	local tp=e:GetHandlerPlayer()
	local limit=s.handlimit(e)
	return Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>limit
end

--Monster Effects
--Register if summoned from Extra Deck
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_EXTRA)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

--Immunity condition: Was summoned from Extra Deck
function s.immcon(e)
	return e:GetHandler():GetFlagEffect(id)>0
end

--Immunity value: Unaffected by Spells/Traps and other Fusion monsters
function s.immval(e,te)
	local tc=te:GetHandler()
	return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) or (tc:IsType(TYPE_FUSION) and tc~=e:GetHandler())
end

--Negate condition: Only opponent's cards
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev) and rp==1-tp
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
	if c:IsRelateToEffect(e) and Duel.CheckPendulumZones(tp) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end