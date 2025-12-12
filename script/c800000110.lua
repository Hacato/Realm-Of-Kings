--Constructor Art - Buildestruction
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x1569} --Blisstopia
--Activation target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=s.fuscheck(e,tp)
	local b2=s.exccheck(e,tp)
	if chk==0 then return b1 or b2 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)},
		{b2,aux.Stringid(id,2)})
	e:SetLabel(op)
	if op==1 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	elseif op==2 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end
--Activation operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		--Fusion Summon
		s.fusop(e,tp,eg,ep,ev,re,r,rp)
	elseif op==2 then
		--Excavate
		s.excop(e,tp,eg,ep,ev,re,r,rp)
	end
end
--Effect 1: Fusion Summon
function s.matfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_WYRM) and c:CheckFusionMaterial(mg)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end
function s.fuscheck(e,tp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
end
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
	local tc=sg:GetFirst()
	if tc then
		local mat=Duel.SelectFusionMaterial(tp,tc,mg)
		if #mat>0 then
			tc:SetMaterial(mat)
			Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
		end
	end
end
--Effect 2: Excavate
function s.excfilter(c)
	return c:IsSetCard(0x1569) and c:IsType(TYPE_FIELD) and c:IsAbleToHand()
end
function s.exccheck(e,tp)
	return Duel.IsPlayerCanDiscardDeck(tp,5)
end
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerCanDiscardDeck(tp,5) then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	local cg=g:Filter(s.excfilter,nil)
	
	if #cg>0 then
		--Let player select which Blisstopia Field Spell to add
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local tc=cg:Select(tp,1,1,nil):GetFirst()
		
		Duel.DisableShuffleCheck()
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
		g:RemoveCard(tc)
	end
	
	--Place rest on bottom of Deck
	if #g>0 then
		Duel.DisableShuffleCheck()
		Duel.MoveToDeckBottom(#g,tp)
		if #g>1 then
			Duel.SortDeckbottom(tp,tp,#g)
		end
	end
end