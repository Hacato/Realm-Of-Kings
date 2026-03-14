--Droopy Tatsugiri
--Setcode: 0x24A2
local s,id=GetID()

function s.initial_effect(c)

	--Union procedure (WATER monster with 3000+ DEF)
	aux.AddUnionProcedure(c,s.unfilter)

	--Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Force equipped monster to Defense Position
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetRange(LOCATION_SZONE)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)

	--Equip DEF boost
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(1000)
	c:RegisterEffect(e3)

	--Equipped monster attacks using DEF
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_EQUIP)
	e4:SetCode(EFFECT_DEFENSE_ATTACK)
	e4:SetValue(1)
	c:RegisterEffect(e4)

	--Search when sent to GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCountLimit(1,{id,2})
	e5:SetTarget(s.thtg)
	e5:SetOperation(s.thop)
	c:RegisterEffect(e5)

end

--Union target
function s.unfilter(c)
	return c:IsFaceup()
	and c:IsAttribute(ATTRIBUTE_WATER)
	and c:GetBaseDefense()>=3000
end

--Special Summon condition
function s.spfilter(c)
	return c:IsFaceup()
	and c:IsAttribute(ATTRIBUTE_WATER)
	and c:GetBaseDefense()>=2000
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Force DEF position while equipped
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetEquipTarget()
	if tc and tc:IsFaceup() and not tc:IsPosition(POS_FACEUP_DEFENSE) then
		Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)
	end
end

--Search effect
function s.thfilter(c)
	return c:IsSetCard(0x24A2)
	and not c:IsCode(id)
	and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
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