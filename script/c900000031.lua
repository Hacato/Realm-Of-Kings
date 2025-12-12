--Veidos' Ashened Raign
--Counter Trap Card
local s,id=GetID()
function s.initial_effect(c)
	--Negate activation that targets
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end
s.listed_names={8540986,78783557} --Veidos card IDs (replace with actual IDs)
--Add token ID to listed names if it has a specific card ID
function s.cfilter(c)
	return c:IsFaceup() and (c:IsCode(8540986) or c:IsCode(78783557)) --Check for either Veidos card
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsChainNegatable(ev) and re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.ashfilter(c,e,tp)
	return c:IsSetCard(0x1a5) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) --Ashened archetype
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.fusfilter(c,e,tp,mg)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_PYRO) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) then
		--Check card type before destruction
		local is_monster=rc:IsType(TYPE_MONSTER)
		local is_trap=rc:IsType(TYPE_TRAP)
		local is_spell=rc:IsType(TYPE_SPELL)
		
		if Duel.Destroy(rc,REASON_EFFECT)>0 then
			--Apply effects in sequence based on destroyed card type
			
			--Monster effect: Special Summon Cast Token to opponent's field
			if is_monster and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
				and Duel.IsPlayerCanSpecialSummonMonster(tp,900000029,0,TYPES_TOKEN,0,0,1,RACE_PYRO,ATTRIBUTE_DARK,POS_FACEUP,1-tp) then
				local token=Duel.CreateToken(tp,900000029) --Cast Token ID (replace with actual token ID)
				Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP)
			end
			
			--Trap effect: Special Summon Ashened monster from GY or banished
			if is_trap and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				local g=Duel.GetMatchingGroup(s.ashfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
				if #g>0 then
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local sg=g:Select(tp,1,1,nil)
					Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
				end
			end
			
			--Spell effect: Fusion Summon Pyro Fusion Monster using monsters from either field
			if is_spell then
				--Get fusion material from both fields
				local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
				local fg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
				if #fg>0 and #mg>0 then
					Duel.BreakEffect()
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
					local fc=fg:Select(tp,1,1,nil):GetFirst()
					if fc then
						local mat=Duel.SelectFusionMaterial(tp,fc,mg,nil,tp)
						fc:SetMaterial(mat)
						Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
						Duel.BreakEffect()
						Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
						fc:CompleteProcedure()
					end
				end
			end
		end
	end
end