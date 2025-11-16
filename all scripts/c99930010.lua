--OTNN Tail Red
--Scripted by Raivost
function c99930010.initial_effect(c)
  c:EnableReviveLimit()
  --Xyz Summon: 2 or more Warrior-Type monsters with the same Level
  Xyz.AddProcedure(c,c99930010.xyzfilter,nil,2,nil,nil,Xyz.InfiniteMats,nil,false,c99930010.xyzcheck)
  --(1) During each Standby Phase, increase this card's Rank by 1
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99930010,0))
  e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
  e1:SetRange(LOCATION_MZONE)
  e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
  e1:SetCountLimit(1)
  e1:SetCondition(c99930010.rkcon)
  e1:SetTarget(c99930010.rktg)
  e1:SetOperation(c99930010.rkop)
  c:RegisterEffect(e1)
  --(2) If this card declares an attack: It gains ATK equal to its Rank x 100 until the end of the Damage Step
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99930010,1))
  e2:SetCategory(CATEGORY_ATKCHANGE)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_ATTACK_ANNOUNCE)
  e2:SetOperation(c99930010.atkop)
  c:RegisterEffect(e2)
  --(3) When this card destroys a monster by battle: Attach it to this card as an Xyz Material
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99930010,2))
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e3:SetCode(EVENT_BATTLE_DESTROYING)
  e3:SetCondition(aux.bdocon)
  e3:SetOperation(c99930010.attachop)
  c:RegisterEffect(e3)
  --(4) Once per turn, when your opponent activates a monster effect: You can detach 1 Xyz Material; negate that activation, and if you do, this card gains half of that monster's original ATK until the End Phase
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(99930010,3))
  e4:SetCategory(CATEGORY_NEGATE+CATEGORY_ATKCHANGE)
  e4:SetType(EFFECT_TYPE_QUICK_O)
  e4:SetCode(EVENT_CHAINING)
  e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
  e4:SetRange(LOCATION_MZONE)
  e4:SetCountLimit(1)
  e4:SetCondition(c99930010.negcon)
  e4:SetCost(c99930010.negcost)
  e4:SetTarget(c99930010.negtg)
  e4:SetOperation(c99930010.negop)
  c:RegisterEffect(e4)
  --(5) If this card destroys a monster by battle, it can make a second attack in a row
  local e5=Effect.CreateEffect(c)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
  e5:SetCode(EVENT_BATTLE_DESTROYING)
  e5:SetCondition(aux.bdocon)
  e5:SetOperation(c99930010.atklimitop)
  c:RegisterEffect(e5)
end

--Xyz Summon
function c99930010.xyzfilter(c,tp)
  return c:IsRace(RACE_WARRIOR) and c:IsLevelAbove(1)
end
function c99930010.xyzcheck(g,tp)
  local mg=g:Filter(function(c) return not c:IsHasEffect(511001175) end,nil)
  return mg:GetClassCount(Card.GetLevel)==1 
end

--(1) Gain Rank
function c99930010.rkcon(e,tp,eg,ep,ev,re,r,rp)
  return e:GetHandler():IsType(TYPE_XYZ)
end
function c99930010.rktg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
end
function c99930010.rkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsFacedown() or not c:IsRelateToEffect(e) then return end
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_UPDATE_RANK)
  e1:SetValue(1)
  e1:SetReset(RESET_EVENT+0x1ff0000)
  c:RegisterEffect(e1)
end

--(2) Gain ATK
function c99930010.atkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsRelateToEffect(e) and c:IsFaceup() then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_DAMAGE)
    e1:SetValue(c:GetRank()*100)
    c:RegisterEffect(e1)
  end
end

--(3) Attach
function c99930010.attachop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tc=c:GetBattleTarget()
  if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsAbleToChangeControler() 
  and not tc:IsImmuneToEffect(e) and not tc:IsHasEffect(EFFECT_NECRO_VALLEY) then
    local og=tc:GetOverlayGroup()
    if og:GetCount()>0 then
      Duel.SendtoGrave(og,REASON_RULE)
    end
    Duel.Overlay(c,Group.FromCards(tc))
  end
end

--(4) Negate
function c99930010.negcon(e,tp,eg,ep,ev,re,r,rp)
  return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) 
    and rp~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end
function c99930010.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
  e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function c99930010.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end
function c99930010.negop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local rc=re:GetHandler()
  if Duel.NegateActivation(ev) and rc:IsRelateToEffect(re) and c:IsRelateToEffect(e) and c:IsFaceup() then
    local atk=rc:GetBaseAttack()
    if atk>0 then
      local e1=Effect.CreateEffect(c)
      e1:SetType(EFFECT_TYPE_SINGLE)
      e1:SetCode(EFFECT_UPDATE_ATTACK)
      e1:SetReset(RESET_EVENT+0x1ff0000+RESET_PHASE+PHASE_END)
      e1:SetValue(math.floor(atk/2))
      c:RegisterEffect(e1)
    end
  end
end

--(5) Second attack
function c99930010.atklimitop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsRelateToBattle() and c:IsFaceup() then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EXTRA_ATTACK)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_BATTLE)
    e1:SetValue(1)
    c:RegisterEffect(e1)
  end
end