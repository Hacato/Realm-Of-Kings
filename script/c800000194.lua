--Tatsugiri Feeding Zone
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	--(1) On activation: add 1 "Tatsugiri" monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.actg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--(2) While all monsters you control are WATER: choose opponent's attack targets
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_PATRICIAN_OF_DARKNESS)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.watercond)
	c:RegisterEffect(e2)

	--(3) Once per turn: equip a WATER Union from GY or Banished to a Tatsugiri you control
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_EQUIP)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.eqtg)
	e3:SetOperation(s.eqop)
	c:RegisterEffect(e3)
end

--────────────────────────────
-- (1) Search
--────────────────────────────
function s.tatfilter(c)
	return c:IsSetCard(0x24A2) and c:IsMonster() and c:IsAbleToHand()
end

function s.actg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tatfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.tatfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--────────────────────────────
-- (2) All WATER condition
--────────────────────────────
function s.watercond(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetHandlerPlayer()
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,p,LOCATION_MZONE,0,nil)
	if #mg==0 then return false end
	return mg:FilterCount(Card.IsAttribute,nil,ATTRIBUTE_WATER)==#mg
end

--────────────────────────────
-- (3) Equip WATER Union
--────────────────────────────
function s.tatmzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x24A2)
end

function s.uniongyfilter(c)
	return c:IsAttribute(ATTRIBUTE_WATER) and c:IsType(TYPE_UNION)
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.tatmzfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.tatmzfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.uniongyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.tatmzfilter,tp,LOCATION_MZONE,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.uniongyfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	local uc=g:GetFirst()
	if not uc then return end

	if Duel.MoveToField(uc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
		if Duel.Equip(tp,uc,tc,true) then

			--Equip limit (prevents destruction)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(function(e,c) return c==tc end)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			uc:RegisterEffect(e1)

		end
	end
end