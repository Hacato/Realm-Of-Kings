--Metarion Fusion
local s,id=GetID()
local SET_IMAGINARY_ARC=0x79b

function s.initial_effect(c)
	--Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(Fusion.SummonEffTG(s.fusfilter,s.matfilter,s.fextra))
	e1:SetOperation(Fusion.SummonEffOP(s.fusfilter,s.matfilter,s.fextra))
	c:RegisterEffect(e1)

	--GY effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_IMAGINARY_ARC}

function s.fusfilter(c,tp)
	return c:IsRace(RACE_MACHINE)
end

function s.matfilter(c,e,tp)
	return c:IsMonster() and c:IsAbleToGrave()
end

function s.arcfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_IMAGINARY_ARC)
end

--This returns extra materials AND the material legality check
function s.fextra(e,tp,mg)
	local chk=s.fcheck
	if Duel.IsExistingMatchingCard(s.arcfilter,tp,LOCATION_MZONE,0,1,nil) then
		local eg=Duel.GetMatchingGroup(s.matfilter,tp,0,LOCATION_MZONE,nil,e,tp)
		return eg,chk
	end
	return Group.CreateGroup(),chk
end

--All Fusion Materials must have different monster Types/Races
function s.fcheck(tp,sg,fc)
	local races={}
	for tc in aux.Next(sg) do
		local race=tc:GetRace()
		if races[race] then
			return false
		end
		races[race]=true
	end
	return true
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetTurnID()~=Duel.GetTurnCount()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.thfilter(c)
	return c:IsSetCard(SET_IMAGINARY_ARC) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.thfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end