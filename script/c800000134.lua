--SZS S.O.N.G. Commander Genjuro
local s,id=GetID()
function s.initial_effect(c)
	--Excavate and add/Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.exccon)
	e1:SetTarget(s.exctg)
	e1:SetOperation(s.excop)
	c:RegisterEffect(e1)
	--Return to hand when you Special Summon "SZS"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--Register Summon
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e4)
end
s.listed_series={0x2406}

--Register summon
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

--E1: Excavate and add/Special Summon
function s.exccon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.excfilter(c,e,tp)
	return c:IsSetCard(0x2406) and c:IsMonster() and not c:IsCode(id)
		and (c:IsAbleToHand() or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.excop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<5 then return end
	Duel.ConfirmDecktop(tp,5)
	local g=Duel.GetDecktopGroup(tp,5)
	local sg=g:Filter(s.excfilter,nil,e,tp)
	if #sg>0 then
		local cansp=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		local spg=sg:Filter(Card.IsCanBeSpecialSummoned,nil,e,0,tp,false,false)
		
		if cansp and #spg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			--Special Summon option
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local ct=math.min(2,Duel.GetLocationCount(tp,LOCATION_MZONE),#spg)
			local ssg=Group.CreateGroup()
			for i=1,ct do
				local tc=spg:Select(tp,1,1,nil):GetFirst()
				if tc then
					ssg:AddCard(tc)
					spg:RemoveCard(tc)
					if i<ct and #spg>0 and not Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
						break
					end
				end
			end
			if #ssg>0 then
				Duel.DisableShuffleCheck()
				Duel.SpecialSummon(ssg,0,tp,tp,false,false,POS_FACEUP)
				sg:Sub(ssg)
			end
		else
			--Add to hand option
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local ct=math.min(2,#sg)
			local thg=Group.CreateGroup()
			for i=1,ct do
				local tc=sg:Filter(Card.IsAbleToHand,thg):Select(tp,1,1,nil):GetFirst()
				if tc then
					thg:AddCard(tc)
					if i<ct and #sg:Filter(Card.IsAbleToHand,thg)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
						--continue
					else
						break
					end
				end
			end
			if #thg>0 then
				Duel.DisableShuffleCheck()
				Duel.SendtoHand(thg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,thg)
				sg:Sub(thg)
			end
		end
	end
	--Shuffle rest back
	Duel.ShuffleDeck(tp)
end

--E2: Return to hand when you Special Summon "SZS"
function s.thfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x2406) and c:IsControler(tp)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.thfilter,1,e:GetHandler(),tp)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoHand(c,nil,REASON_EFFECT)>0 and c:IsLocation(LOCATION_HAND) then
		if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end