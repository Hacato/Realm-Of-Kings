--Shiranui Sunsetsaga
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	--Limit Special Summon (once per turn)
	c:SetSPSummonOnce(id)

	--If Synchro Summoned using a Zombie monster(s)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.zncon)
	e1:SetOperation(s.znop)
	c:RegisterEffect(e1)

	--ATK gain (300 per FIRE monster in GY)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	--Immunity to effects of same type as any "Shiranui" in your GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetValue(s.immval)
	c:RegisterEffect(e3)
end

-- Filter for Zombie materials
function s.zfilter(c)
	return c:IsRace(RACE_ZOMBIE)
end

-- Condition: Synchro Summoned
function s.zncon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

-- Apply restrictions if a Zombie was used
function s.znop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	if mg:IsExists(s.zfilter,1,nil) then
		--Opponent cannot banish monsters (anywhere)
		local e1=Effect.CreateEffect(c)
		e1:SetDescription(aux.Stringid(id,0)) -- Banishing restriction hint
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_REMOVE)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetTargetRange(0,1)
		e1:SetTarget(function(e,c) return c:IsType(TYPE_MONSTER) end)
		e1:SetOwnerPlayer(tp)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		Duel.RegisterEffect(e1,tp)

		--Opponent cannot Tribute non-Zombies (all purposes)
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,1)) -- Tribute restriction hint
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_CANNOT_RELEASE)
		e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e2:SetTargetRange(0,1)
		e2:SetTarget(function(e,c) return not c:IsRace(RACE_ZOMBIE) end)
		e2:SetOwnerPlayer(tp)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		Duel.RegisterEffect(e2,tp)
	end
end

-- ATK gain: 300 per FIRE monster in your GY
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsAttribute,c:GetControler(),LOCATION_GRAVE,0,nil,ATTRIBUTE_FIRE)*300
end

-- Immunity to effects of same type as any "Shiranui" card in your GY
function s.immval(e,te)
	if not te:IsActivated() then return false end
	local tp=e:GetHandlerPlayer()
	local ctype=0
	if te:IsActiveType(TYPE_MONSTER) then ctype=TYPE_MONSTER
	elseif te:IsActiveType(TYPE_SPELL) then ctype=TYPE_SPELL
	elseif te:IsActiveType(TYPE_TRAP) then ctype=TYPE_TRAP
	end
	return Duel.IsExistingMatchingCard(function(c,ct) return c:IsSetCard(0xd9) and c:IsType(ct) end,tp,LOCATION_GRAVE,0,1,nil,ctype)
end
