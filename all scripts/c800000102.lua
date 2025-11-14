--Constructor Warrior Shovelon
local s,id=GetID()
function s.initial_effect(c)
	--Mill and add on summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
end
s.listed_names={id}
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia

--Add filter for "Blisstopia" cards
function s.blissfilter(c)
	return c:IsSetCard(0x1569) and c:IsAbleToHand()
end
--Add filter for "Constructor" cards
function s.confilter(c)
	return c:IsSetCard(0x1568) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
		return Duel.IsPlayerCanDiscardDeck(tp,1)
			and (Duel.IsExistingMatchingCard(s.blissfilter,tp,LOCATION_DECK,0,1,nil)
				or (blisstopia and Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_DECK,0,1,nil)))
	end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	--Mill top card
	if Duel.DiscardDeck(tp,1,REASON_EFFECT)==0 then return end
	local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	local b1=Duel.IsExistingMatchingCard(s.blissfilter,tp,LOCATION_DECK,0,1,nil)
	local b2=blisstopia and Duel.IsExistingMatchingCard(s.confilter,tp,LOCATION_DECK,0,1,nil)
	
	if not b1 and not b2 then return end
	
	local op=0
	if b1 and b2 then
		--Both options available
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		--Only Blisstopia available
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		--Only Constructor available
		op=Duel.SelectOption(tp,aux.Stringid(id,2))
		op=1
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=nil
	if op==0 then
		--Add "Blisstopia" card
		g=Duel.SelectMatchingCard(tp,s.blissfilter,tp,LOCATION_DECK,0,1,1,nil)
	else
		--Add "Constructor" card
		g=Duel.SelectMatchingCard(tp,s.confilter,tp,LOCATION_DECK,0,1,1,nil)
	end
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end