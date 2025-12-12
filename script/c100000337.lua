--Eclipse Spectral Dragon
--Setcode 0x04B2
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon when controlling DARK/LIGHT Dragon Eclipse monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	--Grant protection when used as Synchro material
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.matcon)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end
s.listed_series={0x04B2}

--Check for level 4+ DARK/LIGHT Dragon Eclipse monster
function s.cfilter(c)
	return c:IsFaceup() and c:IsLevelAbove(4) and c:IsSetCard(0x04B2) and c:IsRace(RACE_DRAGON) 
		and (c:IsAttribute(ATTRIBUTE_DARK) or c:IsAttribute(ATTRIBUTE_LIGHT))
end

--Special Summon condition
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

--Special Summon operation and level modification if needed
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	
	-- Get the Eclipse Dragon monster that met the condition
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end
	
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- Make the condition monster Level 7, and this card Level 1 for Synchro
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
			local tc=g:Select(tp,1,1,nil):GetFirst()
			if tc then
				-- Make the target monster Level 7
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CHANGE_LEVEL)
				e1:SetValue(7)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				
				-- Make this card Level 1 for Synchro
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_SYNCHRO_LEVEL)
				e2:SetValue(1)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e2)
				
				-- Visual indicators
				local e3=Effect.CreateEffect(c)
				e3:SetDescription(aux.Stringid(id,2))
				e3:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e3)
				
				local e4=Effect.CreateEffect(c)
				e4:SetDescription(aux.Stringid(id,4))
				e4:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e4:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e4)
			end
		end
	end
end

--Check if used as Synchro material for DARK/LIGHT Dragon
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	return r==REASON_SYNCHRO and rc:IsRace(RACE_DRAGON) 
		and (rc:IsAttribute(ATTRIBUTE_DARK) or rc:IsAttribute(ATTRIBUTE_LIGHT))
		and Duel.GetFlagEffect(e:GetHandlerPlayer(),id)==0
end

--Grant indestructible effect
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	
	-- Create the "once per turn" indestructible effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetCountLimit(1)
	e1:SetValue(s.valcon)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1)
	
	-- Visual indicator for the protection effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3))
	e2:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e2)
	
	-- Register the flag effect to prevent multiple applications
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end

-- Value function for indestructible effect, 1 = cannot be destroyed, 0 = can be destroyed
function s.valcon(e,re,r,rp)
	return (r&REASON_BATTLE+REASON_EFFECT)~=0
end