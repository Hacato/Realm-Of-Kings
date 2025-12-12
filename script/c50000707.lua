--Gold Face - Yaldabaoth
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--spsummon condition
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e1)
	--special summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SPSUMMON_PROC)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--immune
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetCondition(s.immcon)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)
	--battle protection
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e4:SetCondition(s.immcon)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	--chain attack
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_BATTLE_DESTROYING)
	e5:SetCountLimit(1)
	e5:SetCondition(s.atcon)
	e5:SetOperation(s.atop)
	c:RegisterEffect(e5)
end

function s.spfilter1(c)
	return c:IsFaceup() and c:IsLevel(8) and c:IsRace(RACE_MACHINE) and c:IsAbleToGraveAsCost()
end
function s.spfilter2(c)
	return c:IsFaceup() and c:IsLevelBelow(4) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_FLIP) and c:IsAbleToGraveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=e:GetHandlerPlayer()
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_MZONE,0,nil)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-2 and #g1>0 and #g2>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_MZONE,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_MZONE,0,nil)
	local sg1=g1:Select(tp,1,1,nil)
	local sg2=g2:Select(tp,1,1,nil)
	sg1:Merge(sg2)
	if #sg1==2 then
		sg1:KeepAlive()
		e:SetLabelObject(sg1)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST)
	g:DeleteGroup()
end

--Check for face-down cards in Field Zones (sequence 5 for both players)
function s.fieldfilter(c)
	return c:IsFacedown() and c:IsLocation(LOCATION_FZONE)
end
function s.immcon(e)
	return Duel.IsExistingMatchingCard(s.fieldfilter,0,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

--Fixed immunity filter: unaffected by opponent's effects except Field Spells
function s.efilter(e,te)
	local c=e:GetHandler()
	local tc=te:GetOwner()
	--Only affects opponent's card effects
	if tc:GetControler()==c:GetControler() then return false end
	--Exception: opponent's Field Spells still affect this card
	if te:IsActiveType(TYPE_FIELD) and te:IsActiveType(TYPE_SPELL) then return false end
	--Block all other opponent effects
	return true
end

function s.atcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return Duel.GetAttacker()==c and aux.bdocon(e,tp,eg,ep,ev,re,r,rp) and c:CanChainAttack()
end
function s.atop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ChainAttack()
end