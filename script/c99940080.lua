--NGNL Checkmate Declaration
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x994}

function s.pzfilter(c,e,tp)
	return c:IsSetCard(0x994) and c:IsFaceup() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_PZONE) and chkc:IsControler(tp) and s.pzfilter(chkc,e,tp) end
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,2)
		and Duel.IsExistingTarget(s.pzfilter,tp,LOCATION_PZONE,0,1,nil,e,tp)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.pzfilter,tp,LOCATION_PZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.placefilter(c)
	return c:IsSetCard(0x994) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Send top 2 cards of Deck to GY (this happens first, not as cost)
	if not Duel.IsPlayerCanDiscardDeck(tp,2) then return end
	local dg=Duel.GetDecktopGroup(tp,2)
	if Duel.SendtoGrave(dg,REASON_EFFECT)==0 then return end
	
	--Then target and Special Summon the card from Pendulum Zone
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	
	--And if you do, place up to 2 NGNL Pendulum Monsters in Pendulum Zone
	if not Duel.CheckPendulumZones(tp) then return end
	
	local g=Duel.GetMatchingGroup(s.placefilter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		local ct=2
		if Duel.GetFieldCard(tp,LOCATION_PZONE,0) then ct=ct-1 end
		if Duel.GetFieldCard(tp,LOCATION_PZONE,1) then ct=ct-1 end
		if ct>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
			local sg=g:Select(tp,1,math.min(ct,#g),nil)
			for sc in aux.Next(sg) do
				Duel.MoveToField(sc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			end
		end
	end
end