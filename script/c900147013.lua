--SZS - Igalima Kirika
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --spsummon
    Symphogear.EffectProcedure(c,id,nil,{
        category=CATEGORY_TOGRAVE,
        target=s.tgtg,
        operation=s.tgop,
    })
end
s.listed_series={SET_SZS}
function s.tgfilter(c)
	return c:IsSetCard(SET_SZS) and not c:IsCode(id) and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
Duel.LoadScript("szs-utility.lua")