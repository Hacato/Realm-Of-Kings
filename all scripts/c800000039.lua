--Aquamarine Bubble Colony
--Scripted by Hacato & Astra
local s,id=GetID()
function s.initial_effect(c)
	--Must be properly summoned
	c:EnableReviveLimit()
	-- (Optional) Standard Fusion: 2+ "Aquamarine" monsters (set 0x30cd)
	-- Note: the generic Fusion proc does NOT enforce "different names"
	Fusion.AddProcFunRep(c, s.fusfilter, 2, 99, true)

	-- Unique on field (you can only control 1)
	c:SetUniqueOnField(1,0,id)

	-- Special Summon from Extra by banishing materials with different names from GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Cannot be destroyed by battle while you control another "Aquamarine" monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.indcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	-- Aura: Extra attacks for each "Aquamarine" Fusion you control
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.exatk_tg)
	e3:SetValue(s.exatk_val)
	c:RegisterEffect(e3)
end

-- ===== Helpers =====
function s.fusfilter(c,fc,sub,mg,sg,contact)
	return c:IsSetCard(0x30cd)
end

-- GY SS Proc: need 2+ "Aquamarine" monsters with different names
function s.gyfilter(c)
	return c:IsSetCard(0x30cd) and c:IsMonster() and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	-- Need at least 2 different names
	return #g>=2 and g:GetClassCount(Card.GetCode)>=2
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	-- Select 2 to 99 with all different names
	aux.GCheckAdditional=aux.dncheck
	local sg=aux.SelectUnselectGroup(g,e,tp,2,math.min(99,#g),aux.dncheck,1,tp,HINTMSG_REMOVE)
	aux.GCheckAdditional=nil
	if not sg then return false end
	sg:KeepAlive()
	e:SetLabelObject(sg)
	return true
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	Duel.Remove(sg,POS_FACEUP,REASON_COST)
	sg:DeleteGroup()
end

-- Indestructible by battle while you control another "Aquamarine" monster
function s.indcon(e)
	local c=e:GetHandler()
	return Duel.IsExistingMatchingCard(s.indfilter,c:GetControler(),LOCATION_MZONE,0,1,c)
end
function s.indfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd)
end

-- Extra attack aura
-- Target: each "Aquamarine" Fusion monster you control (including itself)
function s.exatk_tg(e,c)
	return c:IsFaceup() and c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION)
end
-- Value: extra attacks = (#distinct names among OTHER "Aquamarine" Fusion you control, excluding this card) - 1
-- Also excludes any "Aquamarine Bubble Colony" from the count (per card text)
function s.exatk_val(e,c)
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(function(tc)
		return tc:IsFaceup() and tc:IsSetCard(0x30cd) and tc:IsType(TYPE_FUSION) and tc~=c and not tc:IsCode(id)
	end,tp,LOCATION_MZONE,0,nil)
	-- Count distinct names among those others
	local distinct=g:GetClassCount(Card.GetCode)
	-- Total attacks allowed = distinct
	-- EDOPro needs "extra" attacks, so subtract 1 (min 0)
	if distinct<=1 then return 0 end
	return distinct-1
end
