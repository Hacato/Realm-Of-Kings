--The Beckoning of Doom
--Script by Assistant
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as "Slayer" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x2407)
	c:RegisterEffect(e0)
	
	--Fusion or Xyz Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.fusfilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_FIEND) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.xyzfilter(c,e,tp)
	return c:IsType(TYPE_XYZ) and c:IsRace(RACE_FIEND)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.matfilter(c)
	return c:IsCanBeFusionMaterial() and c:IsCanBeXyzMaterial()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,LOCATION_MZONE,nil)
		
		local res1=false
		local res2=false
		
		-- Check for Fusion monsters
		local fusionmonsters=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		for fc in aux.Next(fusionmonsters) do
			if fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
				and fc:CheckFusionMaterial(mg,nil,chkf) then
				res1=true
				break
			end
		end
		
		-- Check for Xyz monsters
		local xyzmonsters=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		for xc in aux.Next(xyzmonsters) do
			if Duel.GetLocationCountFromEx(tp,tp,nil,xc)>0 
				and xc:IsXyzSummonable(nil,mg,2,99) then
				res2=true
				break
			end
		end
		
		return res1 or res2
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,LOCATION_MZONE,nil)
	
	local sg=Group.CreateGroup()
	
	-- Add available Fusion monsters
	local fusionmonsters=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
	for fc in aux.Next(fusionmonsters) do
		if fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
			and fc:CheckFusionMaterial(mg,nil,chkf) then
			sg:AddCard(fc)
		end
	end
	
	-- Add available Xyz monsters
	local xyzmonsters=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
	for xc in aux.Next(xyzmonsters) do
		if Duel.GetLocationCountFromEx(tp,tp,nil,xc)>0 
			and xc:IsXyzSummonable(nil,mg,2,99) then
			sg:AddCard(xc)
		end
	end
	
	if #sg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		
		if tc:IsType(TYPE_FUSION) then
			local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_FUSION+REASON_MATERIAL)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		elseif tc:IsType(TYPE_XYZ) then
			if tc:IsXyzSummonable(nil,mg,2,99) then
				Duel.XyzSummon(tp,tc,nil,mg,2,99)
			end
		end
	end
end