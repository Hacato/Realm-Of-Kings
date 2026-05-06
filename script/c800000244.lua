--Hungry Donut
local s,id=GetID()
local SET_HUNGRY=0x2816
local CARD_HAMBURGER_RECIPE=80811661
local CARD_HUNGRY_COUPON=800000241

function s.initial_effect(c)
	--Reveal Recipe/Coupon, mill 4, then recover 1 "Hungry" Spell/Trap
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
end

s.listed_names={CARD_HAMBURGER_RECIPE,CARD_HUNGRY_COUPON}
s.listed_series={SET_HUNGRY}

function s.costfilter(c)
	return c:IsCode(CARD_HAMBURGER_RECIPE,CARD_HUNGRY_COUPON) and not c:IsPublic()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDiscardDeck(tp,4)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,4,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.millcheck(c)
	return c:IsSetCard(SET_HUNGRY) and c:IsPreviousLocation(LOCATION_DECK)
end

function s.thfilter(c)
	return c:IsSetCard(SET_HUNGRY)
		and c:IsSpellTrap()
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetDecktopGroup(tp,4)
	if #g==0 then return end
	local ct=Duel.SendtoGrave(g,REASON_EFFECT)
	if ct>0 then
		local og=Duel.GetOperatedGroup()
		if og:IsExists(s.millcheck,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end