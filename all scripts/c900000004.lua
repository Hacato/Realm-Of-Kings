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

function s.filter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION+TYPE_XYZ) and c:IsRace(RACE_FIEND) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION+SUMMON_TYPE_XYZ,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end

function s.xyzfilter(c,e,tp,mg)
	return c:IsType(TYPE_XYZ) and c:IsRace(RACE_FIEND) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsXyzSummonable(nil,mg,2,99)
end

function s.fusfilter(c,e,tp,mg,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_FIEND) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) 
		and c:CheckFusionMaterial(mg,nil,chkf)
end

function s.matfilter(c)
	return c:IsCanBeFusionMaterial() or c:IsCanBeXyzMaterial()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(s.matfilter,nil)
		local mg2=Duel.GetMatchingGroup(s.matfilter,tp,0,LOCATION_MZONE,nil)
		local mg3=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND,0,nil)
		mg1:Merge(mg2)
		mg1:Merge(mg3)
		
		local res1=Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
		local res2=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1)
		return res1 or res2
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(s.matfilter,nil)
	local mg2=Duel.GetMatchingGroup(s.matfilter,tp,0,LOCATION_MZONE,nil)
	local mg3=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND,0,nil)
	mg1:Merge(mg2)
	mg1:Merge(mg3)
	
	local sg1=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local sg2=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1)
	sg1:Merge(sg2)
	
	if #sg1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg1:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		if tc:IsType(TYPE_FUSION) then
			local mat=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_FUSION+REASON_MATERIAL)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		else
			local mat=tc:GetOverlayGroup()
			if #mat==0 then
				mat=Duel.SelectXyzMaterial(tp,tc,mg1)
			end
			if #mat>0 then
				tc:SetMaterial(mat)
				Duel.Overlay(tc,mat)
				Duel.SpecialSummon(tc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
	end
end