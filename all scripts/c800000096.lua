--Overlord Supreme Adoration
local s,id=GetID()
function s.initial_effect(c)
	--Add "Overlord" monster(s) based on LP difference
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={99920010} --Overlord Ainz Ooal Gown, The Sorcerer King
s.listed_series={0x992} --Overlord

function s.thfilter(c)
	return c:IsSetCard(0x992) and c:IsMonster() and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local diff=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
	local ct=math.floor(diff/2000)
	if ct>2 then ct=2 end
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,ct,tp,LOCATION_DECK)
	--Store if Ainz was on field
	e:SetLabel(Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,99920010) and 1 or 0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local diff=math.abs(Duel.GetLP(tp)-Duel.GetLP(1-tp))
	local ct=math.floor(diff/2000)
	if ct>2 then ct=2 end
	if ct<1 then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,ct,ct,nil)
		if #sg>0 and Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,sg)
			--Reduce LP cost if Ainz was on field when activated
			if e:GetLabel()==1 then
				--LP cost reduction for Overlord monster self-summon effects
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetCode(EFFECT_LPCOST_CHANGE)
				e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
				e1:SetTargetRange(1,0)
				e1:SetValue(s.costchange)
				e1:SetReset(RESET_PHASE+PHASE_END)
				Duel.RegisterEffect(e1,tp)
			end
		end
	end
end

function s.costchange(e,re,rp,val)
	--Check if the effect is from an Overlord monster's self-summon effect
	if re and re:GetHandler():IsSetCard(0x992) and re:GetHandler():IsMonster() then
		return math.max(val-1000,0)
	end
	return val
end