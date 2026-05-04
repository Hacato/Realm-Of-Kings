--Imaginary Reactor
local s,id=GetID()
local SET_IMAGINARY_ARC=0x79b
local SET_METARION=0x80b
local CARD_IMAGINARY_ACTOR=800000205
local CARD_MONSTER_REINCARNATION=74848038

function s.initial_effect(c)
	--Link Summon procedure: 1 LIGHT monster with 500 DEF
	Link.AddProcedure(c,s.matfilter,1,1)
	c:EnableReviveLimit()

	--This card's name is treated as "Imaginary Actor" while face-up on field or in GY
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_CODE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e0:SetValue(CARD_IMAGINARY_ACTOR)
	c:RegisterEffect(e0)

	--If Link Summoned: Set 1 "Imaginary Arc" Spell/Trap from Deck
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--Send top 2 cards; optionally recycle "Monster Reincarnation" and draw 2
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)

	--GY replacement: protect a "Metarion" Fusion Monster from destruction
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,3})
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_IMAGINARY_ACTOR,CARD_MONSTER_REINCARNATION}
s.listed_series={SET_IMAGINARY_ARC,SET_METARION}

function s.matfilter(c,lc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_LIGHT)
		and c:IsDefense(500)
end

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.setfilter(c)
	return c:IsSetCard(SET_IMAGINARY_ARC) and c:IsSpellTrap() and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetDecktopGroup(tp,2):FilterCount(Card.IsAbleToGrave,nil)==2
			and Duel.IsPlayerCanDraw(tp,2)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.recfilter(c)
	return c:IsCode(CARD_MONSTER_REINCARNATION) and c:IsAbleToDeck()
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetDecktopGroup(tp,2)
	if #g<2 then return end
	if Duel.SendtoGrave(g,REASON_EFFECT)==0 then return end

	if Duel.IsExistingMatchingCard(s.recfilter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,2)
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=Duel.SelectMatchingCard(tp,s.recfilter,tp,LOCATION_GRAVE,0,1,1,nil)
		local tc=sg:GetFirst()
		if tc and Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
			Duel.Draw(tp,2,REASON_EFFECT)
		end
	end
end

function s.repfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsFaceup()
		and c:IsSetCard(SET_METARION)
		and c:IsType(TYPE_FUSION)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemove()
			and eg:IsExists(s.repfilter,1,nil,tp)
	end
	if Duel.SelectEffectYesNo(tp,c,96) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
		local g=eg:FilterSelect(tp,s.repfilter,1,1,nil,tp)
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.repval(e,c)
	local g=e:GetLabelObject()
	return g and g:IsContains(c)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if g then
		g:DeleteGroup()
	end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end