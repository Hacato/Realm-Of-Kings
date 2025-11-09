--Overlord Nazarick Guardian, Aura
--Scripted by Hacato
function c800000092.initial_effect(c)
  --(1) Special Summon from hand
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetDescription(aux.Stringid(800000092,0))
  e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
  e1:SetCode(EFFECT_SPSUMMON_PROC)
  e1:SetRange(LOCATION_HAND)
  e1:SetCondition(c800000092.hspcon)
  e1:SetOperation(c800000092.hspop)
  e1:SetValue(1)
  c:RegisterEffect(e1)
  --(2) Gain ATK/DEF
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(800000092,1))
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetRange(LOCATION_MZONE)
  e2:SetCountLimit(1)
  e2:SetCondition(c800000092.atkcon)
  e2:SetTarget(c800000092.atktg)
  e2:SetOperation(c800000092.atkop)
  c:RegisterEffect(e2)
  --(3) Special Summon Pleiades
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(800000092,2))
  e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1,800000092)
  e3:SetTarget(c800000092.sptg)
  e3:SetOperation(c800000092.spop)
  c:RegisterEffect(e3)
  --(4) ATK loss during battle
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_FIELD)
  e4:SetCode(EFFECT_UPDATE_ATTACK)
  e4:SetRange(LOCATION_MZONE)
  e4:SetTargetRange(0,LOCATION_MZONE)
  e4:SetCondition(c800000092.atkdowncon)
  e4:SetTarget(c800000092.atkdowntg)
  e4:SetValue(-1000)
  c:RegisterEffect(e4)
  --(5) Destroy and Special Summon
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(800000092,3))
  e5:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
  e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
  e5:SetCode(EVENT_CHAIN_SOLVED)
  e5:SetRange(LOCATION_MZONE)
  e5:SetProperty(EFFECT_FLAG_DELAY)
  e5:SetCondition(c800000092.descon)
  e5:SetTarget(c800000092.destg)
  e5:SetOperation(c800000092.desop)
  c:RegisterEffect(e5)
end
--(1) Special Summon from hand
function c800000092.hspcon(e,c)
  if c==nil then return true end
  local tp=c:GetControler()
  return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function c800000092.hspop(e,tp,eg,ep,ev,re,r,rp,c)
  Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
--(2) Gain ATK/DEF
function c800000092.atkcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local rc=re:GetHandler()
  return c:GetSummonType()==SUMMON_TYPE_SPECIAL+1 or (re and rc:IsSetCard(0x992) and rc~=c)
end
function c800000092.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
end
function c800000092.atkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsRelateToEffect(e) and c:IsFaceup() then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetReset(RESET_EVENT+0x1fe0000)
    e1:SetValue(Duel.GetLP(tp))
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2)
  end
end
--(3) Special Summon Pleiades
function c800000092.spfilter(c,e,tp)
  return c:IsSetCard(0xB92) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function c800000092.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(c800000092.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function c800000092.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,c800000092.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
  if g:GetCount()>0 then
    Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
  end
end
--(4) ATK loss during battle
function c800000092.atkdowncon(e)
  local phase=Duel.GetCurrentPhase()
  return phase>=PHASE_BATTLE_START and phase<=PHASE_BATTLE
end
function c800000092.olfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x992)
end
function c800000092.atkdowntg(e,c)
  local handler=e:GetHandler()
  local bc=c:GetBattleTarget()
  return bc and c:GetControler()~=handler:GetControler() and bc:IsSetCard(0x992)
end
--(5) Destroy and Special Summon
function c800000092.ainzfilter(c,seq,p)
  return c:IsFaceup() and c:IsCode(99920010) and c:IsColumn(seq,p,LOCATION_MZONE)
end
function c800000092.descon(e,tp,eg,ep,ev,re,r,rp)
  if not re then return false end
  local rc=re:GetHandler()
  local handler=e:GetHandler()
  if not rc or rp==tp or not rc:IsLocation(LOCATION_MZONE) or not rc:IsControler(1-tp) or not rc:IsRelateToEffect(re) then return false end
  return handler:GetColumnGroup():IsContains(rc) 
    or Duel.IsExistingMatchingCard(c800000092.ainzfilter,tp,LOCATION_MZONE,0,1,nil,rc:GetSequence(),1-tp)
end
function c800000092.destg(e,tp,eg,ep,ev,re,r,rp,chk)
  local rc=re:GetHandler()
  if chk==0 then return rc and rc:IsLocation(LOCATION_MZONE) and rc:IsControler(1-tp) end
  e:SetLabelObject(rc)
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function c800000092.spfilter2(c,e,tp,atk)
  return c:IsAttribute(ATTRIBUTE_DARK) and c:IsAttackBelow(atk) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function c800000092.desop(e,tp,eg,ep,ev,re,r,rp)
  local tc=e:GetLabelObject()
  if tc and tc:IsLocation(LOCATION_MZONE) and tc:IsControler(1-tp) then
    local atk=tc:GetAttack()
    if Duel.Destroy(tc,REASON_EFFECT)~=0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
      and Duel.IsExistingMatchingCard(c800000092.spfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp,atk)
      and Duel.SelectYesNo(tp,aux.Stringid(800000092,4)) then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
      local g=Duel.SelectMatchingCard(tp,c800000092.spfilter2,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp,atk)
      if g:GetCount()>0 then
        Duel.BreakEffect()
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
      end
    end
  end
end