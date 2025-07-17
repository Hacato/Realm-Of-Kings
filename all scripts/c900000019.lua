--Domain Of The Thunder Dragon God
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Can only activate 1 per turn
	c:SetUniqueOnField(1,0,id)
	--ATK boost for Thunder monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_THUNDER))
	e2:SetValue(500)
	c:RegisterEffect(e2)
	--Banish Thunder monster to draw
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.drawcost)
	e3:SetTarget(s.drawtg)
	e3:SetOperation(s.drawop)
	c:RegisterEffect(e3)
	--Cannot target Thunder monsters if you control Thunder DragonGod Raijin
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.tgtg)
	e4:SetCondition(s.tgcon)
	e4:SetValue(aux.tgoval)
	c:RegisterEffect(e4)
	--Draw when Thunder monster is summoned from Extra Deck
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_DRAW)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCondition(s.edcon)
	e5:SetTarget(s.edtg)
	e5:SetOperation(s.edop)
	c:RegisterEffect(e5)
end

s.listed_names={CARD_THUNDER_DRAGON_GOD_RAIJIN} --Replace with actual card code if different
s.listed_series={0x11c} --Thunder Dragon archetype

--Banish Thunder monster to draw
function s.drawcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_DECK,0,1,nil,RACE_THUNDER) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsRace,tp,LOCATION_DECK,0,1,1,nil,RACE_THUNDER)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end

--Cannot target condition and target
function s.tgcon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,900000017),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.tgtg(e,c)
	return c:IsRace(RACE_THUNDER)
end

--Draw when Thunder monster summoned from Extra Deck
function s.edfilter(c,tp)
	return c:IsRace(RACE_THUNDER) and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_EXTRA)
end
function s.edcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.edfilter,1,nil,tp)
end
function s.edtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.edop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Draw(p,d,REASON_EFFECT)
end