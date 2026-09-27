function c77777959.initial_effect(c)
	--Synchro summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x999),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	-- Destroy on battle start
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(77777959, 0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_BATTLE_START)
	e1:SetTarget(c77777959.destg)
	e1:SetOperation(c77777959.desop)
	c:RegisterEffect(e1)

	-- Synchro level (as tuner)
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_SYNCHRO_LEVEL)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(c77777959.slevel)
	c:RegisterEffect(e2)

	-- Effect gain when used as material
	local e6 = Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_BE_MATERIAL)
	e6:SetCondition(c77777959.efcon)
	e6:SetOperation(c77777959.efop)
	c:RegisterEffect(e6)
end

function c77777959.slevel(e, c)
	local lv = e:GetHandler():GetLevel()
	return 3 * 65536 + lv
end

function c77777959.destg(e, tp, eg, ep, ev, re, r, rp, chk)
	local c = e:GetHandler()
	local tc = Duel.GetAttacker()
	if tc == c then tc = Duel.GetAttackTarget() end
	if chk == 0 then return tc and tc:IsFaceup() end
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, tc, 1, 0, 0)
end

function c77777959.desop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local tc = Duel.GetAttacker()
	if tc == c then tc = Duel.GetAttackTarget() end
	if tc:IsRelateToBattle() then Duel.Destroy(tc, REASON_EFFECT) end
end

function c77777959.efcon(e, tp, eg, ep, ev, re, r, rp)
	return r == REASON_SYNCHRO
end

function c77777959.efop(e, tp, eg, ep, ev, re, r, rp)
	local c = e:GetHandler()
	local rc = c:GetReasonCard()
	-- Destroy S/T card
	local e1 = Effect.CreateEffect(rc)
	e1:SetDescription(aux.Stringid(77777959, 1))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0, 0x1e0)
	e1:SetCountLimit(1)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET + EFFECT_FLAG_CLIENT_HINT)
	e1:SetTarget(c77777959.target)
	e1:SetOperation(c77777959.activate)
	rc:RegisterEffect(e1, true)

	-- Indestructable by effect
	local e5 = Effect.CreateEffect(rc)
	e5:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e5:SetDescription(aux.Stringid(77777959, 2))
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetValue(aux.tgoval)
	rc:RegisterEffect(e5, true)
end

function c77777959.filter(c)
	return c:IsType(TYPE_SPELL + TYPE_TRAP)
end

function c77777959.target(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
	if chkc then return chkc:IsOnField() and c77777959.filter(chkc) and chkc ~= e:GetHandler() end
	if chk == 0 then return Duel.IsExistingTarget(c77777959.filter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_DESTROY)
	local g = Duel.SelectTarget(tp, c77777959.filter, tp, LOCATION_ONFIELD, LOCATION_ONFIELD, 1, 1, e:GetHandler())
	Duel.SetOperationInfo(0, CATEGORY_DESTROY, g, 1, 0, 0)
end

function c77777959.activate(e, tp, eg, ep, ev, re, r, rp)
	local tc = Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Destroy(tc, REASON_EFFECT)
	end
end