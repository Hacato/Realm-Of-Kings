--Mannadium Kashtira
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER|TIMING_MAIN_END)
	e1:SetCondition(function() return Duel.IsMainPhase() end)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--search a "Kashtira" c, except itself
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--If rm either add it to your h or SpSumm it in def pos
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.target)
	e3:SetOperation(s.operation)
	c:RegisterEffect(e3)
end
s.listed_names={id}
s.listed_series={SET_MANNADIUM,SET_KASHTIRA}
function s.rmfilter(c)
	return c:IsSetCard({SET_MANNADIUM,SET_KASHTIRA}) --and c:IsAbleToRemove()AND ISABLE TOBE DESTROYED
		and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_ONFIELD))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND|LOCATION_ONFIELD)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_HAND|LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
function s.thfilter(c)--search a "Kashtira" c, except itself
	return c:IsSetCard(SET_KASHTIRA) and c:IsAbleToHand() and not c:IsCode(id)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
function s.filter(c,e,tp)--If rm either add it to your h or SpSumm it in def pos, then you can reduce its Lv by 1
	return c:IsCode(id) and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,c,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3))
	local c=e:GetHandler()
	if not c then return end
	aux.ToHandOrElse(c,tp,
					function()
						return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
							and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) 
					end,
					function()
					if	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE) and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
					Duel.BreakEffect()
					--Decrease Level by 1
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_UPDATE_LEVEL)
					e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
					e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
					e1:SetValue(-1)
					c:RegisterEffect(e1)
				end
					end,
					aux.Stringid(id,4)
					)
end
-------------
--Mannadium Kashtira (MDPRO3)
--Scripted by Mardras
-- local s,id,o=GetID()
-- function s.initial_effect(c)
-- 	--Special Summon this card
-- 	local e1=Effect.CreateEffect(c)
-- 	e1:SetDescription(aux.Stringid(id,0))
-- 	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
-- 	e1:SetType(EFFECT_TYPE_QUICK_O)
-- 	e1:SetCode(EVENT_FREE_CHAIN)
-- 	e1:SetRange(LOCATION_HAND)
-- 	e1:SetCountLimit(1,id)
-- 	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
-- 	e1:SetCondition(s.spcon)
-- 	e1:SetTarget(s.sptg)
-- 	e1:SetOperation(s.spop)
-- 	c:RegisterEffect(e1)
-- 	--search a "Kashtira" c, except itself
-- 	local e2=Effect.CreateEffect(c)
-- 	e2:SetDescription(aux.Stringid(id,1))
-- 	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
-- 	e2:SetType(EFFECT_TYPE_IGNITION)
-- 	e2:SetRange(LOCATION_GRAVE)
-- 	e2:SetCountLimit(1,id+o)
-- 	e2:SetCost(aux.bfgcost)
-- 	e2:SetTarget(s.thtg)
-- 	e2:SetOperation(s.thop)
-- 	c:RegisterEffect(e2)
-- 	--If rm either add it to your h or SpSumm it in def pos
-- 	local e3=Effect.CreateEffect(c)
-- 	e3:SetDescription(aux.Stringid(id,2))
-- 	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
-- 	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
-- 	e3:SetProperty(EFFECT_FLAG_DELAY)
-- 	e3:SetCode(EVENT_REMOVE)
-- 	e3:SetCountLimit(1)--,id+o*2)
-- 	e3:SetTarget(s.target)
-- 	e3:SetOperation(s.operation)
-- 	c:RegisterEffect(e3)
-- end
-- function s.spcon(e,tp,eg,ep,ev,re,r,rp)--Special Summon this card
-- 	local ph=Duel.GetCurrentPhase()
-- 	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
-- end
-- function s.rmfilter(c)
-- 	return c:IsSetCard(0x189,0x190) and (c:IsLocation(LOCATION_HAND) or c:IsLocation(LOCATION_ONFIELD))
-- end
-- function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
-- 	local c=e:GetHandler()
-- 	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
-- 		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
-- 		and Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
-- 	end
-- 	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
-- 	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD)
-- end
-- function s.spop(e,tp,eg,ep,ev,re,r,rp)
-- 	local c=e:GetHandler()
-- 	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
-- 	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
-- 	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
-- 	if #g>0 then
-- 		Duel.Destroy(g,REASON_EFFECT)
-- 	end
-- end
-- function s.thfilter(c)--search a "Kashtira" c, except itself
-- 	return c:IsSetCard(0x189) and c:IsAbleToHand() and not c:IsCode(id)
-- end
-- function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
-- 	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
-- 	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
-- end
-- function s.thop(e,tp,eg,ep,ev,re,r,rp)
-- 	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
-- 	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
-- 	if #g>0 then
-- 		Duel.SendtoHand(g,nil,REASON_EFFECT)
-- 		Duel.ConfirmCards(1-tp,g)
-- 	end
-- end
-- function s.target(e,tp,eg,ep,ev,re,r,rp,chk)--if rm either add it to your h or sp summ it in def pos
-- 	if chk==0 then return e:GetHandler():IsAbleToHand()
-- 		or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)) end
-- end
-- function s.operation(e,tp,eg,ep,ev,re,r,rp)
-- 	local c=e:GetHandler()
-- 	if not c:IsRelateToEffect(e) then return end
-- 	local b1=c:IsAbleToHand()
-- 	local b2=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
-- 	local op=aux.SelectFromOptions(tp,{b1,1190},{b2,1152})
-- 	if op==1 then
-- 		Duel.SendtoHand(c,nil,REASON_EFFECT)
-- 	end
-- 	if op==2 then
-- 		if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)>0 
-- 		    and Duel.SelectYesNo(tp,aux.Stringid(45154513,0)) then
-- 		    Duel.BreakEffect()
-- 			--reduce its level by 1
-- 		    local e1=Effect.CreateEffect(c)
-- 		    e1:SetType(EFFECT_TYPE_SINGLE)
-- 		    e1:SetCode(EFFECT_UPDATE_LEVEL)
-- 		    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
-- 		    e1:SetValue(-1)
-- 		    c:RegisterEffect(e1)
-- 	    end
-- 	end
-- end