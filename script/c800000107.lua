--Constructor Princess Pylon
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon
	local params = {aux.FilterBoolFunction(Card.IsRace,RACE_WYRM),nil,s.fextra}
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e1:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e1)
end
s.listed_series={0x1569} --Blisstopia

--Extra materials from Deck if Blisstopia is present
function s.fextra(e,tp,mg)
	if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil) then
		return Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_DECK,0,nil)
	end
	return nil
end