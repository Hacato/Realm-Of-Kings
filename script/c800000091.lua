--Overlord Nazarick Guardian, Mare
--Scripted by Hacato
function c800000091.initial_effect(c)
  --(1) Special Summon from hand
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetDescription(aux.Stringid(800000091,0))
  e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
  e1:SetCode(EFFECT_SPSUMMON_PROC)
  e1:SetRange(LOCATION_HAND)
  e1:SetCondition(c800000091.hspcon)
  e1:SetOperation(c800000091.hspop)
  e1:SetValue(1)
  c:RegisterEffect(e1)
  --(2) Gain ATK/DEF
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(800000091,1))
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetRange(LOCATION_MZONE)
  e2:SetCountLimit(1)
  e2:SetCondition(c800000091.atkcon)
  e2:SetTarget(c800000091.atktg)
  e2:SetOperation(c800000091.atkop)
  c:RegisterEffect(e2)
  --(3) Special Summon Pleiades
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(800000091,2))
  e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1,800000091)
  e3:SetTarget(c800000091.sptg)
  e3:SetOperation(c800000091.spop)
  c:RegisterEffect(e3)
  --(4) Draw when opponent activates Spell from hand
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(800000091,3))
  e4:SetCategory(CATEGORY_DRAW)
  e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
  e4:SetCode(EVENT_CHAINING)
  e4:SetRange(LOCATION_MZONE)
  e4:SetCondition(c800000091.drcon)
  e4:SetTarget(c800000091.drtg)
  e4:SetOperation(c800000091.drop)
  c:RegisterEffect(e4)
  --(5) Destroy monster
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(800000091,4))
  e5:SetCategory(CATEGORY_DESTROY)
  e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
  e5:SetCode(EVENT_SUMMON_SUCCESS)
  e5:SetRange(LOCATION_MZONE)
  e5:SetProperty(EFFECT_FLAG_DELAY)
  e5:SetCondition(c800000091.descon)
  e5:SetCost(c800000091.descost)
  e5:SetTarget(c800000091.destg)
  e5:SetOperation(c800000091.desop)
  c:RegisterEffect(e5)
  local e6=e5:Clone()
  e6:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
  c:RegisterEffect(e6)
  local e7=e5:Clone()
  e7:SetCode(EVENT_SPSUMMON_SUCCESS)
  c:RegisterEffect(e7)
end
--(1) Special Summon from hand
function c800000091.hspcon(e,c)
  if c==nil then return true end
  local tp=c:GetControler()
  return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function c800000091.hspop(e,tp,eg,ep,ev,re,r,rp,c)
  Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
--(2) Gain ATK/DEF
function c800000091.atkcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local rc=re:GetHandler()
  return c:GetSummonType()==SUMMON_TYPE_SPECIAL+1 or (re and rc:IsSetCard(0x992) and rc~=c)
end
function c800000091.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
end
function c800000091.atkop(e,tp,eg,ep,ev,re,r,rp)
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
function c800000091.spfilter(c,e,tp)
  return c:IsSetCard(0xB92) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function c800000091.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(c800000091.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function c800000091.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,c800000091.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
  if g:GetCount()>0 then
    Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
  end
end
--(4) Draw when opponent activates Spell from hand
function c800000091.drcon(e,tp,eg,ep,ev,re,r,rp)
  return rp==1-tp and re:IsActiveType(TYPE_SPELL) and re:GetHandler():IsPreviousLocation(LOCATION_HAND)
end
function c800000091.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function c800000091.drop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Draw(tp,1,REASON_EFFECT)
end
--(5) Destroy monster
function c800000091.ainzfilter(c,seq,p)
  return c:IsFaceup() and c:IsCode(99920010) and c:IsColumn(seq,p,LOCATION_MZONE)
end
function c800000091.desfilter(c,tp,mc)
  return c:GetSummonPlayer()==1-tp and (mc:GetColumnGroup():IsContains(c) 
    or Duel.IsExistingMatchingCard(c800000091.ainzfilter,tp,LOCATION_MZONE,0,1,nil,c:GetSequence(),1-tp))
end
function c800000091.descon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(c800000091.desfilter,1,nil,tp,e:GetHandler())
end
function c800000091.cfilter(c)
  return c:IsSetCard(0x992) and c:IsType(TYPE_SPELL) and c:IsAbleToRemoveAsCost()
end
function c800000091.descost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c800000091.cfilter,tp,LOCATION_GRAVE,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
  local g=Duel.SelectMatchingCard(tp,c800000091.cfilter,tp,LOCATION_GRAVE,0,1,1,nil)
  Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function c800000091.destg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return eg:IsExists(c800000091.desfilter,1,nil,tp,e:GetHandler()) end
  local g=eg:Filter(c800000091.desfilter,nil,tp,e:GetHandler())
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetTargetCard(g)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,g:GetCount(),0,0)
end
function c800000091.desop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(c800000091.desfilter,nil,tp,e:GetHandler())
  if g:GetCount()>0 then
    Duel.Destroy(g,REASON_EFFECT)
  end
end