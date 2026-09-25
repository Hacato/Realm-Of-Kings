-- Grayshade the Phantom of Grayscale
-- Scripted by Youware CLI
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon (2+ Level 8, incl. a LIGHT Fiend among materials)
	Xyz.AddProcedure(c,nil,8,2,nil,nil,Xyz.InfiniteMats)
	c:EnableReviveLimit()
	-- Material check: ensure at least 1 LIGHT Fiend used
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_MATERIAL_CHECK)
	e0:SetValue(s.matcheck)
	c:RegisterEffect(e0)
	local e0b=Effect.CreateEffect(c)
	e0b:SetType(EFFECT_TYPE_SINGLE)
	e0b:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0b:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0b:SetValue(s.splimit)
	e0b:SetLabelObject(e0)
	c:RegisterEffect(e0b)
	-- Cannot be Link Material except for a "Grayscale" Link Monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetValue(s.linklimit)
	c:RegisterEffect(e1)
	-- Quick Effect: rewrite opponent's Spell/Trap activation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.chcon)
	e2:SetCost(s.chcost)
	e2:SetOperation(s.chop)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT)
	-- End Phase: detach 2, add 1 "Grayscale" from GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
end
s.listed_series={0x2410}
function s.mfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_FIEND)
end
function s.matcheck(e,c)
	local g=c:GetMaterial()
	if g and g:IsExists(s.mfilter,1,nil) then
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
end
function s.splimit(e,se,sp,st)
	if st&SUMMON_TYPE_XYZ==SUMMON_TYPE_XYZ then
		return e:GetLabelObject():GetLabel()==1
	end
	return true
end
function s.linklimit(e,lc,sumtype,tp)
	return not (lc and lc:IsSetCard(0x2410))
end
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsHasType(EFFECT_TYPE_ACTIVATE) and re:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end
function s.chcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.spellfilter(c)
	return c:IsType(TYPE_SPELL)
end
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2410) and c:IsType(TYPE_XYZ)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spellfilter),tp,LOCATION_GRAVE,LOCATION_GRAVE,nil)
	if #g==0 then return end
	local p=rp -- the activator of the original Spell/Trap
	Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TARGET)
	local sg=g:Select(p,1,1,nil)
	if #sg==0 then return end
	Duel.HintSelection(sg)
	if Duel.IsExistingMatchingCard(s.xyzfilter,p,LOCATION_MZONE,0,1,nil) and Duel.SelectYesNo(p,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_FACEUP)
		local cg=Duel.SelectMatchingCard(p,s.xyzfilter,p,LOCATION_MZONE,0,1,1,nil)
		local tc=cg:GetFirst()
		if tc then Duel.Overlay(tc,sg) end
	end
end
function s.chop(e,tp,eg,ep,ev,re,r,rp)
	local ng=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,ng)
	Duel.ChangeChainOperation(ev,s.repop)
end
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end
function s.thfilter(c)
	return c:IsSetCard(0x2410) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end