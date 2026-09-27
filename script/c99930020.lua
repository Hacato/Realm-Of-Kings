--OTNN Tail Blue
--Scripted by Hacato
--99930020
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()

	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_WARRIOR),nil,2,nil,nil,Xyz.InfiniteMats,nil,false,function(g) return g:GetClassCount(Card.GetLevel)==1 end)

	--(1) Rank gain
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_RANK)
	e1:SetValue(function(e) return e:GetHandler():GetOverlayCount() end)
	c:RegisterEffect(e1)

	--(2) ATK gain
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	--(3) Attach destroyed monster
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdocon)
	e3:SetTarget(s.atchtg)
	e3:SetOperation(s.atchop)
	c:RegisterEffect(e3)

	--(4) Negate Special Summon
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_SPSUMMON)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.dscon)
	e4:SetCost(s.dscost)
	e4:SetOperation(s.dsop)
	c:RegisterEffect(e4)

	--(5) Piercing
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_PIERCE)
	e5:SetCondition(s.piercecon)
	c:RegisterEffect(e5)

	--(5b) Triple piercing damage (FIXED PROPERLY)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e6:SetCondition(s.damcon)
	e6:SetOperation(s.damop)
	c:RegisterEffect(e6)
end

--(2)
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
		e1:SetValue(c:GetRank()*500)
		c:RegisterEffect(e1)
	end
end

--(3)
function s.atchtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then
		return bc and bc:IsMonster() and bc:IsLocation(LOCATION_GRAVE)
			and bc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT)
	end
	Duel.SetTargetCard(bc)
end

function s.atchop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,tc)
	end
end

--(4)
function s.dscon(e,tp,eg,ep,ev,re,r,rp)
	return tp~=ep and #eg==1 and Duel.GetCurrentChain()==0
end

function s.dscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.dsop(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateSummon(eg)
	if Duel.Destroy(eg,REASON_EFFECT)~=0 then
		Duel.BreakEffect()
		Duel.Damage(1-tp,1000,REASON_EFFECT)
	end
end

--Helper
function s.hasOppMat(c)
	return c:GetOverlayGroup():IsExists(function(tc)
		return tc:GetOwner()~=c:GetControler()
	end,1,nil)
end

--Piercing condition
function s.piercecon(e)
	return s.hasOppMat(e:GetHandler())
end

--Triple damage condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return ep~=tp
		and Duel.GetAttacker()==c
		and Duel.GetAttackTarget()
		and Duel.GetAttackTarget():IsDefensePos()
		and s.hasOppMat(c)
end

--Triple damage operation (FINAL FIX)
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local dam=Duel.GetBattleDamage(ep)
	if dam>0 then
		Duel.ChangeBattleDamage(ep,dam*3)
	end
end