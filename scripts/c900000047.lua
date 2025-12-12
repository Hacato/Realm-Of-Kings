--Dominus Maximus, The Punisher Of The Dovakin
--Scripted by ChatGPT
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Can only be Special Summoned by Infernus Dominus, the Lord Of The Dovakin
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(function(e,se,sp,st) return se and se:GetHandler():IsCode(900000046) end)
	c:RegisterEffect(e0)
	-- Cannot be targeted by opponent’s card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	-- On summon: negate all opponent face-up cards, banish your field except this, burn 600 per banished
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetTarget(s.smtg)
	e2:SetOperation(s.smop)
	c:RegisterEffect(e2)
	-- Burn when it destroys monster by battle (FIXED: Always inflicts half original ATK as damage)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(aux.bdocon)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
	-- If it leaves field by opponent’s card, inflict 1000
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DAMAGE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCondition(s.lfcon)
	e4:SetTarget(s.lftg)
	e4:SetOperation(s.lfop)
	c:RegisterEffect(e4)
end

-- On summon: negate opponent’s face-up cards, banish your field (except itself), burn 600 per banished
function s.smtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	local g2=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,0,e:GetHandler())
	if chk==0 then return #g1>0 or #g2>0 end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g1,#g1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g2,#g2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g2*600)
end
function s.smop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- Negate all opponent’s face-up cards
	local g1=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
	for tc in aux.Next(g1) do
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
	-- Banish all you control except this card and damage
	local g2=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,0,c)
	if #g2>0 then
		if Duel.Remove(g2,POS_FACEUP,REASON_EFFECT)~=0 then
			local ct=#g2
			if ct>0 then
				Duel.Damage(1-tp,ct*600,REASON_EFFECT)
			end
		end
	end
end

-- Battle destruction burn (FIXED: always half original ATK)
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleTarget()
	if chk==0 then return bc~=nil end
	local at=bc:GetTextAttack()
	if at<0 then at=0 end
	local dam=math.floor(at/2)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,dam)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc then
		local at=bc:GetTextAttack()
		if at<0 then at=0 end
		local dam=math.floor(at/2)
		Duel.Damage(1-tp,dam,REASON_EFFECT)
	end
end

-- Leave field by opponent → burn 1000
function s.lfcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return rp~=tp and c:IsPreviousControler(tp)
end
function s.lftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function s.lfop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Damage(1-tp,1000,REASON_EFFECT)
end