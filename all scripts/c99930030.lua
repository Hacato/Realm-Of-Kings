--OTNN Tail Yellow
--Scripted by Raivost
function c99930030.initial_effect(c)
  c:EnableReviveLimit()
  --Xyz Summon: 2+ Warrior monsters with the same Level
  Xyz.AddProcedure(c,c99930030.xyzfilter,nil,2,nil,nil,Xyz.InfiniteMats,nil,false,c99930030.xyzcheck)
  --(1) This card gains 1 Rank for each material attached to it
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_UPDATE_RANK)
  e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
  e1:SetRange(LOCATION_MZONE)
  e1:SetValue(c99930030.rankval)
  c:RegisterEffect(e1)
  --(2) If this card attacks, before damage calculation: It gains ATK equal to its Rank x 500, until the end of the Damage Step
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99930030,0))
  e2:SetCategory(CATEGORY_ATKCHANGE)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_ATTACK_ANNOUNCE)
  e2:SetOperation(c99930030.atkop)
  c:RegisterEffect(e2)
  --(3) If this card destroys a monster by battle: You can attach that monster to this card as material
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99930030,1))
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e3:SetCode(EVENT_BATTLE_DESTROYING)
  e3:SetCondition(aux.bdocon)
  e3:SetTarget(c99930030.attachtg)
  e3:SetOperation(c99930030.attachop)
  c:RegisterEffect(e3)
  --(4) Once per turn, if an Xyz Monster you control would be destroyed: You can detach 1 material instead, and if you do, inflict 200 damage for each face-up card opponent controls
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
  e4:SetCode(EFFECT_DESTROY_REPLACE)
  e4:SetRange(LOCATION_MZONE)
  e4:SetCountLimit(1)
  e4:SetTarget(c99930030.dreptg)
  e4:SetValue(c99930030.drepval)
  e4:SetOperation(c99930030.drepop)
  c:RegisterEffect(e4)
  --(5) While this card has a material owned by opponent: At the start of the Damage Step, if this card attacks: You can destroy S/T up to number of materials instead of damage calculation
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(99930030,2))
  e5:SetCategory(CATEGORY_DESTROY)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e5:SetCode(EVENT_BATTLE_CONFIRM)
  e5:SetCondition(c99930030.descon)
  e5:SetTarget(c99930030.destg)
  e5:SetOperation(c99930030.desop)
  c:RegisterEffect(e5)
end

--Xyz Summon
function c99930030.xyzfilter(c,tp)
  return c:IsRace(RACE_WARRIOR) and c:IsLevelAbove(1)
end
function c99930030.xyzcheck(g,tp)
  local mg=g:Filter(function(c) return not c:IsHasEffect(511001175) end,nil)
  return mg:GetClassCount(Card.GetLevel)==1
end

--(1) Gain Rank equal to material count
function c99930030.rankval(e,c)
  return c:GetOverlayCount()
end

--(2) Gain ATK
function c99930030.atkop(e,tp,eg,ep,ev,re,r,rp)
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
function c99930030.attachtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
end
function c99930030.attachop(e,tp,eg,ep,ev,re,r,rp)
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

--(4) Destroy replace
function c99930030.drepfilter(c,tp)
  return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) 
    and c:IsType(TYPE_XYZ) and c:IsReason(REASON_EFFECT+REASON_BATTLE) and not c:IsReason(REASON_REPLACE)
end
function c99930030.dreptg(e,tp,eg,ep,ev,re,r,rp,chk)
  local c=e:GetHandler()
  if chk==0 then return eg:IsExists(c99930030.drepfilter,1,nil,tp) 
    and c:CheckRemoveOverlayCard(tp,1,REASON_EFFECT) end
  if Duel.SelectEffectYesNo(tp,c,96) then
    c:RemoveOverlayCard(tp,1,1,REASON_EFFECT+REASON_REPLACE)
    return true
  else 
    return false 
  end
end
function c99930030.drepval(e,c)
  return c99930030.drepfilter(c,e:GetHandlerPlayer())
end
function c99930030.drepop(e,tp,eg,ep,ev,re,r,rp)
  local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE+LOCATION_SZONE)
  if ct>0 then
    Duel.Damage(1-tp,ct*200,REASON_EFFECT)
  end
end

--(5) Destroy S/T instead of damage calculation (only when has opponent's material)
function c99930030.descon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local bc=c:GetBattleTarget()
  if not (c==Duel.GetAttacker() and bc) then return false end
  -- Check if has opponent's material
  local og=c:GetOverlayGroup()
  return og:IsExists(Card.IsPreviousControler,1,nil,1-tp)
end
function c99930030.destg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then 
    local ct=e:GetHandler():GetOverlayCount()
    return ct>0 and Duel.IsExistingMatchingCard(Card.IsType,tp,0,LOCATION_SZONE,1,nil,TYPE_SPELL+TYPE_TRAP)
  end
  local ct=e:GetHandler():GetOverlayCount()
  local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_SPELL+TYPE_TRAP)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,math.min(ct,#g),0,0)
end
function c99930030.desop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
  local ct=c:GetOverlayCount()
  if ct==0 then return end
  local g=Duel.GetMatchingGroup(Card.IsType,tp,0,LOCATION_SZONE,nil,TYPE_SPELL+TYPE_TRAP)
  if #g==0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
  local sg=g:Select(tp,1,math.min(ct,#g),nil)
  if #sg>0 and Duel.Destroy(sg,REASON_EFFECT)>0 then
    -- Prevent battle destruction of monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e1:SetValue(1)
    e1:SetReset(RESET_PHASE+PHASE_DAMAGE)
    Duel.RegisterEffect(e1,tp)
    -- Skip damage calculation
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(1,1)
    e2:SetReset(RESET_PHASE+PHASE_DAMAGE)
    Duel.RegisterEffect(e2,tp)
  end
end