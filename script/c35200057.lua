--Supremecode Talker
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,nil,2,nil,s.lcheck)
	
	--Add material attributes as card hint
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EVENT_SPSUMMON_SUCCESS)
	e0:SetCondition(s.regcon)
	e0:SetOperation(s.regop)
	c:RegisterEffect(e0)
	
	--ATK gain and effects based on materials
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.regcon)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)
end

function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x101)
end

function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	local attr=0
	
	for tc in aux.Next(mg) do
		attr = attr | tc:GetAttribute()
	end
	
	-- Store attribute flags
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,attr)
	
	-- Add hints to indicate gained effects
	if attr & ATTRIBUTE_EARTH ~= 0 then
		c:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,4))
	end
	if attr & ATTRIBUTE_WATER ~= 0 then
		c:RegisterFlagEffect(id+200,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,5))
	end
	if attr & ATTRIBUTE_FIRE ~= 0 then
		c:RegisterFlagEffect(id+300,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,6))
	end
	if attr & ATTRIBUTE_WIND ~= 0 then
		c:RegisterFlagEffect(id+400,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,7))
	end
	if attr & ATTRIBUTE_LIGHT ~= 0 then
		c:RegisterFlagEffect(id+500,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,8))
	end
	if attr & ATTRIBUTE_DARK ~= 0 then
		c:RegisterFlagEffect(id+600,RESET_EVENT+RESETS_STANDARD,EFFECT_FLAG_CLIENT_HINT,1,0,aux.Stringid(id,9))
	end
end

function s.link3matfilter(c)
	return c:IsSetCard(0x101) and c:IsLink(3)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	
	-- Count Link-3 Code Talker monsters
	local count=mg:FilterCount(s.link3matfilter,nil)
	
	-- ATK gain
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(count*2300)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e1)
	
	-- Get attribute flags
	local attr=0
	if c:GetFlagEffectLabel(id) then
		attr=c:GetFlagEffectLabel(id)
	else
		-- Fallback to recalculating
		for tc in aux.Next(mg) do
			attr = attr | tc:GetAttribute()
		end
	end
	
	-- Apply effects based on attributes
	-- EARTH: protection
	if attr & ATTRIBUTE_EARTH ~= 0 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e2:SetRange(LOCATION_MZONE)
		e2:SetTargetRange(LOCATION_MZONE,0)
		e2:SetTarget(s.indtg)
		e2:SetValue(1)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e2)
		local e3=e2:Clone()
		e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		c:RegisterEffect(e3)
	end
	
	-- WATER: draw on attack
	if attr & ATTRIBUTE_WATER ~= 0 then
		local e4=Effect.CreateEffect(c)
		e4:SetDescription(aux.Stringid(id,0))
		e4:SetCategory(CATEGORY_DRAW)
		e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
		e4:SetCode(EVENT_ATTACK_ANNOUNCE)
		e4:SetRange(LOCATION_MZONE)
		e4:SetCountLimit(1,id)
		e4:SetCondition(s.drawcon)
		e4:SetTarget(s.drawtg)
		e4:SetOperation(s.drawop)
		e4:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e4)
	end
	
	-- FIRE: damage on destruction
	if attr & ATTRIBUTE_FIRE ~= 0 then
		local e5=Effect.CreateEffect(c)
		e5:SetDescription(aux.Stringid(id,1))
		e5:SetCategory(CATEGORY_DAMAGE)
		e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
		e5:SetCode(EVENT_BATTLE_DESTROYING)
		e5:SetRange(LOCATION_MZONE)
		e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e5:SetCondition(s.damcon)
		e5:SetTarget(s.damtg)
		e5:SetOperation(s.damop)
		e5:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e5)
	end
	
	-- WIND: negate targeting effects
	if attr & ATTRIBUTE_WIND ~= 0 then
		local e6=Effect.CreateEffect(c)
		e6:SetDescription(aux.Stringid(id,2))
		e6:SetCategory(CATEGORY_NEGATE)
		e6:SetType(EFFECT_TYPE_QUICK_O)
		e6:SetCode(EVENT_CHAINING)
		e6:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
		e6:SetRange(LOCATION_MZONE)
		e6:SetCountLimit(1,id+1)
		e6:SetCondition(s.negcon)
		e6:SetTarget(s.negtg)
		e6:SetOperation(s.negop)
		e6:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e6)
	end
	
	-- LIGHT: banish cards
	if attr & ATTRIBUTE_LIGHT ~= 0 then
		local e7=Effect.CreateEffect(c)
		e7:SetDescription(aux.Stringid(id,3))
		e7:SetCategory(CATEGORY_REMOVE)
		e7:SetType(EFFECT_TYPE_IGNITION)
		e7:SetRange(LOCATION_MZONE)
		e7:SetCountLimit(1,id+2)
		e7:SetTarget(s.rmtg)
		e7:SetOperation(s.rmop)
		e7:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e7)
	end
	
	-- DARK: tribute protection and banish instead of GY
	if attr & ATTRIBUTE_DARK ~= 0 then
		-- Cannot be tributed
		local e8=Effect.CreateEffect(c)
		e8:SetType(EFFECT_TYPE_FIELD)
		e8:SetCode(EFFECT_UNRELEASABLE_SUM)
		e8:SetRange(LOCATION_MZONE)
		e8:SetTargetRange(LOCATION_MZONE,0)
		e8:SetTarget(s.indtg)
		e8:SetValue(1)
		e8:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e8)
		local e9=e8:Clone()
		e9:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		c:RegisterEffect(e9)
		
		-- Banish instead of sending to GY
		local e10=Effect.CreateEffect(c)
		e10:SetType(EFFECT_TYPE_FIELD)
		e10:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
		e10:SetCode(EFFECT_TO_GRAVE_REDIRECT)
		e10:SetRange(LOCATION_MZONE)
		e10:SetTargetRange(0,0xff)
		e10:SetValue(LOCATION_REMOVED)
		e10:SetTarget(s.bantg)
		e10:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e10)
	end
end

function s.indtg(e,c)
	return c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_LINK)
end

function s.drawcon(e,tp,eg,ep,ev,re,r,rp)
	local at=Duel.GetAttacker()
	return at:IsControler(tp) and at:IsRace(RACE_CYBERSE) and at:IsType(TYPE_LINK)
end

function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end

function s.damconfilter(c,tp)
	return c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_LINK) and c:IsControler(tp)
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=eg:GetFirst()
	return rc and rc:IsStatus(STATUS_OPPO_BATTLE) and s.damconfilter(rc,tp)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(2300)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,2300)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end

function s.negfilter(c,tp)
	return c:IsFaceup() and c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_LINK) and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsExists(s.negfilter,1,nil,tp) and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.NegateActivation(ev)
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ct=c:GetLinkedGroupCount()+1
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) and ct>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_ONFIELD)
	-- Cannot be responded to
	Duel.SetChainLimit(function(e,_ep,_tp) return _tp==tp end)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local ct=c:GetLinkedGroupCount()+1
	if ct==0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,ct,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

function s.bantg(e,c)
	return c:GetOwner()~=e:GetHandlerPlayer() and Duel.IsPlayerCanRemove(e:GetHandlerPlayer(),c)
end