--Stardust Resonator
local s,id=GetID()

function s.initial_effect(c)
	--Reveal 1 Level 8 Dragon Synchro Monster;
	--Special Summon this card, then optionally search a card that mentions it
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

--==================================================
-- Reveal Level 8 Dragon Synchro Monster
--==================================================

function s.rvfilter(c)
	return c:IsType(TYPE_SYNCHRO)
		and c:IsRace(RACE_DRAGON)
		and c:IsLevel(8)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.rvfilter,tp,LOCATION_EXTRA,0,1,nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(
		tp,s.rvfilter,tp,LOCATION_EXTRA,0,1,1,nil
	)

	local tc=g:GetFirst()
	Duel.ConfirmCards(1-tp,g)

	--Store the revealed monster's card ID
	e:SetLabel(tc:GetCode())
end

--==================================================
-- Search cards that mention the revealed monster
--==================================================

function s.thfilter(c,code)
	return c:IsAbleToHand()
		and c:ListsCode(code)
end

--==================================================
-- Special Summon
--==================================================

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(
				e,0,tp,false,false
			)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local code=e:GetLabel()

	--Special Summon Stardust Resonator
	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then
		return
	end

	--"and if you do, you can add..."
	if not Duel.IsExistingMatchingCard(
		s.thfilter,tp,LOCATION_DECK,0,1,nil,code
	) then
		return
	end

	if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,code
	)

	if #g==0 then return end

	Duel.SendtoHand(g,nil,REASON_EFFECT)
	Duel.ConfirmCards(1-tp,g)

	--If you searched, restrict Extra Deck summons
	--to Dragon monsters for the rest of this turn
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--==================================================
-- Extra Deck restriction
--==================================================

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA)
		and not c:IsRace(RACE_DRAGON)
end