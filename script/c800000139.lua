-- SZS Kadingir
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	
	-- Enable Phonic Counter
	c:EnableCounterPermit(0x1996)
	
	-- Only 1 "SZS Kadingir" can be controlled
	c:SetUniqueOnField(1,0,id)
	
	-- Place 1 Phonic Counter when you Special Summon a "SZS" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCondition(s.ctcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)
	
	-- Once per turn, during each End Phase: Remove all counters and inflict damage
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
	
	-- If destroyed: Shuffle 1 "SZS" monster from GY to Deck, then draw 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

s.listed_series={0x2406}
s.counter_place_list={0x1996}

-- Counter placement filter
function s.ctfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x2406) and c:IsSummonPlayer(tp)
end

function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(s.ctfilter,nil,tp)
	if ct>0 then
		e:GetHandler():AddCounter(0x1996 ,ct)
	end
end

-- Damage target
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ct=e:GetHandler():GetCounter(0x1996)
	Duel.SetTargetPlayer(1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*500)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	local ct=c:GetCounter(0x1996)
	if ct==0 then return end
	if c:RemoveCounter(tp,0x1996,ct,REASON_EFFECT) then
		local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
		Duel.Damage(p,ct*500,REASON_EFFECT)
	end
end

-- Draw effect condition
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD) 
		and e:GetHandler():IsPreviousPosition(POS_FACEUP)
end

function s.drfilter(c)
	return c:IsSetCard(0x2406) and c:IsMonster() and c:IsAbleToDeck()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.drfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.drfilter,tp,LOCATION_GRAVE,0,1,nil) 
		and Duel.IsPlayerCanDraw(tp,1) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.drfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 
			and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
			Duel.ShuffleDeck(tp)
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end