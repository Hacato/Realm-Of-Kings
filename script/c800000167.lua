--Pursuer of Justice - Lute the Prodigy (ALL FOUR STONES TEST)
local s,id=GetID()
function s.initial_effect(c)
	--Cannot Special Summon monsters except "Pursuer of Justice" monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	--TEST: Banish this card and Sacred Stone to summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_names={800000157,800000154,800000163,800000161,800000164}
s.listed_series={0x816,0x5510}

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(0x816)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(1-tp)
end

function s.stonefilter(c)
	return c:IsSetCard(0x5510) and c:IsAbleToRemoveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		if not c:IsAbleToRemoveAsCost() then return false end
		-- Check if any valid Sacred Stone exists that would allow activation
		local g=Duel.GetMatchingGroup(s.stonefilter,tp,LOCATION_GRAVE,0,nil)
		for tc in aux.Next(g) do
			local code=tc:GetCode()
			if code==800000157 then
				-- Check Renais condition
				local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
				if Duel.IsExistingMatchingCard(s.eirikalfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
					and mg:CheckWithSumGreater(Card.GetLevel,6) then
					return true
				end
			elseif code==800000163 then
				-- Check Rausten condition
				local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.monsterfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
				if Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg) then
					return true
				end
			elseif code==800000161 then
				-- Check Jehanna condition - need at least one possible Synchro summon
				local sg=Duel.GetMatchingGroup(s.synfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
				if #sg==0 then return false end
				
				local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsAbleToRemove),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
				mg=mg:Filter(Card.IsLevelAbove,nil,1)
				
				-- Check each Synchro monster to see if a valid combination exists
				for sc in aux.Next(sg) do
					local lv=sc:GetLevel()
					local tuners=mg:Filter(Card.IsType,nil,TYPE_TUNER)
					-- Check each tuner
					for tuner in aux.Next(tuners) do
						local tlv=tuner:GetLevel()
						if tlv<lv then
							local remaining=lv-tlv
							local nontuners=mg:Filter(function(c) return c~=tuner and not c:IsType(TYPE_TUNER) end,nil)
							-- Check if non-tuners can sum to remaining level
							if nontuners:CheckWithSumEqual(Card.GetLevel,remaining,1,99) then
								return true
							end
						end
					end
				end
				return false
			end
		end
		return false
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.stonefilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local stone=g:GetFirst()
	g:AddCard(c)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	e:SetLabel(stone and stone:GetCode() or 0)
end

function s.eirikalfilter(c,e,tp)
	return c:IsCode(800000154) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.matfilter(c)
	return c:IsMonster() and c:HasLevel() and c:IsAbleToRemove()
end

function s.monsterfilter(c)
	return c:IsMonster() and c:IsAbleToRemove()
end

--Rausten filter
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x816)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end

--Jehanna filter
function s.synfilter(c,e,tp)
	return c:IsType(TYPE_SYNCHRO) and c:IsSetCard(0x816)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

--Frelia filter
function s.linkfilter(c,e,tp)
	return c:IsType(TYPE_LINK) and c:IsSetCard(0x816)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_LINK,tp,false,false)
end

-- Check if a Synchro monster has valid material combinations
function s.synchrocheck(c,mg)
	local lv=c:GetLevel()
	if lv==0 then return false end
	local tuners=mg:Filter(Card.IsType,nil,TYPE_TUNER)
	for tuner in aux.Next(tuners) do
		local tlv=tuner:GetLevel()
		if tlv>0 and tlv<lv then
			local remaining=lv-tlv
			local nontuners=mg:Filter(function(tc) return tc~=tuner and not tc:IsType(TYPE_TUNER) end,nil)
			if nontuners:CheckWithSumEqual(Card.GetLevel,remaining,1,99) then
				return true
			end
		end
	end
	return false
end

-- Check if a tuner is valid for the selected Synchro
function s.tunercheck(c,sc,mg,matreq)
	local lv=sc:GetLevel()
	local tlv=c:GetLevel()
	if tlv==0 or tlv>=lv then return false end
	local remaining=lv-tlv
	local nontuners=mg:Filter(function(tc) return tc~=c and not tc:IsType(TYPE_TUNER) end,nil)
	if matreq then
		nontuners=nontuners:Filter(matreq,nil,sc,false)
	end
	return nontuners:CheckWithSumEqual(Card.GetLevel,remaining,1,99)
end

-- Get custom material filter for specific Synchro monsters
-- Override this function to add requirements for your custom Synchros
function s.getsynchrofilter(c)
	-- Example: If your Synchro requires "monsters with different Types":
	-- You can check the card code and return appropriate filters
	-- For now, returns nil (no custom requirements)
	return nil
end

-- Get custom material filter for specific Link monsters
-- Override this function to add requirements for your custom Links
function s.getlinkfilter(c)
	-- Default: All "Pursuer of Justice" Link monsters require "Pursuer of Justice" materials
	if c and c:IsSetCard(0x816) then
		return function(mc,lc) return mc:IsSetCard(0x816) end
	end
	-- Add specific exceptions here if needed
	return nil
end

-- Check if a group has all different types (for "different Types" requirement)
function s.checkdifferenttypes(g)
	local types={}
	for tc in aux.Next(g) do
		local t=tc:GetRace()
		if types[t] then
			return false -- Duplicate type found
		end
		types[t]=true
	end
	return true
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local code=e:GetLabel()
	if code==800000157 then
		--Renais: Ritual Summon Eirika
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=Duel.SelectMatchingCard(tp,s.eirikalfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
		if not tc then return end
		
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		if #mg==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local mat=mg:SelectWithSumGreater(tp,Card.GetLevel,6)
		
		if #mat>0 then
			if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)==#mat then
				Duel.BreakEffect()
				if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
					tc:CompleteProcedure()
				end
			end
		end
	elseif code==800000163 then
		--Rausten: Fusion Summon
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.monsterfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		if #mg==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
		local tc=sg:GetFirst()
		if not tc then return end
		
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
		if #mat==0 then return end
		
		tc:SetMaterial(mat)
		if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)==#mat then
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
				tc:CompleteProcedure()
			end
		end
	elseif code==800000161 then
		--Jehanna: Synchro Summon with custom material validation support
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.monsterfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		mg=mg:Filter(Card.IsLevelAbove,nil,1)
		if #mg==0 then return end
		
		-- Get all Synchro monsters
		local sg=Duel.GetMatchingGroup(s.synfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		local validsyns=sg:Filter(s.synchrocheck,nil,mg)
		if #validsyns==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=validsyns:Select(tp,1,1,nil):GetFirst()
		if not tc then return end
		
		-- Get material requirement function if exists
		local matreq=s.getsynchrofilter(tc)
		
		-- Get all valid tuners
		local tuners=mg:Filter(Card.IsType,nil,TYPE_TUNER)
		if matreq then
			tuners=tuners:Filter(matreq,nil,tc,true) -- Filter tuners by custom requirements
		end
		local validtuners=tuners:Filter(s.tunercheck,nil,tc,mg,matreq)
		if #validtuners==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
		local tuner=validtuners:Select(tp,1,1,nil):GetFirst()
		if not tuner then return end
		
		local lv=tc:GetLevel()
		local tlv=tuner:GetLevel()
		local remaining=lv-tlv
		
		-- Get valid non-tuners
		local nontuners=mg:Filter(function(c) return c~=tuner and not c:IsType(TYPE_TUNER) end,nil)
		if matreq then
			nontuners=nontuners:Filter(matreq,nil,tc,false) -- Filter non-tuners by custom requirements
		end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local mats=nontuners:SelectWithSumEqual(tp,Card.GetLevel,remaining,1,99)
		if #mats==0 then return end
		
		-- Final validation for "different Types" requirement
		if matreq and s.checkdifferenttypes then
			local allmat=Group.FromCards(tuner)
			allmat:Merge(mats)
			if not s.checkdifferenttypes(allmat) then return end
		end
		
		local mat=Group.FromCards(tuner)
		mat:Merge(mats)
		
		tc:SetMaterial(mat)
		if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO)==#mat then
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
				tc:CompleteProcedure()
			end
		end
	elseif code==800000164 then
		--Frelia: Link Summon with custom material validation support
		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.monsterfilter),tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		if #mg==0 then return end
		
		-- Get all Link monsters
		local sg=Duel.GetMatchingGroup(s.linkfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		if #sg==0 then return end
		
		-- Get material requirement function if exists
		local linkreq=s.getlinkfilter(nil)
		
		-- Filter to only show Links that can be summoned with available materials
		local validlinks=Group.CreateGroup()
		for lc in aux.Next(sg) do
			local lkcount=lc:GetLink()
			local vmg=mg
			-- Apply custom filter if exists
			local customfilter=s.getlinkfilter(lc)
			if customfilter then
				vmg=mg:Filter(customfilter,nil,lc)
			end
			if #vmg>=lkcount then
				validlinks:AddCard(lc)
			end
		end
		if #validlinks==0 then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=validlinks:Select(tp,1,1,nil):GetFirst()
		if not tc then return end
		
		local lkcount=tc:GetLink()
		
		-- Apply custom filter to materials
		local matgroup=mg
		local customfilter=s.getlinkfilter(tc)
		if customfilter then
			matgroup=mg:Filter(customfilter,nil,tc)
		end
		
		if #matgroup<lkcount then return end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local mat=matgroup:Select(tp,lkcount,lkcount,nil)
		if #mat~=lkcount then return end
		
		tc:SetMaterial(mat)
		if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_LINK)==#mat then
			Duel.BreakEffect()
			if Duel.SpecialSummon(tc,SUMMON_TYPE_LINK,tp,tp,false,false,POS_FACEUP)>0 then
				tc:CompleteProcedure()
			end
		end
	end
end