--YuYuYu Ritual Spell
--Scripted by Raivost
function c99910010.initial_effect(c)
  --(1) Ritual Summon and Equip
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99910010,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetTarget(c99910010.sptg)
  e1:SetOperation(c99910010.spop)
  c:RegisterEffect(e1)
end
--(1) Ritual Summon and Equip
function c99910010.spfilter(c,e,tp)
  return c:IsSetCard(0x991) and bit.band(c:GetType(),0x81)==0x81 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
end
function c99910010.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
  and Duel.IsExistingMatchingCard(c99910010.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end
function c99910010.eqfilter(c)
  return c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and not c:IsForbidden()
end
function c99910010.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local tg=Duel.SelectMatchingCard(tp,c99910010.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
  local tc=tg:GetFirst()
  if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP)~=0 then
    tc:CompleteProcedure()
    if Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
      local b1=Duel.IsEnvironment(99910070) and Duel.IsExistingMatchingCard(c99910010.eqfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
      local b2=Duel.IsExistingMatchingCard(c99910010.eqfilter,tp,LOCATION_HAND,0,1,nil)
      if b1 or b2 then
        if Duel.SelectYesNo(tp,aux.Stringid(99910010,1)) then
          Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
          local g=nil
          if b1 then
            g=Duel.SelectMatchingCard(tp,c99910010.eqfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
          else
            g=Duel.SelectMatchingCard(tp,c99910010.eqfilter,tp,LOCATION_HAND,0,1,1,nil)
          end
          local ec=g:GetFirst()
          if ec then
            Duel.BreakEffect()
            Duel.Equip(tp,ec,tc)
            --Equip limit
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            e1:SetValue(c99910010.eqlimit)
            e1:SetLabelObject(tc)
            ec:RegisterEffect(e1)
          end
        end
      end
    end
    --(1.1) Lose LP
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetCountLimit(1)
    e2:SetReset(RESET_PHASE+PHASE_END)
    e2:SetOperation(c99910010.loseop)
    Duel.RegisterEffect(e2,tp)
  end
end
function c99910010.eqlimit(e,c)
  return c==e:GetLabelObject()
end
--(1.1) Lose LP
function c99910010.loseop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_CARD,0,99910010)
  Duel.SetLP(tp,Duel.GetLP(tp)-1000)
end