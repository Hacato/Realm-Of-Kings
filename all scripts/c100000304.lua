--Resonator Gift
--Normal Spell Card
local s,id=GetID()
function s.initial_effect(c)
	--Activate to draw
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--Register a global effect for tracking Synchro Summons that used Resonators
	if not s.global_check then
		s.global_check=true
		s.resonator_synchro_summons={}
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
	
	--Protection effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end
s.listed_series={0x57} --Resonator

function s.resonatorfilter(c)
	return c:IsSetCard(0x57) and c:IsMonster()
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.resonatorfilter,tp,LOCATION_GRAVE,0,nil)
	return g:GetClassCount(Card.GetCode)>=3
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end

-- Global tracking function for Synchro Summons using Resonators
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
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

--Protection effect
function s.repfilter(c,tp)
	if not c:IsLocation(LOCATION_MZONE) or not c:IsFaceup() or not c:IsControler(tp) 
		or not c:IsReason(REASON_BATTLE+REASON_EFFECT) then
		return false
	end
	
	-- Check if this card was Synchro Summoned using a Resonator
	return s.resonator_synchro_summons[c]==true
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local res = Duel.GetFlagEffect(tp,id)==0 and e:GetHandler():IsAbleToRemove()
			and eg:IsExists(s.repfilter,1,nil,tp)
		return res
	end
	
	if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		return true
	else
		return false
	end
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end