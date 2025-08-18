--Eclipse Red Scale Magician
--ID: You can replace this with your desired ID
local s,id=GetID()
local SETCODE_ECLIPSE=0x04B2

function s.initial_effect(c)
	--Pendulum attributes
	Pendulum.AddProcedure(c)
	
	--Can only Pendulum Summon DARK monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetTargetRange(1,0)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	
	--Change Pendulum Scale to 4 if no card in other Pendulum Zone
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CHANGE_LSCALE)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCondition(s.sccon)
	e2:SetValue(4)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EFFECT_CHANGE_RSCALE)
	c:RegisterEffect(e2b)
	
	--Reduce battle damage to 0
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.damcon)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
	
	--Special Summon when "Eclipse" monster leaves the field by opponent's effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_HAND)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e5)
	local e6=e4:Clone()
	e6:SetCode(EVENT_TO_HAND)
	c:RegisterEffect(e6)
	local e7=e4:Clone()
	e7:SetCode(EVENT_TO_DECK)
	c:RegisterEffect(e7)
end

--Cannot Pendulum Summon non-DARK monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsAttribute(ATTRIBUTE_DARK) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Check if there's no card in the other Pendulum Zone
function s.sccon(e)
	local tp=e:GetHandlerPlayer()
	return not Duel.GetFieldCard(tp,LOCATION_PZONE,1-e:GetHandler():GetSequence())
end

--Damage reduction condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	--Check if battle damage will be taken involving a DARK monster
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	
	local p=e:GetHandlerPlayer()
	local tc=Duel.GetFieldCard(p,LOCATION_PZONE,1-e:GetHandler():GetSequence())
	
	if not tc or not tc:IsSetCard(SETCODE_ECLIPSE) then return false end
	
	-- Handle direct attacks
	if a and not d then
		return a:IsControler(1-p) and Duel.GetBattleDamage(p)>0
	end
	
	-- Handle battles between monsters
	if a and d then
		if (a:IsControler(p) and a:IsAttribute(ATTRIBUTE_DARK)) or (d:IsControler(p) and d:IsAttribute(ATTRIBUTE_DARK)) then
			return Duel.GetBattleDamage(p)>0
		end
	end
	
	return false
end

--Damage reduction operation
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_DAMAGE)
	Duel.RegisterEffect(e1,tp)
end

--Check if "Eclipse" monster left the field by opponent's effect
function s.cfilter(c,tp)
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousControler(tp)
		and c:IsSetCard(SETCODE_ECLIPSE) and c:IsType(TYPE_MONSTER)
		and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

--Filter for face-up "Eclipse" Pendulum Monster in Extra Deck
function s.pendfilter(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(SETCODE_ECLIPSE) and c:IsType(TYPE_PENDULUM)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Target for Special Summon - MODIFIED TO ONLY REQUIRE CARD TO BE SUMMONABLE
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	
	-- Only set operation info for the second summon if there's a valid target
	if Duel.IsExistingMatchingCard(s.pendfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	end
end

--Special Summon operation - MODIFIED TO MAKE SECOND SUMMON OPTIONAL
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)~=0 then
		-- Check if there's space for another monster and if there are valid targets
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		
		-- Check if there are any valid "Eclipse" Pendulum Monsters to summon
		if Duel.IsExistingMatchingCard(s.pendfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.pendfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
			if #g>0 then
				Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end