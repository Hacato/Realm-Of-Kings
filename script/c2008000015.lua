--Number C75: Misleading Criminal Shade
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,4,3,nil,nil,99)
	c:EnableReviveLimit()
	--Sp Summ from Ex D
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCountLimit(1,{id,0},EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--xyz sum 1 R3 xyz m by using this c
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_DUEL)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--act added "R-U-M Quick Chaos" from h during your opp's turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e3:SetRange(LOCATION_GRAVE+LOCATION_REMOVED)
	e3:SetTargetRange(LOCATION_HAND,0)
	e3:SetTarget(s.acttg)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4))
	e4:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e4:SetCondition(function(e) return e:GetHandler():IsSetCard(0x48) end)
	e4:SetTargetRange(LOCATION_HAND,0)
	e4:SetTarget(s.acttg)
	c:RegisterEffect(e4)
end
s.listed_names={id,33252803,71166481}
s.listed_series={0x48,0x95}
s.xyz_number=75
function s.filter(c)--rm 1 "R-U-M" Q-P S from your h/D to Xyz Summ this c from your Ex D
	return c:IsSetCard(0x95) and c:GetType()==TYPE_QUICKPLAY+TYPE_SPELL and c:IsAbleToRemoveAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.cfilter(c,e,tp,xyz)
	return c:IsCode(71166481) and c:IsFaceup()
		and c:IsCanBeXyzMaterial(xyz,tp)
end
function s.condition(e)
	return Duel.IsExistingMatchingCard(s.cfilter,e:GetOwnerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		local c=e:GetHandler()
		local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
		return #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,true,false)
	end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
	Duel.SetChainLimit(aux.FALSE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,true,false) then return end
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_MZONE,0,nil)
	local pg=aux.GetMustBeMaterialGroup(tp,g,tp,nil,nil,REASON_XYZ)
	if #g>0 and #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 then
		c:SetMaterial(g)
		Duel.Overlay(c,g)
		if Duel.SpecialSummon(c,SUMMON_TYPE_XYZ,tp,tp,true,false,POS_FACEUP) and Duel.GetFieldGroupCount(c:GetControler(),0,LOCATION_ONFIELD)==0 then
		c:CompleteProcedure()
		end
	end
end
function s.xyzfilter(c)--rm 1 "R-U-M" N S from your D/GY to Xyz Summ 1 R3 "Number" m
	return c:IsSetCard(0x95) and c:GetType()==TYPE_SPELL and c:IsAbleToRemoveAsCost()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.spfilter(c,e,tp,mc,pg)
	return c:IsType(TYPE_XYZ) and c:IsSetCard(0x48) and c:IsRank(3) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and mc:IsCanBeXyzMaterial(c,tp) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local c=e:GetHandler()
		local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
		return (#pg<=0 or (#pg==1 and pg:IsContains(c))) and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,e:GetHandler(),pg) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetChainLimit(aux.FALSE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
		if c:IsFaceup() and c:IsRelateToEffect(e) and c:IsControler(tp) and not c:IsImmuneToEffect(e) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c,pg)
			local sc=g:GetFirst()
			if sc then
				Duel.BreakEffect()
				local mg=c:GetOverlayGroup()
				if #mg~=0 then
					Duel.Overlay(sc,mg)
				end
				sc:SetMaterial(Group.FromCards(c))
				Duel.Overlay(sc,Group.FromCards(c))
				if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
					sc:CompleteProcedure()
					--then you can add 1 "R-U-M Quick Chaos" from your D to your h
					local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
					if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
					local sg=g:Select(tp,1,1,nil)
					Duel.BreakEffect()
					Duel.SendtoHand(sg,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,sg)
				end
			end
		end
	end
end
function s.thfilter(c)
	return c:IsCode(33252803) and c:IsAbleToHand()
end
function s.acttg(e,c)--act "R-U-M Quick Chaos" from h during your opp's turn
	return c:IsCode(33252803)
end