--Fate Witch of Betrayal
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_names={0x989}
s.listed_series={0x989,0xF69}
s.counter_place_list={0x1997}

function s.costfilter(c)
	return c:IsSetCard(0x989) and c:IsMonster() and c:IsDiscardable()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.casterfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x989) and c:IsSetCard(0xF69)
end
function s.fieldfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_FIELD) and c:IsSetCard(0x989) and c:IsCanAddCounter(0x1997,1)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Discard up to 2 "Fate" monsters with different names
	local g=Duel.GetMatchingGroup(s.costfilter,tp,LOCATION_HAND,0,nil)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_DISCARD)
	if #sg>0 then
		local discarded=Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
		if discarded>0 then
			--Draw cards equal to number discarded
			Duel.Draw(tp,discarded,REASON_EFFECT)
			--If you control a "Fate" monster with "Caster" in its name, place Relic Counters
			if Duel.IsExistingMatchingCard(s.casterfilter,tp,LOCATION_MZONE,0,1,nil) then
				local fc=Duel.GetFirstMatchingCard(s.fieldfilter,tp,LOCATION_FZONE,0,nil)
				if fc then
					fc:AddCounter(0x1997,discarded)
				end
			end
		end
	end
end