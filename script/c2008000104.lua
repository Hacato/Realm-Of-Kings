--Terminal Nexus Gates
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--search
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
function s.filter(c)
	return c:IsMonster() and c:IsLevelBelow(10) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		local tc=g:GetFirst()
		if tc:IsLocation(LOCATION_HAND) then
			Duel.SetLP(tp,math.ceil(Duel.GetLP(tp)/2))
			local c=e:GetHandler()
			--Check Summon for matching name
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_SUMMON_SUCCESS)
			e1:SetLabel(tc:GetCode())
			e1:SetOperation(s.checkop)
			e1:SetReset(RESET_PHASE+PHASE_END,2)
			Duel.RegisterEffect(e1,tp)
			local e2=e1:Clone()
			e1:SetCode(EVENT_SPSUMMON_SUCCESS)
			Duel.RegisterEffect(e2,tp)
			local e3=e1:Clone()
			e3:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
			Duel.RegisterEffect(e3,tp)
--			--Cannot act effs of ms with the same name
--			local e4=Effect.CreateEffect(c)
--			e4:SetType(EFFECT_TYPE_FIELD)
--			e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
--			e4:SetCode(EFFECT_CANNOT_ACTIVATE)
--			e4:SetTargetRange(1,0)
--			e4:SetValue(s.aclimit)
--			e4:SetLabelObject(e1)
--			e4:SetReset(RESET_PHASE+PHASE_END,2)
--			Duel.RegisterEffect(e4,tp)
		end
	end
end
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local sc=eg:GetFirst()
	if sc:IsSummonPlayer(1-tp) then return end
	if sc:IsCode(e:GetLabel()) then e:SetLabel(-1) end
end
--function s.aclimit(e,re,tp)
--	return not re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:GetHandler():IsCode(e:GetLabelObject():GetLabel())
--end

--NOTE: It currently locks only on Normal Summoned monsters, other summons don't let the monster activate its effects
--NOTE: Missing the no further damage part