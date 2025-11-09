--YuYuYu A Hero's Will
--Scripted by Assistant
function c800000084.initial_effect(c)
  --(1) Ritual Summon with ATK boost
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(800000084,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetTarget(c800000084.target)
  e1:SetOperation(c800000084.activate)
  c:RegisterEffect(e1)
end
--(1) Ritual Summon
function c800000084.filter(c,e,tp)
  return c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_MONSTER)
    and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end
function c800000084.target(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return false end
    return Duel.IsExistingMatchingCard(c800000084.filter,tp,LOCATION_HAND,0,1,nil,e,tp)
      or Duel.IsExistingMatchingCard(aux.AND(c800000084.filter,Card.IsFaceup),tp,LOCATION_EXTRA,0,1,nil,e,tp)
  end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_EXTRA)
end
function c800000084.activate(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.GetMatchingGroup(c800000084.filter,tp,LOCATION_HAND,0,nil,e,tp)
  local eg=Duel.GetMatchingGroup(aux.AND(c800000084.filter,Card.IsFaceup),tp,LOCATION_EXTRA,0,nil,e,tp)
  g:Merge(eg)
  if #g>0 then
    local tc=g:Select(tp,1,1,nil):GetFirst()
    if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
      tc:CompleteProcedure()
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
      
      -- LP loss at End Phase (per use)
      local e2=Effect.CreateEffect(e:GetHandler())
      e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
      e2:SetCode(EVENT_PHASE+PHASE_END)
      e2:SetCountLimit(1)
      e2:SetReset(RESET_PHASE+PHASE_END)
      e2:SetOperation(c800000084.loseop)
      Duel.RegisterEffect(e2,tp)
    end
  end
end
function c800000084.loseop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_CARD,0,800000084)
  Duel.SetLP(tp,Duel.GetLP(tp)-1000)
end