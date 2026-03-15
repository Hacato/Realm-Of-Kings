--Miraihunder
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,s.matfilter,4,2)

	--Protection: Cannot be targeted by opponent
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)  -- YOUR monsters
	e1:SetTarget(s.prottg)               -- non-Xyz Thunder only
	e1:SetValue(aux.tgoval)              -- standard cannot-target value
	c:RegisterEffect(e1)

	--Protection: Cannot be destroyed by opponent's effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.prottg)
	e2:SetValue(s.indval)                -- only opponent's effects
	c:RegisterEffect(e2)

	--Protection: Opponent cannot attack them
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)  -- opponent selects
	e3:SetValue(s.atlimit)
	c:RegisterEffect(e3)

	--Detach to search + Normal Summon (soft once per turn)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)                  -- soft once per turn
	e4:SetCost(s.cost)
	e4:SetTarget(s.target)
	e4:SetOperation(s.operation)
	c:RegisterEffect(e4)
end

--Xyz material filter
function s.matfilter(c,tp,lc)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_THUNDER)
end

--Filter for protection (non-Xyz Thunder monsters)
function s.prottg(e,c)
	return c:IsFaceup() and c:IsRace(RACE_THUNDER) and not c:IsType(TYPE_XYZ)
end

--Opponent cannot attack these monsters
function s.atlimit(e,c)
	return c:IsFaceup() and c:IsRace(RACE_THUNDER) and not c:IsType(TYPE_XYZ)
end

--Cannot be destroyed by opponent's effects
function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

--Detach 1 material as cost
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Search filter: Level 4 LIGHT Thunder
function s.thfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_THUNDER) and c:IsLevel(4) and c:IsAbleToHand()
end

--Target for search effect
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

--Search and Normal Summon
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		local tc=g:GetFirst()
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
			if tc:IsSummonable(true,nil) then
				Duel.BreakEffect()
				Duel.Summon(tp,tc,true,nil)
			end
		end
	end
end