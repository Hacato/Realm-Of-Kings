--The Sacred Stone of Renais
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={800000154}
s.listed_series={0x816}

--Ritual Monster: Eirika only
function s.ritfilter(c,e,tp)
	return c:IsCode(800000154)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

--Hand / Field materials (Tribute only)
function s.matfilter(c,e)
	return c:IsMonster()
		and c:HasLevel()
		and c:IsReleasableByEffect()
		and c~=e:GetHandler()
end

--GY materials (POJ only, banish only)
function s.gyfilter(c,e)
	return c:IsSetCard(0x816)
		and c:IsMonster()
		and c:HasLevel()
		and c:IsAbleToRemove()
		and c~=e:GetHandler()
end

--Check if activation is possible
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		--Must have Ritual Monster
		if not Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then 
			return false 
		end
		
		local field_full = Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		
		if field_full then
			--Field is full: must have at least 1 field monster AND enough total materials
			local field_mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil,e)
			if field_mg:GetCount()==0 then return false end
			
			--Check if any field monster + other materials can reach 6+
			local hand_mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND,0,nil,e)
			local gy_mg=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil,e)
			
			for fc in aux.Next(field_mg) do
				local remaining_needed = 6 - fc:GetLevel()
				if remaining_needed <= 0 then return true end --Single field monster is enough
				
				--Check if remaining materials can cover the rest
				local temp_group=Group.CreateGroup()
				temp_group:Merge(field_mg)
				temp_group:Merge(hand_mg)
				temp_group:Merge(gy_mg)
				temp_group:RemoveCard(fc)
				
				if temp_group:GetCount()>0
					and temp_group:CheckWithSumGreater(Card.GetLevel,remaining_needed) then
					return true
				end
			end
			return false
		else
			--Field not full: standard check
			local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil,e)
			local gy=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil,e)
			mg:Merge(gy)
			return mg:CheckWithSumGreater(Card.GetLevel,6)
		end
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Select Ritual Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
	if not rc then return end
	
	local field_full = Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
	local mat=Group.CreateGroup()
	
	if field_full then
		--TWO-STEP SELECTION: Field is full
		--STEP 1: Force selection of exactly 1 FIELD monster
		local field_mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil,e)
		field_mg:RemoveCard(rc)
		
		if field_mg:GetCount()==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local field_mat=field_mg:Select(tp,1,1,nil)
		mat:Merge(field_mat)
		
		local first_level=field_mat:GetFirst():GetLevel()
		local remaining_needed=6-first_level
		
		--STEP 2: Select remaining materials if needed
		if remaining_needed>0 then
			local hand_mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND,0,nil,e)
			local remaining_field=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil,e)
			local gy_mg=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil,e)
			
			remaining_field:Sub(field_mat) --Remove already selected field monster
			remaining_field:RemoveCard(rc)
			hand_mg:RemoveCard(rc)
			gy_mg:RemoveCard(rc)
			
			local rest_mg=Group.CreateGroup()
			rest_mg:Merge(hand_mg)
			rest_mg:Merge(remaining_field)
			rest_mg:Merge(gy_mg)
			
			if rest_mg:GetCount()==0 or not rest_mg:CheckWithSumGreater(Card.GetLevel,remaining_needed) then
				return
			end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
			local rest_mat=rest_mg:SelectWithSumGreater(tp,Card.GetLevel,remaining_needed)
			if not rest_mat or rest_mat:GetCount()==0 then return end
			mat:Merge(rest_mat)
		end
		
	else
		--SINGLE-STEP SELECTION: Field not full (standard ritual)
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil,e)
		local gy=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil,e)
		mg:Merge(gy)
		mg:RemoveCard(rc)
		
		if mg:GetCount()==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		mat=mg:SelectWithSumGreater(tp,Card.GetLevel,6)
	end
	
	--Validate selection
	if not mat or mat:GetCount()==0 then return end
	if mat:GetSum(Card.GetLevel)<6 then return end
	
	--Split materials by location BEFORE paying cost
	local release_group=mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
	local banish_group=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	
	--Pay costs in correct manner
	if release_group:GetCount()>0 then
		Duel.Release(release_group,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	if banish_group:GetCount()>0 then
		Duel.Remove(banish_group,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	
	--Ritual Summon
	Duel.BreakEffect()
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	rc:CompleteProcedure()
end