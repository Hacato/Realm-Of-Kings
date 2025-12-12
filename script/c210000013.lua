--Magician's Misdirection
--Coded by HuascarD
local s,id,o=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,46986414)
	--search
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(210000013,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,210000013)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--draw 1
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(210000013,0))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_RELEASE)
	e2:SetCountLimit(1,210000014)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
end
s.listed_names={46986414}
function s.filter(c)
	return aux.IsCodeListed(c,46986414) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
		return g:GetClassCount(Card.GetCode)>=2
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
	if g:GetClassCount(Card.GetCode)>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg=g:SelectSubGroup(tp,aux.dncheck,false,2,2)
		Duel.ConfirmCards(1-tp,sg)
		local tg=sg:RandomSelect(1-tp,1)
		tg:GetFirst():SetStatus(STATUS_TO_HAND_WITHOUT_CONFIRM,true)
		Duel.SendtoHand(tg,nil,REASON_EFFECT)
		Duel.SendtoDeck(sg-tg,nil,SEQ_DECKTOP,REASON_EFFECT)
	end
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end