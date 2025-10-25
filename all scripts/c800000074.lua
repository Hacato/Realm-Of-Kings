--Fate Ephemeral Silhouette
local s,id=GetID()
function s.initial_effect(c)
	--Activate when Ritual Spell activation or any Summon of "Fate" Ritual Monster is negated
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_SUMMON_NEGATED)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.summoncon)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_NEGATED)
	c:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EVENT_FLIP_SUMMON_NEGATED)
	c:RegisterEffect(e3)
	local e4=e1:Clone()
	e4:SetCode(EVENT_CHAIN_NEGATED)
	e4:SetCondition(s.spellcon)
	c:RegisterEffect(e4)
end
s.listed_series={0x989}

--Condition for any Summon negation (Normal/Flip/Special)
function s.summoncon(e,tp,eg,ep,ev,re,r,rp)
	if not eg then return false end
	--Check if a "Fate" Ritual Monster's summon was negated
	return eg:IsExists(function(c) return c:IsSetCard(0x989) and c:IsType(TYPE_RITUAL) end,1,nil)
end

--Condition for Ritual Spell negation
function s.spellcon(e,tp,eg,ep,ev,re,r,rp)
	if not re then return false end
	local rc=re:GetHandler()
	if not rc then return false end
	--Check if the negated card is a Ritual Spell (any Ritual Spell)
	return rc:IsType(TYPE_RITUAL) and rc:IsType(TYPE_SPELL)
end

function s.thfilter(c)
	return c:IsSetCard(0x989) and c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_MZONE)
end

function s.desfilter(c,turncount)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:GetTurnID()==turncount
end

function s.spellfilter(c)
	return c:IsSetCard(0x989) and c:IsType(TYPE_SPELL) and not c:IsType(TYPE_RITUAL) and not c:IsType(TYPE_QUICKPLAY) and not c:IsType(TYPE_CONTINUOUS) and not c:IsType(TYPE_EQUIP) and not c:IsType(TYPE_FIELD) and c:IsAbleToHand()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
		Duel.ConfirmCards(1-tp,g)
		local turncount=Duel.GetTurnCount()-1
		local b1=Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_MZONE,1,nil,turncount)
		local b2=Duel.IsExistingMatchingCard(s.spellfilter,tp,LOCATION_DECK,0,1,nil)
		if not (b1 or b2) then return end
		local op=Duel.SelectEffect(tp,
			{b1,aux.Stringid(id,1)},
			{b2,aux.Stringid(id,2)})
		if op==1 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local dg=Duel.SelectMatchingCard(tp,s.desfilter,tp,0,LOCATION_MZONE,1,1,nil,turncount)
			if #dg>0 then
				Duel.BreakEffect()
				Duel.Destroy(dg,REASON_EFFECT)
			end
		elseif op==2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.spellfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #sg>0 then
				Duel.BreakEffect()
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end