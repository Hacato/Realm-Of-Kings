-- Wyrm Excavator the Heavy Cavalry Draco [L]
local s,id=GetID()
s.MaximumSide="Left"

function s.initial_effect(c)
	---------------------------------------------------------------
	-- 1. Maximum Mode only: This card gains 400 ATK × hand size
	---------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.maxCon)
	e1:SetValue(s.val)
	c:RegisterEffect(e1)
	c:AddSideMaximumHandler(e1)

	---------------------------------------------------------------
	-- 2. Maximum Mode only: Discard 1 → Draw 1
	---------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.maxCon)
	e2:SetCost(s.discost)
	e2:SetTarget(s.drawtg)
	e2:SetOperation(s.drawop)
	c:RegisterEffect(e2)
	c:AddSideMaximumHandler(e2)

	---------------------------------------------------------------
	-- 3. Maximum Mode only: Your monsters gain 300 ATK
	---------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetCondition(s.maxCon)
	e3:SetValue(100)
	c:RegisterEffect(e3)
	c:AddSideMaximumHandler(e3)

	---------------------------------------------------------------
	-- 4. Maximum Mode only: Once per turn, your monsters cannot be destroyed by card effects
	---------------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetCondition(s.maxCon)
	e4:SetValue(s.indct)
	c:RegisterEffect(e4)
	c:AddSideMaximumHandler(e4)

	---------------------------------------------------------------
	-- 5. Graveyard effect: Banish self → Add Level 4 or lower Wyrm to hand
	---------------------------------------------------------------
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetCountLimit(1,id+1000)
	e5:SetCost(s.banishcost)
	e5:SetTarget(s.search_tg)
	e5:SetOperation(s.search_op)
	c:RegisterEffect(e5)
end

---------------------------------------------------------------
-- Maximum Mode check
---------------------------------------------------------------
function s.maxCon(e)
	local c=e:GetHandler()
	return c:IsMaximumMode() or c:IsMaximumModeSide()
end

---------------------------------------------------------------
-- ATK boost by hand size
---------------------------------------------------------------
function s.val(e,c)
	return Duel.GetFieldGroupCount(c:GetControler(),LOCATION_HAND,0)*400
end

---------------------------------------------------------------
-- Indestructible count for monsters
---------------------------------------------------------------
function s.indct(e,re,r,rp)
	if bit.band(r,REASON_EFFECT)~=0 then return 1 end
	return 0
end

---------------------------------------------------------------
-- Discard cost
---------------------------------------------------------------
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

---------------------------------------------------------------
-- Draw target & operation
---------------------------------------------------------------
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

---------------------------------------------------------------
-- Banish self cost
---------------------------------------------------------------
function s.banishcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

---------------------------------------------------------------
-- Search Level 4 or lower Wyrm
---------------------------------------------------------------
function s.search_filter(c)
	return c:IsRace(RACE_WYRM) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

function s.search_tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.search_filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.search_op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.search_filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
