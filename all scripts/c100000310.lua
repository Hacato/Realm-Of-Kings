--Resonator Jamming
--Counter Trap Card
local s,id=GetID()
function s.initial_effect(c)
	--Activate to negate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--Set from GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O) -- Quick Effect so it works on either turn
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetHintTiming(0,TIMING_END_PHASE)
	e2:SetCost(s.setcost)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	
	-- Flag to track if this specific copy has been used this chain
	c:RegisterFlagEffect(0,0,RESET_EVENT+RESETS_STANDARD+RESET_CHAIN,0,0)
	
	-- Global flag handling for once per chain
aux.GlobalCheck(s,function()
	-- Not needed anymore, using individual card flags
end)
	
	--Create global table to track Synchros if not already created
	if not s.global_check then
		s.global_check=true
		s.resonator_synchro_summons={}
		local ge3=Effect.CreateEffect(c)
		ge3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge3:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge3:SetOperation(s.checkop3)
		Duel.RegisterEffect(ge3,0)
	end
end
s.listed_series={0x57} --Resonator series

-- Remove these functions as they're no longer needed
-- function s.checkop1(e,tp,eg,ep,ev,re,r,rp)
--     s.check=Duel.GetCurrentChain()
-- end

-- function s.checkop2(e,tp,eg,ep,ev,re,r,rp)
--     s.chain_counter[0]=0
--     s.chain_counter[1]=0
--     s.check=0
-- end

--Tracking for Synchro Summons that used Resonators
function s.checkop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	while tc do
		if tc:IsSummonType(SUMMON_TYPE_SYNCHRO) then
			local mg=tc:GetMaterial()
			if mg and mg:IsExists(s.resonatorfilter,1,nil) then
				s.resonator_synchro_summons[tc]=true
			end
		end
		tc=eg:GetNext()
	end
end

--Resonator filter
function s.resonatorfilter(c)
	return c:IsSetCard(0x57) and c:IsMonster()
end

--Condition check for activation
function s.controlsResonator(tp)
	return Duel.IsExistingMatchingCard(s.resonatorfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.controlsResonatorSynchro(tp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	while tc do
		if s.resonator_synchro_summons[tc] then
			return true
		end
		tc=g:GetNext()
	end
	return false
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainNegatable(ev) then return false end
	if not re:IsActiveType(TYPE_MONSTER) or ep==tp then return false end
	
	return s.controlsResonator(tp) or s.controlsResonatorSynchro(tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

--Set from GY effects
function s.setfilter(c)
	return c:IsSetCard(0x57) and c:IsMonster() and c:IsAbleToDeck()
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if c:GetFlagEffect(id)>0 then return false end
	
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
	
	-- Register that this specific copy has been used this chain
	c:RegisterFlagEffect(id,RESET_CHAIN,0,1)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		-- Set the card directly, bypassing normal Set restrictions
		local pos=Duel.SSet(tp,c)
		if pos==0 then return end
        
		-- Allow activation this turn
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
        
		-- Add a client hint to show the player this trap can be activated
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1))
		e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
        
		-- Banish when it leaves the field
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e3:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e3:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e3)
	end
end