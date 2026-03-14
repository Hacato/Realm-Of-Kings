--SZS - Ameno Habakiri Tsubasa
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --spsummon
    Symphogear.EffectProcedure(c,id,nil,{
        category=CATEGORY_TOHAND+CATEGORY_SEARCH,
        target=s.thtg,
        operation=s.thop,
    })
end
s.listed_series={SET_SZS}
function s.thfilter(c)
	return c:IsSetCard(SET_SZS) and c:IsSpellTrap() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
Duel.LoadScript("szs-utility.lua")