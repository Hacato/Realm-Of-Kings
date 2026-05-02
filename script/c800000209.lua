--Metarion King Cobrastar
--Scripted by Hacato
local s,id=GetID()
local CARD_IMAGINARY_ACTOR=800000205
local CARD_SNAKE_CLOWN=800000207
local FLAG_ATTACKED=id+101

function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,CARD_IMAGINARY_ACTOR,s.matfilter)

	--Must be Fusion Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.fuslimit)
	c:RegisterEffect(e0)

	--This card's Type is also always treated as Reptile
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_RACE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_ALL)
	e1:SetValue(RACE_REPTILE)
	c:RegisterEffect(e1)

	--If Snake Clown was used as material, grant extra attack as continuous effect
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCondition(s.snakecon)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--Mark after this card declares an attack
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	--After first attack, it can only attack opponent's Reptile monsters (only if Snake Clown was material)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e4:SetCondition(s.atkcon)
	e4:SetValue(s.atklimit)
	c:RegisterEffect(e4)

	--Draw, then place same number from hand on bottom of Deck
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,1})
	e5:SetTarget(s.drtg)
	e5:SetOperation(s.drop)
	c:RegisterEffect(e5)

	--Quick Effect if "Imaginary Actor" is in your GY
	local e6=e5:Clone()
	e6:SetType(EFFECT_TYPE_QUICK_O)
	e6:SetCode(EVENT_FREE_CHAIN)
	e6:SetCondition(s.qcon)
	c:RegisterEffect(e6)

	--If this Fusion Summoned card is sent to the GY by an opponent's card
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_DESTROY)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetCode(EVENT_TO_GRAVE)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCountLimit(1,{id,2})
	e7:SetCondition(s.descon)
	e7:SetTarget(s.destg)
	e7:SetOperation(s.desop)
	c:RegisterEffect(e7)
end

s.listed_names={CARD_IMAGINARY_ACTOR,CARD_SNAKE_CLOWN}
s.listed_series={0x80b}

function s.matfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_REPTILE,fc,sumtype,tp)
end

function s.snakecon(e)
	local c=e:GetHandler()
	local g=c:GetMaterial()
	return c:IsSummonType(SUMMON_TYPE_FUSION)
		and g~=nil and g:IsExists(Card.IsCode,1,nil,CARD_SNAKE_CLOWN)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(FLAG_ATTACKED,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE,0,1)
end

function s.atkcon(e)
	return e:GetHandler():GetFlagEffect(FLAG_ATTACKED)>0
		and s.snakecon(e)
end

function s.atklimit(e,c)
	return not (c:IsControler(1-e:GetHandlerPlayer()) and c:IsRace(RACE_REPTILE))
end

function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,1,nil,CARD_IMAGINARY_ACTOR)
end

function s.metfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x80b) and c:IsMonster()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.metfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return ct>0 and Duel.IsPlayerCanDraw(tp,ct) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,ct)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,tp,LOCATION_HAND)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.metfilter,tp,LOCATION_MZONE,0,nil)
	if ct<=0 then return end
	if Duel.Draw(tp,ct,REASON_EFFECT)==ct then
		Duel.BreakEffect()
		if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)<ct then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,ct,ct,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		end
	end
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and rp==1-tp
end

function s.desfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_REPTILE)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end