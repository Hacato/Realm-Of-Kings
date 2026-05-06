--Vending Machine
local s,id=GetID()
local CARD_HUNGRY_COLA=800000246

function s.initial_effect(c)
	--Ritual Summon "Hungry Cola"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop)
	c:RegisterEffect(e1)

	--When sent to GY: add 1 Level 6 Warrior monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	--Shuffle this card into the Deck; add 1 Ritual Spell or Ritual Monster from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(s.gycost)
	e3:SetTarget(s.gytg)
	e3:SetOperation(s.gyop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_HUNGRY_COLA}

function s.ritfilter(c,e,tp)
	return c:IsCode(CARD_HUNGRY_COLA)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.fieldmatfilter(c)
	return c:HasLevel() and c:IsReleasable()
end

function s.deckmatfilter(c)
	return c:HasLevel() and c:IsMonster() and c:IsAbleToGrave()
end

function s.getmatgroup(tp)
	local g=Duel.GetMatchingGroup(s.fieldmatfilter,tp,LOCATION_MZONE,0,nil)
	local dg=Duel.GetMatchingGroup(s.deckmatfilter,tp,LOCATION_DECK,0,nil)
	g:Merge(dg)
	return g
end

function s.exactcheck(g,lv,sum)
	if sum==lv then return true end
	if sum>lv or #g==0 then return false end
	local tc=g:GetFirst()
	while tc do
		local sg=g:Clone()
		sg:RemoveCard(tc)
		if s.exactcheck(sg,lv,sum+tc:GetLevel()) then return true end
		tc=g:GetNext()
	end
	return false
end

function s.canritual(tp,e)
	local rg=Duel.GetMatchingGroup(s.ritfilter,tp,LOCATION_HAND,0,nil,e,tp)
	if #rg==0 then return false end
	local mg=s.getmatgroup(tp)
	return #mg>0 and s.exactcheck(mg,6,0)
end

function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and s.canritual(tp,e)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.ritop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rg=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	local rc=rg:GetFirst()
	if not rc then return end

	local mg=s.getmatgroup(tp)
	if not s.exactcheck(mg,6,0) then return end

	local mat=Group.CreateGroup()
	local sum=0
	while sum<6 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local sg=mg:FilterSelect(tp,function(c,mat,sum)
			local lv=c:GetLevel()
			if sum+lv>6 then return false end
			local cg=mg:Clone()
			cg:RemoveCard(c)
			return s.exactcheck(cg,6,sum+lv)
		end,1,1,nil,mat,sum)
		local sc=sg:GetFirst()
		if not sc then return end
		mat:AddCard(sc)
		mg:RemoveCard(sc)
		sum=sum+sc:GetLevel()
	end

	local rel=mat:Filter(Card.IsLocation,nil,LOCATION_MZONE)
	local send=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)

	if #rel>0 then
		Duel.Release(rel,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	if #send>0 then
		Duel.SendtoGrave(send,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end

	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	rc:CompleteProcedure()
end

function s.thfilter(c)
	return c:IsLevel(6)
		and c:IsRace(RACE_WARRIOR)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
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

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToDeckAsCost()
			and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,c)
	end
	Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_COST)
end

function s.gyfilter(c)
	return c:IsAbleToHand()
		and ((c:IsMonster() and c:IsType(TYPE_RITUAL))
		or (c:IsSpell() and c:IsType(TYPE_RITUAL)))
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end