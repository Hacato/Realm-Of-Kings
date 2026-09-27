--Seafarer Undead King Black Bart
function c77777705.initial_effect(c)
--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x999),1,99)
	c:EnableReviveLimit()
	--set
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(77777705,1))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(c77777705.target)
	e1:SetOperation(c77777705.operation)
	c:RegisterEffect(e1)
	--Banish
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetDescription(aux.Stringid(77777705,0))
	e2:SetTarget(c77777705.destarget)
	e2:SetOperation(c77777705.desoperation)
	c:RegisterEffect(e2)
	--cannot be target
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(c77777705.tgval)
	c:RegisterEffect(e3)
end

function c77777705.tgval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

function c77777705.filter(c)
	return c:IsDestructable() and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function c77777705.filter2(c)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToChangeControler()
end
function c77777705.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return  Duel.IsExistingMatchingCard(c77777705.filter2,tp,0,LOCATION_HAND+LOCATION_GRAVE,1,nil) 
	and Duel.IsExistingMatchingCard(c77777705.filter,tp,LOCATION_ONFIELD,0,1,nil)end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
  Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,0,0)
end
function c77777705.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
  local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
  local tg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
  if g:GetCount()>0 then
    tg=g:Filter(Card.IsType,nil,TYPE_SPELL+TYPE_TRAP)
    Duel.ConfirmCards(tp,tg)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
  local hg=Duel.SelectMatchingCard(tp,c77777705.filter2,tp,0,LOCATION_HAND+LOCATION_GRAVE,1,1,nil)
  local tc=hg:GetFirst()
  Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
  Duel.ChangePosition(tc,POS_FACEDOWN)
  Duel.ConfirmCards(1-tp,tc)
  Duel.ShuffleHand(1-tp)
  end

function c77777705.dfilter(c,s)
	return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsDestructable()
end
function c77777705.destarget(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) and Duel.IsExistingMatchingCard(c77777705.dfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler())end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
  Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,0)
end
function c77777705.desoperation(e,tp,eg,ep,ev,re,r,rp)
  if not Duel.IsExistingMatchingCard(c77777705.dfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler()) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local tc=Duel.SelectMatchingCard(tp,c77777705.dfilter,tp,LOCATION_ONFIELD,0,1,1,nil,e,tp)
	if Duel.Destroy(tc,REASON_EFFECT)~=0 and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
		if g:GetCount()>0 then
			Duel.HintSelection(g)
			Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		end	
	end
end
