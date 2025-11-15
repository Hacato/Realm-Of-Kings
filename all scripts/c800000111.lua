--Constructor Sword Foreman
local s,id=GetID()
function s.initial_effect(c)
	--Activate: mill and add Constructor monster(s)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia
--Add filter: "Constructor" monster
function s.thfilter(c)
	return c:IsSetCard(0x1568) and c:IsMonster() and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Mill top card
	if Duel.DiscardDeck(tp,1,REASON_EFFECT)==0 then return end
	
	local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	local dg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	local g=nil
	
	if blisstopia and #dg>=2 then
		--Select up to 2 with different names
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		g=aux.SelectUnselectGroup(dg,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_ATOHAND)
	else
		--Select 1
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		g=dg:Select(tp,1,1,nil)
	end
	
	if g and #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end