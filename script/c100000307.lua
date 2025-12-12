--Fusion Dragon Fiend
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.ffilter1,s.ffilter2)
	
	--Special summon condition
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	
	--Negate activation, destroy, and then special summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
	
	--Gain ATK equal to damage
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BATTLE_DAMAGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.atkcon1)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_DAMAGE)
	e4:SetCondition(s.atkcon2)
	c:RegisterEffect(e4)
end
s.miracle_synchro_fusion=true

--Special Summon Condition
function s.splimit(e,se,sp,st)
	if e:GetHandler():IsLocation(LOCATION_EXTRA) then
		return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
	end
	return true
end

--Fusion Materials filter
function s.ffilter1(c,fc,sumtype,tp)
	return c:IsRace(RACE_DRAGON,fc,sumtype,tp) and c:IsType(TYPE_SYNCHRO,fc,sumtype,tp)
end

function s.ffilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_FIEND,fc,sumtype,tp)
end

--Negate activation condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER) and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) 
		and Duel.IsChainNegatable(ev)
end

--Cost: banish 1 Fiend from hand, field or GY
function s.cfilter(c)
	return c:IsRace(RACE_FIEND) and c:IsAbleToRemoveAsCost()
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

--Target for negation
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

--Negate, destroy, special summon and damage
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	
	--Negate the activation
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		--Destroy it
		if Duel.Destroy(rc,REASON_EFFECT)~=0 and rc:IsMonster() then
			--Check if can be special summoned
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and rc:IsLocation(LOCATION_GRAVE)
				and rc:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
				
				--Special summon the destroyed monster
				if Duel.SpecialSummon(rc,0,tp,tp,false,false,POS_FACEUP)~=0 then
					--Inflict damage equal to original ATK
					local atk=rc:GetBaseAttack()
					if atk>0 then
						Duel.Damage(1-tp,atk,REASON_EFFECT)
					end
				end
			end
		end
	end
end

--ATK gain from battle damage
function s.atkcon1(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
end

--ATK gain from effect damage
function s.atkcon2(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp and r&REASON_EFFECT~=0
end

--Gain ATK equal to damage
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		--Gain ATK equal to damage
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
		e1:SetValue(ev)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end