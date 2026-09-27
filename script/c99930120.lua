--OTNN World Star Twintails
--Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
  --Activate
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)

  --(1) Attack Lock
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetCode(EFFECT_CANNOT_ACTIVATE)
  e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
  e1:SetRange(LOCATION_FZONE)
  e1:SetTargetRange(0,1)
  e1:SetCondition(s.atkcon)
  e1:SetValue(s.aclimit)
  c:RegisterEffect(e1)

  --(2) Attach on Special Summon
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,0))
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e2:SetRange(LOCATION_FZONE)
  e2:SetCountLimit(1,id)
  e2:SetCondition(s.attachcon)
  e2:SetTarget(s.attachtg)
  e2:SetOperation(s.attachop)
  c:RegisterEffect(e2)

  --(3) Special Summon OTNN Xyz if opponent controls more monsters
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,1))
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_FZONE)
  e3:SetCountLimit(1,id+1)
  e3:SetTarget(s.sptg)
  e3:SetOperation(s.spop)
  c:RegisterEffect(e3)

  --(4) GY add effect
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(id,2))
  e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e4:SetCode(EVENT_TO_GRAVE)
  e4:SetProperty(EFFECT_FLAG_DELAY)
  e4:SetCountLimit(1,id+2)
  e4:SetTarget(s.thtg)
  e4:SetOperation(s.thop)
  c:RegisterEffect(e4)
end

--(1) Attack Lock
function s.atkcon(e)
  local atk=Duel.GetAttacker()
  return atk and atk:IsControler(e:GetHandlerPlayer()) and atk:IsSetCard(0x993) and atk:IsType(TYPE_XYZ)
end
function s.aclimit(e,re,tp)
  local loc = re:GetActivateLocation()
  return tp==1-e:GetHandlerPlayer() and (loc==LOCATION_HAND or loc==LOCATION_GRAVE)
end

--(2) Attach on Special Summon
function s.attachconfilter(c,tp)
  return c:IsFaceup() and c:IsSetCard(0x993) and c:GetSummonPlayer()==tp and c:GetSummonType()==SUMMON_TYPE_XYZ
end
function s.attachcon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(s.attachconfilter,1,nil,tp)
end
function s.attachfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
end
function s.attachmatfilter(c)
  return c:IsRace(RACE_WARRIOR) and c:IsAbleToChangeControler()
end
function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chk==0 then
    return Duel.IsExistingTarget(s.attachfilter,tp,LOCATION_MZONE,0,1,nil)
      and Duel.IsExistingMatchingCard(s.attachmatfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
  Duel.SelectTarget(tp,s.attachfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.attachop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  local tc=Duel.GetFirstTarget()
  if tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsImmuneToEffect(e) then
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectMatchingCard(tp,s.attachmatfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.Overlay(tc,g)~=0 then
      local e1=Effect.CreateEffect(e:GetHandler())
      e1:SetType(EFFECT_TYPE_SINGLE)
      e1:SetCode(EFFECT_UPDATE_ATTACK)
      e1:SetReset(RESET_EVENT+0x1ff0000+RESET_PHASE+PHASE_END)
      e1:SetValue(g:GetFirst():GetAttack()/2)
      tc:RegisterEffect(e1)
    end
  end
end

--(3) Special Summon OTNN Xyz
function s.xyzfilter(c,e,tp)
  return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_MZONE,0) > Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
    and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
    and Duel.GetLocationCountFromEx(tp,tp,nil)>0 end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
  local sc=g:GetFirst()
  if sc then
    Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
    sc:CompleteProcedure()
  end
end

--(4) GY add OTNN monster AND Spell
function s.thfilter_mon(c)
  return c:IsSetCard(0x993) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thfilter_spell(c)
  return c:IsSetCard(0x993) and c:IsType(TYPE_SPELL) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    return Duel.IsExistingMatchingCard(s.thfilter_mon,tp,LOCATION_DECK,0,1,nil)
       and Duel.IsExistingMatchingCard(s.thfilter_spell,tp,LOCATION_DECK,0,1,nil)
  end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g1=Duel.SelectMatchingCard(tp,s.thfilter_mon,tp,LOCATION_DECK,0,1,1,nil)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g2=Duel.SelectMatchingCard(tp,s.thfilter_spell,tp,LOCATION_DECK,0,1,1,nil)
  g1:Merge(g2)
  if #g1>0 then
    Duel.SendtoHand(g1,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g1)
  end
end