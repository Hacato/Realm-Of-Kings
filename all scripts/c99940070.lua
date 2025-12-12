--NGNL Game Start
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x994}

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 
		and Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,PLAYER_ALL,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,0)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,PLAYER_ALL,LOCATION_DECK)
end

function s.pzonefilter(c)
	return c:IsSetCard(0x994) and c:IsFaceup()
end

function s.gamestart(tp)
	--Count cards in hand for both players
	local ct_p=Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	local ct_op=Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)
	
	if ct_p==0 or ct_op==0 then return false end
	
	--Shuffle both players' hands into Deck
	local g_p=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
	local g_op=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
	
	Duel.SendtoDeck(g_p,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.SendtoDeck(g_op,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	Duel.ShuffleDeck(tp)
	Duel.ShuffleDeck(1-tp)
	
	--Determine the number of cards to draw (minimum of both players' hand counts)
	local draw_count=math.min(ct_p,ct_op)
	
	--Both players draw
	Duel.Draw(tp,draw_count,REASON_EFFECT)
	Duel.Draw(1-tp,draw_count,REASON_EFFECT)
	
	--Send top card of each Deck to GY
	local dg=Duel.GetDecktopGroup(tp,1)
	dg:Merge(Duel.GetDecktopGroup(1-tp,1))
	if #dg>0 then
		Duel.SendtoGrave(dg,REASON_EFFECT)
	end
	
	return true
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--First iteration
	if not s.gamestart(tp) then return end
	
	--Check for NGNL cards in both Pendulum Zones
	local pz1=Duel.GetFieldCard(tp,LOCATION_PZONE,0)
	local pz2=Duel.GetFieldCard(tp,LOCATION_PZONE,1)
	
	if pz1 and pz2 and s.pzonefilter(pz1) and s.pzonefilter(pz2) then
		--Can repeat the effect once more
		if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			s.gamestart(tp)
		end
	end
end