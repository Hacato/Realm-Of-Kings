--Aquamarine Aquasanctuary
local s,id=GetID()
function s.initial_effect(c)
	--Activation
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--Forced targeting (cannot target other monsters)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCondition(s.atkcon)
	e2:SetValue(s.atklimit)
	c:RegisterEffect(e2)
	
	--Special Summon on Fusion Summon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

s.listed_series={0x30cd}

--Activation
function s.thfilter(c)
	return c:IsSetCard(0x30cd) and c:IsAbleToHand() and not c:IsCode(id)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		--Place 1 card from hand to bottom of deck
		if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local tc=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,1,nil):GetFirst()
			if tc then
				Duel.SendtoDeck(tc,nil,0,REASON_EFFECT)
			end
		end
	end
	--Cannot activate monster effects except WATER Aqua (turn player only)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsMonsterEffect() and rc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE)
		and not (rc:IsRace(RACE_AQUA) and rc:IsAttribute(ATTRIBUTE_WATER))
end

--Forced targeting condition (check for Level 7+ Aquamarine Fusion)
function s.atkconfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION) and c:IsLevelAbove(7)
end

function s.atkcon(e)
	return Duel.IsExistingMatchingCard(s.atkconfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--Prevent targeting non-Aquamarine Level 7+ Fusions for attacks
function s.atklimit(e,c)
	local tp=e:GetHandlerPlayer()
	return c:IsFaceup() and not (c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION) and c:IsLevelAbove(7))
		and Duel.IsExistingMatchingCard(s.atkconfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Special Summon on Fusion Summon
function s.spconfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION) 
		and c:IsControler(tp) and c:IsSummonType(SUMMON_TYPE_FUSION)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.spconfilter,1,nil,tp)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x30cd) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end