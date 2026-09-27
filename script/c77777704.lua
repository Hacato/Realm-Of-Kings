--Seafarer Undead Gunslinger Cecile
function c77777704.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x999),1,99)
	c:EnableReviveLimit()
	--spell/trap to hand
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,77777704)
	e1:SetCondition(c77777704.con)
	e1:SetTarget(c77777704.thtg)
	e1:SetOperation(c77777704.thop)
	c:RegisterEffect(e1)
	--Destroy 2
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetDescription(aux.Stringid(77777704,1))
	e2:SetTarget(c77777704.destarget)
	e2:SetOperation(c77777704.desoperation)
	c:RegisterEffect(e2)
end


function c77777704.con(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetSummonType()==SUMMON_TYPE_SYNCHRO
end

function c77777704.thfilter(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP)and c:IsSetCard(0x999) and c:IsAbleToHand()
end
function c77777704.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(c77777704.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function c77777704.thop(e,tp,eg,ep,ev,re,r,rp)
  if not Duel.IsExistingMatchingCard(c77777704.thfilter,tp,LOCATION_GRAVE,0,1,nil) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,c77777704.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
  Duel.SendtoHand(g,nil,REASON_EFFECT)
  Duel.ConfirmCards(1-tp,g)
end


function c77777704.dfilter(c,s)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsDestructable()
end
function c77777704.destarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsDestructable() end
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDestructable,tp,0,LOCATION_MZONE,2,nil)
		and Duel.IsExistingMatchingCard(c77777704.dfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler())end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,1-tp,LOCATION_MZONE)
end
function c77777704.desoperation(e,tp,eg,ep,ev,re,r,rp)
  if not Duel.IsExistingMatchingCard(c77777704.dfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler()) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,c77777704.dfilter,tp,LOCATION_ONFIELD,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if Duel.Destroy(tc,REASON_EFFECT)~=0 and Duel.IsExistingMatchingCard(Card.IsDestructable,tp,0,LOCATION_MZONE,2,nil) then
    Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g2=Duel.SelectMatchingCard(tp,Card.IsDestructable,tp,0,LOCATION_MZONE,2,2,nil)  
		if g2:GetCount()>0 then
      Duel.Destroy(g2,REASON_EFFECT)
    end
	end
end
