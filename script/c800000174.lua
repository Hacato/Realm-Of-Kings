--Ame no Habakiri Ignite Module - Tsubasa
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x2406),4,2)

	--Must be Xyz Summoned
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--Alternative Xyz Summon during opponent's turn with 1 material
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.xyzcon)
	e1:SetTarget(s.xyztg)
	e1:SetOperation(s.xyzop)
	e1:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e1)

	--Register Xyz Summon during opponent's turn (PERMANENT flag)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.regcon)
	e2:SetOperation(s.regop)
	c:RegisterEffect(e2)

	--Quick battle during opponent's turn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e3:SetCondition(s.battlecon)
	e3:SetTarget(s.battletg)
	e3:SetOperation(s.battleop)
	e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OPPONENT_TURN)
	c:RegisterEffect(e3)

	--Destroy and place on top of Deck at start of Damage Step
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DESTROY+CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BATTLE_START)
	e4:SetCondition(s.descon)
	e4:SetCost(s.descost)
	e4:SetTarget(s.destg)
	e4:SetOperation(s.desop)
	c:RegisterEffect(e4)

	--Send to GY if no materials, then add 1 Level 4 "SZS" monster
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCondition(s.tgcon)
	e5:SetTarget(s.tgtg)
	e5:SetOperation(s.tgop)
	c:RegisterEffect(e5)
end
s.listed_series={0x2406}
s.xyz_number=0

--Must be Xyz Summoned
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ
end

--1-material alternative Xyz Summon during opponent's turn
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2406) and c:IsLevel(4) and c:IsCanBeXyzMaterial(nil)
end
function s.xyzcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetTurnPlayer()==1-tp
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local sg=g:Select(tp,1,1,nil)
	if #sg>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	else
		return false
	end
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

--PERMANENTLY registers "Xyz Summoned during opponent's turn"
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ) and Duel.GetTurnPlayer()==1-tp
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	--No turn limit, stays active until card leaves the field
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

--Quick battle during opponent's turn
function s.battlecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local phase=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==1-tp
		and c:GetFlagEffect(id)>0
		and c:IsAttackPos()
		and phase~=PHASE_DAMAGE and phase~=PHASE_DAMAGE_CAL
end
function s.battletg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end
function s.battleop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACKTARGET)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	if #g>0 then
		Duel.CalculateDamage(c,g:GetFirst())
	end
end

--Destroy and place on top of Deck
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsControler(1-tp) and bc:IsFaceup()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local bc=e:GetHandler():GetBattleTarget()
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,bc,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		if Duel.Destroy(bc,REASON_EFFECT)>0 then
			--Place on top of Deck instead of going to GY
			local og=Duel.GetOperatedGroup()
			local tc=og:GetFirst()
			if tc and tc:IsLocation(LOCATION_GRAVE) then
				Duel.SendtoDeck(tc,nil,SEQ_DECKTOP,REASON_EFFECT)
			end
		end
	end
end

--Send to GY if no materials, then add 1 Level 4 "SZS" monster
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetOverlayCount()==0
end
function s.tgfilter(c)
	return c:IsSetCard(0x2406) and c:IsLevel(4) and c:IsAbleToHand()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SendtoGrave(c,REASON_EFFECT)>0 and c:IsLocation(LOCATION_GRAVE) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.tgfilter),tp,LOCATION_GRAVE,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end