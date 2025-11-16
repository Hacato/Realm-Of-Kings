--OTNN Tail Blue
--Scripted by Raivost
function c99930020.initial_effect(c)
  c:EnableReviveLimit()
  --Xyz Summon: 2+ Warrior monsters with the same Level
  Xyz.AddProcedure(c,c99930020.xyzfilter,nil,2,nil,nil,Xyz.InfiniteMats,nil,false,c99930020.xyzcheck)
  --(1) This card gains 1 Rank for each material attached to it
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_UPDATE_RANK)
  e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
  e1:SetRange(LOCATION_MZONE)
  e1:SetValue(c99930020.rankval)
  c:RegisterEffect(e1)
  --(2) If this card attacks, before damage calculation: It gains ATK equal to its Rank x 500, until the end of the Damage Step
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99930020,0))
  e2:SetCategory(CATEGORY_ATKCHANGE)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_ATTACK_ANNOUNCE)
  e2:SetOperation(c99930020.atkop)
  c:RegisterEffect(e2)
  --(3) If this card destroys a monster by battle: You can attach that monster to this card as material
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99930020,1))
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e3:SetCode(EVENT_BATTLE_DESTROYING)
  e3:SetCondition(aux.bdocon)
  e3:SetTarget(c99930020.attachtg)
  e3:SetOperation(c99930020.attachop)
  c:RegisterEffect(e3)
  --(4) Once per turn, when your opponent would Special Summon exactly 1 monster (Quick Effect): You can detach 1 material; negate the Special Summon, destroy that card, and inflict 1000 damage
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(99930020,2))
  e4:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
  e4:SetType(EFFECT_TYPE_QUICK_O)
  e4:SetCode(EVENT_SPSUMMON)
  e4:SetRange(LOCATION_MZONE)
  e4:SetCountLimit(1)
  e4:SetCondition(c99930020.dscon)
  e4:SetCost(c99930020.dscost)
  e4:SetTarget(c99930020.dstg)
  e4:SetOperation(c99930020.dsop)
  c:RegisterEffect(e4)
  --(5) While this card has a material that is owned by your opponent, it gains: If this card attacks a Defense Position monster, inflict triple piercing battle damage
  local e5=Effect.CreateEffect(c)
  e5:SetType(EFFECT_TYPE_SINGLE)
  e5:SetCode(EFFECT_PIERCE)
  e5:SetCondition(c99930020.piercecon)
  c:RegisterEffect(e5)
  local e6=Effect.CreateEffect(c)
  e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
  e6:SetCode(EVENT_PRE_BATTLE_DAMAGE)
  e6:SetCondition(c99930020.damcon)
  e6:SetOperation(c99930020.damop)
  c:RegisterEffect(e6)
end

--Xyz Summon
function c99930020.xyzfilter(c,tp)
  return c:IsRace(RACE_WARRIOR) and c:IsLevelAbove(1)
end
function c99930020.xyzcheck(g,tp)
  local mg=g:Filter(function(c) return not c:IsHasEffect(511001175) end,nil)
  return mg:GetClassCount(Card.GetLevel)==1
end

--(1) Gain Rank equal to material count
function c99930020.rankval(e,c)
  return c:GetOverlayCount()
end

--(2) Gain ATK
function c99930020.atkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsRelateToEffect(e) and c:IsFaceup() then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_DAMAGE)
    e1:SetValue(c:GetRank()*500)
    c:RegisterEffect(e1)
  end
end

--(3) Attach
function c99930020.attachtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
end
function c99930020.attachop(e,tp,eg,ep,ev,re,r,rp)
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

--(4) Disable Special Summon
function c99930020.dscon(e,tp,eg,ep,ev,re,r,rp)
  return tp~=ep and eg:GetCount()==1 and Duel.GetCurrentChain()==0
end
function c99930020.dscost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
  e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function c99930020.dstg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,eg:GetCount(),0,0)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,eg:GetCount(),0,0)
  Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function c99930020.dsop(e,tp,eg,ep,ev,re,r,rp)
  Duel.NegateSummon(eg)
  if Duel.Destroy(eg,REASON_EFFECT)~=0 then
    Duel.BreakEffect()
    Duel.Damage(1-tp,1000,REASON_EFFECT)
  end
end

--(5) Triple Piercing (only when has opponent's material)
function c99930020.piercecon(e)
  local c=e:GetHandler()
  local og=c:GetOverlayGroup()
  return og:IsExists(Card.IsPreviousControler,1,nil,1-e:GetHandlerPlayer())
end
function c99930020.damcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if not (ep~=tp and c==Duel.GetAttacker() and Duel.GetAttackTarget() and Duel.GetAttackTarget():IsDefensePos()) then
    return false
  end
  -- Check if has opponent's material
  local og=c:GetOverlayGroup()
  return og:IsExists(Card.IsPreviousControler,1,nil,1-tp)
end
function c99930020.damop(e,tp,eg,ep,ev,re,r,rp)
  local dam=Duel.GetBattleDamage(ep)
  Duel.ChangeBattleDamage(ep,dam*3)
end