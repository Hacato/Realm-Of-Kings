--Aquamarine Reef Hapalochlaena
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Material: 2 Level 7 or higher "Aquamarine" Fusion Monsters
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter,s.matfilter)
	--Must be Fusion Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--Unaffected by other card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.immcon)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	--Inflict damage (Quick Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMING_MAIN_END)
	e2:SetCondition(s.damcon)
	e2:SetCost(s.damcost)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
	--Register for turn reset
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_PHASE_START+PHASE_DRAW)
		ge1:SetOperation(s.clear_count)
		Duel.RegisterEffect(ge1,0)
	end
end

--Fusion material filter: Level 7+ Aquamarine Fusion monsters
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION) and c:IsLevelAbove(7)
end

--Must be Fusion Summoned
function s.splimit(e,se,sp,st)
	return st&SUMMON_TYPE_FUSION==SUMMON_TYPE_FUSION
end

--Check if Aquamarine Glaucus or Physalia is in GY for immunity
function s.immfilter(c)
	return c:IsCode(800000037,800000036)
end

function s.immcon(e)
	return Duel.IsExistingMatchingCard(s.immfilter,e:GetHandlerPlayer(),LOCATION_GRAVE,0,1,nil)
end

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--Damage effect: Main Phase only, proper timing
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2) 
		and Duel.GetTurnPlayer()==tp
end

--Cost: Banish 1 "Aquamarine" Fusion Monster from GY (except this card)
function s.damcostfilter(c)
	return c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION) and not c:IsCode(id) and c:IsAbleToRemoveAsCost()
end

function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.damcostfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.damcostfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

--Target: Check usage limit and prevent chaining to itself
function s.countfilter(c)
	return c:IsSetCard(0x30cd) and c:IsLevelAbove(8) and c:IsFaceup() and not c:IsCode(id)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		--Prevent chaining to itself
		local chain_count=Duel.GetCurrentChain()
		if chain_count>0 then
			for i=1,chain_count do
				local ce=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_EFFECT)
				if ce and ce:GetHandler()==e:GetHandler() and ce:GetCode()==e:GetCode() then
					return false
				end
			end
		end
		--Check if we can still use this effect this turn
		local max_uses=Duel.GetMatchingGroupCount(s.countfilter,tp,LOCATION_MZONE,0,nil)
		local current_uses=e:GetHandler():GetFlagEffect(id)
		return current_uses<max_uses and Duel.IsExistingMatchingCard(s.damcostfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(1000)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end

--Operation: Inflict 1000 damage and register usage
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local d=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
	if Duel.Damage(p,d,REASON_EFFECT)>0 then
		--Register that this effect was used this turn
		e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end

--Clear usage counters at start of each turn
function s.clear_count(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsCode,0,LOCATION_MZONE,LOCATION_MZONE,nil,id)
	for tc in aux.Next(g) do
		tc:ResetFlagEffect(id)
	end
end