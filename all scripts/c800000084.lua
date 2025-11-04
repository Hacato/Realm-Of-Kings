--YuYuYu A Hero's Will
--Scripted by Assistant
function c800000084.initial_effect(c)
  --(1) Ritual Summon with ATK boost
  Ritual.AddProcGreater({
    handler=c,
    filter=c800000084.ritualfilter,
    location=LOCATION_HAND|LOCATION_EXTRA,
    stage2=c800000084.stage2
  })
end
function c800000084.ritualfilter(c)
  return c:IsSetCard(0x991) and c:IsRitualMonster() and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end
function c800000084.stage2(mat,e,tp,eg,ep,ev,re,r,rp,tc)
  -- ATK boost effect
  local ct=Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_MZONE,0,nil,0x991)
  if ct>0 then
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(ct*500)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN,1)
    tc:RegisterEffect(e1)
  end
  
  -- LP loss at End Phase
  if Duel.GetFlagEffect(tp,800000084)==0 then
    Duel.RegisterFlagEffect(tp,800000084,RESET_PHASE+PHASE_END,0,1)
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetCountLimit(1)
    e2:SetReset(RESET_PHASE+PHASE_END)
    e2:SetOperation(c800000084.loseop)
    Duel.RegisterEffect(e2,tp)
  end
end
function c800000084.loseop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_CARD,0,800000084)
  Duel.SetLP(tp,Duel.GetLP(tp)-1000)
end