--白の枢機竜
--Dogmatikalamity Alba System
--scripted by pyrQ, optimized to prevent lag
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials: "Fallen of Albaz" + 6 different monsters from your GY
	Fusion.AddProcMixN(c,true,true,CARD_ALBAZ,1,s.matfilter,6)
	Fusion.AddProcCheck(c,s.matcheck)
	c:AddMustFirstBeFusionSummoned()
	--This card can attack all monsters your opponent controls, once each
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--Cannot declare an attack unless you send 1 card from your Extra Deck to the GY
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_ATTACK_COST)
	e2:SetCost(function(e,c,tp) return Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,LOCATION_EXTRA,0,1,nil) end)
	e2:SetOperation(s.atkcostop)
	c:RegisterEffect(e2)
	--Send all cards in both players' Extra Decks to the GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.tgcon)
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)
end
s.listed_names={CARD_ALBAZ}

-- Fusion material filter (GY only, no uniqueness check here)
function s.matfilter(c,fc,sumtype,tp,sub,mg,sg)
	return c:IsLocation(LOCATION_GRAVE) and c:IsControler(tp)
end

-- Final uniqueness check: all 6 GY monsters must have different names
function s.matcheck(g,fc,sumtype,tp)
	return g:GetClassCount(Card.GetCode)==#g
end

-- Attack cost handler
function s.atkcostop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsAttackCostPaid()~=2 and e:GetHandler():IsLocation(LOCATION_MZONE) then
		local g=Duel.GetMatchingGroup(Card.IsAbleToGraveAsCost,tp,LOCATION_EXTRA,0,nil)
		local sg=aux.SelectUnselectGroup(g,e,tp,0,1,nil,1,tp,HINTMSG_TOGRAVE,function() return Duel.IsAttackCostPaid()==0 end,nil)
		if #sg==1 then
			Duel.SendtoGrave(sg,REASON_COST)
			Duel.AttackCostPaid()
		else
			Duel.AttackCostPaid(2)
		end
	end
end

-- Condition for Extra Deck nuke
function s.tgconfilter(c)
	return c:IsType(TYPE_FUSION) and c:ListsCodeAsMaterial(CARD_ALBAZ)
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsFusionSummoned() then return false end
	local g=Duel.GetMatchingGroup(s.tgconfilter,tp,LOCATION_GRAVE,0,nil)
	return g:GetClassCount(Card.GetCode)>=6
end

-- Target + operation
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetFieldGroup(tp,LOCATION_EXTRA,LOCATION_EXTRA)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,tp,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,LOCATION_EXTRA,LOCATION_EXTRA)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
