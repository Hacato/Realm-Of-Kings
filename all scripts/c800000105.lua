--Constructor Engineer Draftannium
local s,id=GetID()
function s.initial_effect(c)
	--Excavate on Normal Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.exctg)
	e1:SetOperation(s.excop)
	c:RegisterEffect(e1)
end
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia

--Excavate target
function s.excfilter(c,e,tp,blisstopia)
	if not (c:IsSetCard(0x1568) and c:IsMonster()) then return false end
	return c:IsAbleToHand() or (blisstopia and c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,3) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
--Excavate operation
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerCanDiscardDeck(tp,3) then return end
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
	local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local cg=g:Filter(s.excfilter,nil,e,tp,blisstopia and ft>0)
	
	if #cg>0 then
		--Let player select which Constructor monster to use
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
		local tc=cg:Select(tp,1,1,nil):GetFirst()
		
		local b1=tc:IsAbleToHand()
		local b2=blisstopia and ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		local op=0
		
		if b1 and b2 then
			--Both options available
			op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
		elseif b1 then
			--Only add to hand
			op=Duel.SelectOption(tp,aux.Stringid(id,1))
		elseif b2 then
			--Only Special Summon
			op=Duel.SelectOption(tp,aux.Stringid(id,2))
			op=1
		end
		
		Duel.DisableShuffleCheck()
		if op==0 then
			--Add to hand
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
			g:RemoveCard(tc)
		else
			--Special Summon
			if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
				g:RemoveCard(tc)
			end
		end
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