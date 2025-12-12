-- Harmony Element of Kindness
local s,id=GetID()
function s.initial_effect(c)
	-- Activate: 2 different possible effects
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- GY effect: recover LP
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_RECOVER)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.rectg)
	e2:SetOperation(s.recop)
	c:RegisterEffect(e2)
end

-- condition: spell count in GY
function s.spellcount(tp)
	return Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
end

-- GY monster filter for first effect
function s.lvfilter(c,e,tp)
	return c:GetLevel()>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Extra Deck filter for XYZ summon
function s.xyzfilter(c,mg)
	return c:IsXyzSummonable(nil,mg,2,2)
end

-- Extra Deck special summon filter
function s.spfilter(c,e,tp)
	return c:IsCode(50000041) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,true,true)
end

-- helper: check if at least 2 monsters with same Level exist
function s.haspair(g)
	local lvcount={}
	for tc in aux.Next(g) do
		local lv=tc:GetLevel()
		lvcount[lv]=(lvcount[lv] or 0)+1
		if lvcount[lv]>=2 then return true end
	end
	return false
end

-- target setup
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local sc=s.spellcount(tp)
	if chk==0 then
		if sc<5 then
			-- need 2 monsters with same Level in GY + 2 zones free
			local g=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
			return s.haspair(g) and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		else
			-- need Harmony Wielder of Kindness in Extra
			return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
		end
	end
end

-- activation operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sc=s.spellcount(tp)
	if sc<5 then
		-- First effect: pick 2 monsters with same Level
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
		local g=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
		if #g<2 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg1=g:Select(tp,1,1,nil)
		local tc1=sg1:GetFirst()
		local lvl=tc1:GetLevel()
		local g2=g:Filter(function(c) return c:GetLevel()==lvl and c~=tc1 end,nil)
		if #g2==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg2=g2:Select(tp,1,1,nil)
		sg1:Merge(sg2)
		if Duel.SpecialSummon(sg1,0,tp,tp,false,false,POS_FACEUP)==2 then
			for tc in aux.Next(sg1) do
				-- Negate effects
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				local e2=e1:Clone()
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				tc:RegisterEffect(e2)
				-- Change Level to 7
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_CHANGE_LEVEL)
				e3:SetValue(7)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e3)
			end
			Duel.BreakEffect()
			local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,sg1)
			if #xyzg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
				Duel.XyzSummon(tp,xyz,sg1)
			end
		end
	else
		-- Second effect: summon Harmony Wielder of Kindness
		if Duel.GetLocationCountFromEx(tp)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #g>0 and Duel.SpecialSummon(g,SUMMON_TYPE_XYZ,tp,tp,true,true,POS_FACEUP)~=0 then
			local tc=g:GetFirst()
			tc:CompleteProcedure()
			if c:IsRelateToEffect(e) then
				c:CancelToGrave()
				Duel.Overlay(tc,Group.FromCards(c))
			end
		end
	end
end

-- recover target
function s.recfilter(c)
	return c:IsFaceup() and c:GetBaseAttack()>0
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.recfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.recfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.recfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,g:GetFirst():GetBaseAttack())
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Recover(tp,tc:GetBaseAttack(),REASON_EFFECT)
	end
end
