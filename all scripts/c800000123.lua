--Constructor Driver Trailon
local s,id=GetID()
function s.initial_effect(c)
	--Add Wyrm Excavator, then optionally add or SS a Wyrm from GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.con)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
s.listed_names={800000120}
function s.cfilter(c)
	return c:IsFaceup() and not (c:IsAttribute(ATTRIBUTE_EARTH) and c:IsRace(RACE_WYRM))
end
function s.con(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,e:GetHandler())
	return #g==0 or not g:IsExists(s.cfilter,1,nil)
end
function s.thfilter(c)
	return c:IsCode(800000120) and c:IsAbleToHand()
end
function s.gyfilter(c,e,tp)
	return c:IsRace(RACE_WYRM) and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.thfilter2(c)
	return c:IsRace(RACE_WYRM) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_WYRM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.lvfilter(c)
	return c:IsRace(RACE_WYRM) and c:IsLevelAbove(5)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	--Add Wyrm Excavator
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		--Check for Level 5+ Wyrm in GY
		if Duel.IsExistingMatchingCard(s.lvfilter,tp,LOCATION_GRAVE,0,1,nil) then
			local th=Duel.GetMatchingGroup(s.thfilter2,tp,LOCATION_GRAVE,0,nil)
			local sp=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
			local cth=#th>0
			local csp=#sp>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			if (cth or csp) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
				local op=0
				if cth and csp then
					op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
				elseif csp then
					op=1
				end
				if op==0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
					local tc=th:Select(tp,1,1,nil):GetFirst()
					Duel.SendtoHand(tc,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,tc)
				else
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local tc=sp:Select(tp,1,1,nil):GetFirst()
					Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_ATTACK)
				end
			end
		end
	end
end