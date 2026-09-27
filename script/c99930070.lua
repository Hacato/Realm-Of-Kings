--OTNN Tails Emergency
--Scripted by Raivost
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--Filter for Warrior monsters (Hand/Deck)
function s.filter(c,e,tp)
	return c:IsRace(RACE_WARRIOR) and c:GetLevel()>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Filter for OTNN Xyz monsters (Extra Deck)
function s.xyzfilter(c,mg)
	return c:IsSetCard(0x993) and c:IsXyzSummonable(nil,mg,2,2)
end

--Check for another monster with the same level in the pool
function s.mfilter1(c,mg)
	return mg:IsExists(s.mfilter2,1,c,c:GetLevel())
end
function s.mfilter2(c,lv)
	return c:GetLevel()==lv
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	-- Pool all valid Warriors from Hand and Deck
	local mg=Duel.GetMatchingGroup(s.filter,tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,tp)
	
	if chk==0 then 
		return not Duel.IsPlayerAffectedByEffect(tp,59822133)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and mg:IsExists(s.mfilter1,1,nil,mg) 
	end
	
	-- Force the UI to prompt for BOTH cards from the entire pool at once
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=mg:FilterSelect(tp,s.mfilter1,1,1,nil,mg)
	local tc1=g1:GetFirst()
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g2=mg:FilterSelect(tp,s.mfilter2,1,1,tc1,tc1:GetLevel())
	g1:Merge(g2)
	
	Duel.SetTargetCard(g1)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g1,2,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	-- Extra Deck Restriction applies regardless of summon success
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	if Duel.IsPlayerAffectedByEffect(tp,59822133) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
	if #g<2 then return end
	
	-- Calculate total levels for the ATK boost before summoning
	local atk_val=0
	for tc in aux.Next(g) do
		atk_val = atk_val + tc:GetLevel()
	end
	
	-- Attempt to summon both
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==2 then
		Duel.BreakEffect()
		-- Find valid OTNN Xyz monsters in Extra Deck using only these 2 materials
		local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil,g)
		if #xyzg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local xyz=xyzg:Select(tp,1,1,nil):GetFirst()
			if Duel.XyzSummon(tp,xyz,g,nil,2,2) then
				-- ATK Boost: Combined Levels x 100 until End Phase
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_UPDATE_ATTACK)
				e2:SetValue(atk_val*100)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				xyz:RegisterEffect(e2)
			end
		end
	end
end

function s.splimit(e,c)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_XYZ)
end