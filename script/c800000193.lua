--Shiny Tatsugiri
local s,id=GetID()
function s.initial_effect(c)
	--(1) Quick Effect: equip from hand to Level 8+ Tatsugiri you control, negate opponent monsters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)
	
	--(2) Union procedure (Dondozo)
	aux.AddUnionProcedure(c,s.unfilter)
	
	--(3) Equipped monster cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	
	--(4) Sent to GY → place on bottom of deck, then draw 1
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

-- ────────────────────────────────────────────────────────────────
-- Effect (1): Quick Effect equip from hand
-- ────────────────────────────────────────────────────────────────
function s.eqfilter(c)
	-- Target must be a face-up Level 8+ "Tatsugiri" you control
	return c:IsFaceup()
		and c:IsSetCard(0x24A2)
		and c:IsLevelAbove(7)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.eqfilter(chkc)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) then return end
	if not tc or not tc:IsFaceup() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	-- Equip face-up
	if Duel.Equip(tp,c,tc,true) then
		-- Equip limit: stays on this target only
		local elim=Effect.CreateEffect(c)
		elim:SetType(EFFECT_TYPE_SINGLE)
		elim:SetCode(EFFECT_EQUIP_LIMIT)
		elim:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		elim:SetReset(RESET_EVENT+RESETS_STANDARD)
		elim:SetValue(function(ef,cc) return cc==tc end)
		c:RegisterEffect(elim)
		-- Count Tatsugiri equip cards on the target
		local g=tc:GetEquipGroup():Filter(Card.IsSetCard,nil,0x24A2)
		local ct=#g
		if ct==0 then return end
		-- Negate opponent's face-up monsters (up to ct)
		local og=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		if #og==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
		local sg=og:Select(tp,0,math.min(ct,#og),nil)
		for sc in aux.Next(sg) do
			local ed=Effect.CreateEffect(c)
			ed:SetType(EFFECT_TYPE_SINGLE)
			ed:SetCode(EFFECT_DISABLE)
			ed:SetReset(RESET_EVENT+RESETS_STANDARD)
			sc:RegisterEffect(ed)
			local ee=Effect.CreateEffect(c)
			ee:SetType(EFFECT_TYPE_SINGLE)
			ee:SetCode(EFFECT_DISABLE_EFFECT)
			ee:SetReset(RESET_EVENT+RESETS_STANDARD)
			sc:RegisterEffect(ee)
		end
	end
end

-- ────────────────────────────────────────────────────────────────
-- Effect (2): Union procedure (Dondozo)
-- ────────────────────────────────────────────────────────────────
function s.unfilter(c)
	return c:IsFaceup() and c:IsCode(800000189)
end

-- ────────────────────────────────────────────────────────────────
-- Effect (4): GY trigger — bottom of deck, draw 1
-- ────────────────────────────────────────────────────────────────
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SendtoDeck(c,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end