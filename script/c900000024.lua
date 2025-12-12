--Infernoble Arms Of The Emperor
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetCategory(CATEGORY_EQUIP)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e0:SetTarget(s.target)
	e0:SetOperation(s.activate)
	c:RegisterEffect(e0)
	--Equip limit
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--Add/Special Summon Warrior
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--Add Noble Knight/Arms/Avalon when sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.thtg2)
	e3:SetOperation(s.thop2)
	c:RegisterEffect(e3)
	--Also trigger when equipped monster is sent to GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg2)
	e4:SetOperation(s.thop2)
	c:RegisterEffect(e4)
end
s.listed_names={82140600} --Avalon

--Equip target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

--Equip operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if e:GetHandler():IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,e:GetHandler(),tc)
	end
end

--Filter for Warrior monsters
function s.thfilter(c,e,tp,ft)
	return c:IsRace(RACE_WARRIOR) and (c:IsAbleToHand() 
		or (ft>0 and c:IsAttribute(ATTRIBUTE_FIRE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
		and (c:IsLocation(LOCATION_DECK+LOCATION_GRAVE) or c:IsFaceup())
end

--Add/Special Summon target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp,ft) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end

--Add/Special Summon operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp,ft)
	if #g>0 then
		local tc=g:GetFirst()
		if tc:IsAttribute(ATTRIBUTE_FIRE) and ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and (not tc:IsAbleToHand() or Duel.SelectYesNo(tp,aux.Stringid(id,2))) then
			if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
				Duel.Destroy(c,REASON_EFFECT)
			end
		else
			if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
				Duel.ConfirmCards(1-tp,tc)
				Duel.Destroy(c,REASON_EFFECT)
			end
		end
	end
end

--Condition for equipped monster sent to GY
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and eg:IsContains(ec)
end

--Filter for Noble Knight/Arms/Avalon
function s.thfilter2(c)
	return (c:IsSetCard(0x107a) or c:IsSetCard(0x207a) or c:IsCode(82140600) 
		or c:ListsCode(82140600)) and c:IsAbleToHand()
end

--Add Noble Knight/Arms/Avalon target
function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Add Noble Knight/Arms/Avalon operation
function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end