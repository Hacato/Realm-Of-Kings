--Ashened into Legend
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Add to hand when "Ashened" monster is destroyed by card effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.addcon)
	e2:SetOperation(s.addop)
	c:RegisterEffect(e2)
	--Activate Obsidim + Special Summon when this card is sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.obsidtg)
	e3:SetOperation(s.obsidop)
	c:RegisterEffect(e3)
end

s.listed_names={03055018} --Obsidim, the Ashened City

--Effect 1: Special Summon from Deck + send weaker monster to GY
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_PYRO) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsLevelBelow(6)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end
	
	--Let player choose which field to summon to
	local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
	local summon_to_opponent=false
	
	if b1 and b2 then
		summon_to_opponent=Duel.SelectYesNo(tp,aux.Stringid(id,2)) --"Summon to opponent's field?"
	elseif b2 then
		summon_to_opponent=true
	end
	
	local summon_player=tp
	local summon_field=tp
	if summon_to_opponent then
		summon_field=1-tp
	end
	
	if Duel.SpecialSummon(tc,0,summon_player,summon_field,false,false,POS_FACEUP)~=0 then
		local controller_field=tc:GetControler()
		local sg=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:GetAttack()<tc:GetAttack() end,controller_field,LOCATION_MZONE,0,nil)
		if #sg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
			local tg=sg:Select(tp,1,1,nil)
			Duel.SendtoGrave(tg,REASON_EFFECT)
		end
	end
end

--Effect 2: Add to hand when "Ashened" monster is destroyed by card effect
function s.addfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) 
		and c:IsSetCard(0x1a5) and c:IsReason(REASON_EFFECT) and c:IsReason(REASON_DESTROY)
end
function s.addcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.addfilter,1,nil,tp)
end
function s.addop(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.addfilter,nil,tp)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)~=0 then
		Duel.ConfirmCards(1-tp,g)
		--Trigger the Obsidim effect since we added to hand
		if s.obsidtg(e,tp,eg,ep,ev,re,r,rp,0) then
			Duel.Hint(HINT_CARD,0,e:GetHandler():GetCode())
			if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then --"Activate Obsidim effect?"
				s.obsidop(e,tp,eg,ep,ev,re,r,rp)
			end
		end
	end
end

--Effect 3: Activate "Obsidim, the Ashened City" and optionally Special Summon DARK Pyro from hand
function s.obsidfilter(c,tp)
	return c:IsCode(03055018) and c:GetActivateEffect() and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.handspfilter(c,e,tp)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_PYRO) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.obsidtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.obsidfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,tp) end
end
function s.obsidop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.obsidfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,tp):GetFirst()
	if tc then
		local te=tc:GetActivateEffect()
		local tg=te:GetTarget()
		local op=te:GetOperation()
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end
		if op then op(te,tp,eg,ep,ev,re,r,rp) end
		--Optional Special Summon from hand
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and 
		   Duel.IsExistingMatchingCard(s.handspfilter,tp,LOCATION_HAND,0,1,nil,e,tp) and 
		   Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			local sg=Duel.SelectMatchingCard(tp,s.handspfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
			if #sg>0 then
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end