--クイック フュージョン
--Quick Fusion
--Scripted by Lilac
local s,id=GetID()
function s.initial_effect(c)
	Fusion.ApplyAdditionalMaterials(id,2,s.amcon)
	local fe=Fusion.RegisterSummonEff(c)
	fe:SetHintTiming(TIMINGS_CHECK_MONSTER_E,0)
	fe:SetCondition(Duel.IsMainPhase)
end
function s.amcon(e,tp,mc,fc)
	local ct1=Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)
	local ct2=Duel.GetFieldGroupCount(1-tp,LOCATION_ONFIELD,0)
	if e:GetHandler():IsLocation(LOCATION_HAND) then ct1=ct1+1 end
	return ct1<ct2 and not Duel.HasFlagEffect(tp,id+EFFECT_FUSION_MATERIAL_COUNT)
end