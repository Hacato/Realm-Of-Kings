--Eclipse Ritual
local s,id=GetID()
function s.initial_effect(c)
	--Activate Ritual Spell
	local e1=Ritual.CreateProc({
		handler=c,
		lvtype=RITPROC_GREATER,
		filter=s.ritualfil,
		extrafil=s.extrafil,
		extraop=nil,
		matfilter=nil,
		stage2=nil,
		location=LOCATION_HAND, -- Changed from LOCATION_HAND+LOCATION_DECK
		forcedselection=nil,
		specificmatfilter=nil
	})
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	c:RegisterEffect(e1)
	
	--Banish to add DARK monster to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCondition(s.thcon)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	e2:SetCountLimit(1,id)
	c:RegisterEffect(e2)
end
s.listed_series={0x04B2}

--Filter for Ritual Monsters
function s.ritualfil(c)
	return c:IsSetCard(0x04B2) and c:IsRitualMonster()
end

--Extra materials
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	return nil
end

--Condition check for banish effect
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnCount()~=e:GetHandler():GetTurnID()
end

--Target DARK monster in GY
function s.thfilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

--Add DARK monster to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end