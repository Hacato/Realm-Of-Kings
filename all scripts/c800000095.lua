--Overlord Voracious Drain
--Scripted by Raivost
function c800000095.initial_effect(c)
  --Activate
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(800000095,0))
  e1:SetCategory(CATEGORY_DESTROY+CATEGORY_RECOVER+CATEGORY_ATKCHANGE)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e1:SetCountLimit(1,800000095+EFFECT_COUNT_CODE_OATH)
  e1:SetTarget(c800000095.target)
  e1:SetOperation(c800000095.activate)
  c:RegisterEffect(e1)
end
function c800000095.olfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x992)
end
function c800000095.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return false end
  if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_MZONE,1,nil)
    and Duel.IsExistingTarget(c800000095.olfilter,tp,LOCATION_MZONE,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
  local g1=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_MZONE,1,1,nil)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
  local g2=Duel.SelectTarget(tp,c800000095.olfilter,tp,LOCATION_MZONE,0,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,g1,1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,0)
end
function c800000095.activate(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
  local tc1=g:GetFirst()
  local tc2=g:GetNext()
  if tc1:IsControler(tp) then
    tc1,tc2=tc2,tc1
  end
  if tc1:IsRelateToEffect(e) then
    local atk=tc1:GetBaseAttack()
    if atk<0 then atk=0 end
    if Duel.Destroy(tc1,REASON_EFFECT)~=0 then
      if Duel.Recover(tp,atk,REASON_EFFECT)~=0 and tc2:IsRelateToEffect(e) and tc2:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(atk)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc2:RegisterEffect(e1)
      end
    end
  end
end