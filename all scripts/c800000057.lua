--Borreload Assault Arson Dragon
local s,id=GetID()
function s.initial_effect(c)
	-- Tribute Summon using 1 Extra Deck DARK Dragon
	aux.AddNormalSummonProcedure(c,true,true,1,1,SUMMON_TYPE_TRIBUTE,aux.Stringid(id,0),s.otfilter)
	aux.AddNormalSetProcedure(c,true,true,1,1,SUMMON_TYPE_TRIBUTE,aux.Stringid(id,0),s.otfilter)

	-- Quick Effect Tribute Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER|TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.qsumcon)
	e1:SetCost(s.qsumcost)
	e1:SetTarget(s.qsumtg)
	e1:SetOperation(s.qsumop)
	c:RegisterEffect(e1)

	-- On Tribute Summon: send opponent's monster(s) to GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCondition(s.gycon)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)

	-- Store material for checking
	local e2a=Effect.CreateEffect(c)
	e2a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2a:SetCode(EVENT_SUMMON_SUCCESS)
	e2a:SetOperation(s.matop)
	c:RegisterEffect(e2a)

	-- If opponent's monster destroyed: Special Summon Rokket from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.sscon)
	e3:SetTarget(s.sstg)
	e3:SetOperation(s.ssop)
	c:RegisterEffect(e3)

	-- GY Quick Effect: Negate and shuffle
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCode(EVENT_CHAINING)
	e4:SetCondition(s.negcon)
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

s.listed_series={0x102,0x10f}

-- Tribute filter: DARK Dragon that was Special Summoned from Extra Deck
function s.otfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)
		and c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsPreviousLocation(LOCATION_EXTRA)
end

-- Quick Effect Tribute Summon condition
function s.qsumcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase() and Duel.IsExistingMatchingCard(s.otfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end

function s.qsumcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.qsumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsSummonable(true,nil,1)
	end
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,c,1,0,0)
end

function s.qsumop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	if c:IsSummonable(true,nil,1) then
		Duel.Summon(tp,c,true,nil,1)
	end
end

-- Store material information
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsSummonType(SUMMON_TYPE_TRIBUTE) then return end
	local mg=c:GetMaterial()
	if mg and #mg==1 then
		local tc=mg:GetFirst()
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
		if tc:IsSetCard(0x102) or tc:IsSetCard(0x10f) then
			c:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,0,1)
		end
	end
end

-- Tribute Summon check
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_TRIBUTE)
end

-- Send opponent monsters to GY (Tribute Summon effect)
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local c=e:GetHandler()
	local all=c:GetFlagEffect(id+100)>0
	local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
	if all then
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
	end
	Duel.SetChainLimit(function() return false end)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local all=c:GetFlagEffect(id+100)>0
	if all then
		local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_MZONE,nil,TYPE_MONSTER)
		if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,0,LOCATION_MZONE,1,1,nil,TYPE_MONSTER)
		if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
	end
end

-- Rokket revive condition
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c,tp)
		return c:IsPreviousControler(1-tp) and c:IsPreviousLocation(LOCATION_MZONE)
	end,1,nil,tp)
end

-- Rokket revive filter
function s.ssfilter(c,e,tp,eg)
	if not (c:IsSetCard(0x102) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_DEFENSE)) then return false end
	local atk=c:GetAttack()
	return eg:IsExists(function(dc,tp)
		return dc:IsPreviousControler(1-tp) and dc:IsPreviousLocation(LOCATION_MZONE) 
			and dc:GetPreviousAttackOnField()>=atk
	end,1,nil,tp)
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,eg)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ssfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp,eg)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_DEFENSE)
	end
end

-- GY Quick Effect negate
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if rc:IsRelateToEffect(re) then
			Duel.SendtoDeck(rc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end