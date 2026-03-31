--Scarlet Thirst
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--your opp loses LP & you gain LP
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
--	e2:SetCondition(s.thcond)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--Change race
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_REMOVED)
	e3:SetCountLimit(1)
	e3:SetCost(s.zcost)
	e3:SetTarget(s.ztg)
	e3:SetOperation(s.zop)
	c:RegisterEffect(e3)
--	aux.GlobalCheck(s,function()
--		local ge1=Effect.CreateEffect(c)
--		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
--		ge1:SetCode(CATEGORY_RECOVER)
--		ge1:SetOperation(s.checkop)
--		Duel.RegisterEffect(ge1,0)
--	end)
end
s.listed_names={id,69700783}
s.listed_series={SET_VAMPIRE}
--function s.checkop(e,tp,eg,ep,ev,re,r,rp)--If you gained LP this turn:
--	if (r&REASON_EFFECT)~=0 then
--		Duel.RegisterFlagEffect(ep,id,RESET_PHASE+PHASE_END,0,1)
--	end
--end
function s.filter(c)--rm 1 "Vampire" m from your D/f-up field; your opp loses 1000LP and you gain 1000LP
	return  c:IsSetCard(SET_VAMPIRE) and c:IsMonster() and c:IsAbleToRemoveAsCost()
		and (c:IsFaceup() or c:IsLocation(LOCATION_DECK))
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_ONFIELD,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLP(1-tp)>=1000 end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1000)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1000)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local lp1=Duel.GetLP(1-tp)
	if lp1>=1000 then
		Duel.SetLP(1-tp,lp1-1000)
	end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
end
--function s.thcond(e,tp,eg,ep,ev,re,r,rp)
--	return Duel.GetFlagEffect(tp,id)~=0
--end
function s.thfilter(c)--you can rm this c from your GY; add 1 "Vampire's Desire" from your D/GY to your h
	return c:IsCode(69700783) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.cfilter(c)--rm 1 "Vampire" m from your D/f-up field; your opp loses 1000LP and you gain 1000LP
	return  c:IsSetCard(SET_VAMPIRE) and c:IsMonster() and c:IsAbleToDeckOrExtraAsCost()
end
function s.zcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SendtoDeck(g,nil,2,REASON_COST)
end
function s.ztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local rc=Duel.AnnounceRace(tp,1,RACE_ZOMBIE)--ALL
	e:SetLabel(rc)
	--Operation info needed to handle the interaction with "Necrovalley"
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,0,0)
end
function s.zop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local race=e:GetLabel()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_RACE)
	e1:SetTargetRange(0,LOCATION_MZONE+LOCATION_GRAVE)
	e1:SetTarget(s.rctg)
	e1:SetValue(race)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	--id chk
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(4064256)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,1)
	e2:SetValue(s.val(race))
	c:RegisterEffect(e2)
end
function s.rctg(e,c)
	if c:GetFlagEffect(1)==0 then
		c:RegisterFlagEffect(1,0,0,0)
		local eff
		if c:IsLocation(LOCATION_MZONE) then
			eff={Duel.GetPlayerEffect(c:GetControler(),EFFECT_NECRO_VALLEY)}
		else
			eff={c:GetCardEffect(EFFECT_NECRO_VALLEY)}
		end
		c:ResetFlagEffect(1)
		for _,te in ipairs(eff) do
			local op=te:GetOperation()
			if not op or op(e,c) then return false end
		end
	end
	return true
end
function s.val(race)
	return  function(e,c,re,chk)
				if chk==0 then return true end
				return race
			end
end