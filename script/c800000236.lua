--Hamburger Fast Recipe
local s,id=GetID()
local SET_HUNGRY=0x2816
local CARD_HUNGRY_BURGER=30243636

function s.initial_effect(c)
	--Ritual Summon "Hungry Burger" or a "Hungry" Ritual Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--GY effect: banish this card; add 1 "Hungry" monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_names={CARD_HUNGRY_BURGER}
s.listed_series={SET_HUNGRY}

function s.ritfilter(c,e,tp)
	return (c:IsCode(CARD_HUNGRY_BURGER)
		or (c:IsSetCard(SET_HUNGRY) and c:IsType(TYPE_RITUAL)))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

function s.matfilter(c,tc)
	return c~=tc and c:IsReleasable()
end

function s.gyfilter(c)
	return c:IsSetCard(SET_HUNGRY)
		and c:IsMonster()
		and c:IsAbleToRemove()
		and c:HasLevel()
end

function s.checkmat(tp,tc)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil,tc)
	mg:Merge(Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil))
	return s.canreach(mg,6,0)
end

function s.canreach(g,lv,sum)
	if sum>=lv then return true end
	if #g==0 then return false end
	local tc=g:GetFirst()
	while tc do
		local sg=g:Clone()
		sg:RemoveCard(tc)
		if s.canreach(sg,lv,sum+tc:GetLevel()) then return true end
		tc=g:GetNext()
	end
	return false
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(function(c,e,tp)
			return s.ritfilter(c,e,tp) and s.checkmat(tp,c)
		end,tp,LOCATION_HAND,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rg=Duel.SelectMatchingCard(tp,function(c,e,tp)
		return s.ritfilter(c,e,tp) and s.checkmat(tp,c)
	end,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	local tc=rg:GetFirst()
	if not tc then return end

	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil,tc)
	mg:Merge(Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil))

	local mat=Group.CreateGroup()
	local sum=0
	while sum<6 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local sg=mg:Select(tp,1,1,nil)
		local sc=sg:GetFirst()
		if not sc then return end
		mat:AddCard(sc)
		mg:RemoveCard(sc)
		sum=sum+sc:GetLevel()
	end

	local rel=mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
	local rem=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)

	if #rel>0 then
		Duel.Release(rel,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	if #rem>0 then
		Duel.Remove(rem,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end

	if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end

function s.thfilter(c)
	return c:IsSetCard(SET_HUNGRY)
		and c:IsMonster()
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