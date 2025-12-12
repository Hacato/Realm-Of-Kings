--Cyber-Tech Alligator - Effect
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,s.tfilter,1,1,Synchro.NonTunerEx(Card.IsRace,RACE_MACHINE),1,99)
	c:EnableReviveLimit()
	-- gain atk
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(s.val)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)
	--shuffle and draw
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCountLimit(1)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
	--Negate monster effect or summon
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_SPSUMMON)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.discon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.distg)
	e5:SetOperation(s.disop)
	c:RegisterEffect(e5)
end
function s.tfilter(c,scard,sumtype,tp)
	return c:GetLevel()==5
end
function s.val(e,c)
	local ct=e:GetHandler():GetFlagEffectLabel(id)
	if not ct then return 0 end
	return ct
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsSummonType(SUMMON_TYPE_SYNCHRO) then
		local g=c:GetMaterial()
		local atk=0
		if #g>0 then
			for tc in g:Iter() do
				if tc:IsRace(RACE_MACHINE) then
					atk=atk+tc:GetBaseAttack()
				end
			end
		end
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,0,atk/2)
	end
end
function s.tdfilter(c)
	return c:IsRace(RACE_MACHINE) and c:GetLevel()==5 and c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.tdfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_REMOVED,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)~=0
		and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
		if tc:IsLocation(LOCATION_DECK) then Duel.ShuffleDeck(tc:GetControler()) end
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thcfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.thcfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.thcfilter(c)
	return c:IsRace(RACE_MACHINE) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost()
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentChain()==0 and eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=eg:Filter(Card.IsSummonPlayer,nil,1-tp)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(Card.IsSummonPlayer,nil,1-tp)
	Duel.NegateSummon(g)
	Duel.Destroy(g,REASON_EFFECT)
end