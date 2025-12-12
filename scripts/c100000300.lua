--Galaxy-Eyes Cipher Expansion Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,nil,10,3)
	c:EnableReviveLimit()
	
	--Alternate Xyz Summon with Cipher Dragon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.xyzcon)
	e1:SetTarget(s.xyztg)
	e1:SetOperation(s.xyzop)
	e1:SetValue(SUMMON_TYPE_XYZ)
	e1:SetCountLimit(1,{id,1})
	c:RegisterEffect(e1)
	
	--Protection
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetCondition(s.protcon)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)
	
	--Negate and take control
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_NEGATE+CATEGORY_CONTROL)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.negcon)
	e4:SetCost(s.negcost)
	e4:SetTarget(s.negtg)
	e4:SetOperation(s.negop)
	c:RegisterEffect(e4)
end

--Functions for alternate Xyz Summon
function s.xyzfilter(c,tp,xyzc)
	return c:IsFaceup() and c:IsSetCard(0x10e5) and c:IsType(TYPE_XYZ) and c:IsCanBeXyzMaterial(xyzc,tp)
end

function s.xyzcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	local pg=aux.GetMustBeMaterialGroup(tp,Group.CreateGroup(),tp,c,nil,REASON_XYZ)
	return #pg<=0 and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,tp,c)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,tp,c)
	if #g>0 then
		local mg=g:GetFirst():GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(c,mg)
		end
		g:GetFirst():CancelToGrave()
		Duel.Overlay(c,g)
		return true
	end
	return false
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	--Nothing needed here as we handled everything in xyztg
end

--Protection condition
function s.protcon(e)
	return e:GetHandler():GetOverlayCount()>0
end

--Functions for negate and take control effect
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev) and rp==1-tp
end

function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	
	local rc=re:GetHandler()
	if rc:IsOnField() and rc:IsRelateToEffect(re) and rc:IsControlerCanBeChanged() then
		Duel.SetOperationInfo(0,CATEGORY_CONTROL,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=re:GetHandler()
	
	if Duel.NegateActivation(ev) and rc:IsOnField() and rc:IsRelateToEffect(re) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		if Duel.GetControl(rc,tp) then
			--Negate effects
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e2)
			
			--Change ATK to 4200
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SET_ATTACK_FINAL)
			e3:SetValue(4200)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e3)
			
			--Change name to "Galaxy-Eyes Cipher Expansion Dragon"
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_CHANGE_CODE)
			e4:SetValue(id)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			rc:RegisterEffect(e4)
		end
	end
end