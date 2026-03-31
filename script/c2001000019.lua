--虐殺の母 
--Hallow Mother of Abominations
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --Contact Fusion Procedure
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    --Non-Hallowfall monsters lose ATK
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e2:SetTarget(s.atktg)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)
    --Banish Substitute
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(id)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(1,0)
    e3:SetCountLimit(1, id)
    e3:SetCondition(s.repcon)
    e3:SetValue(s.repval)
    e3:SetOperation(s.repop)
    c:RegisterEffect(e3)
end

s.listed_series={0x77b}
s.listed_names={2001000001,2001000007} --Hallowfall of the Gildentree, Lady Hallowfall

function s.spfilter1(c)
	return c:IsCode(2001000001) and c:IsAbleToGraveAsCost() and c:IsFaceup() and c:IsOnField()
end

function s.spfilter2(c)
	return c:IsCode(2001000007) and c:IsAbleToGraveAsCost() and c:IsFaceup() and c:IsOnField()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_ONFIELD,0,nil)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_MZONE,0,nil)
	local g=aux.SelectUnselectGroup(g1+g2,e,tp,2,2,aux.dncheck,1,tp,HINTMSG_TOGRAVE)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoGrave(g,REASON_COST+REASON_MATERIAL)
	g:DeleteGroup()
end

function s.atktg(e,c)
	return not c:IsSetCard(0x77b)
end

function s.atkfilter(c)
	return c:IsSetCard(0x77b) and c:IsSpellTrap()
end

function s.atkval(e,c)
	if not c then return 0 end
	local tp=e:GetHandlerPlayer()
	local ct=Duel.GetMatchingGroupCount(s.atkfilter,tp,LOCATION_REMOVED,0,nil)
	return ct*-100
end

function s.repcfilter(c,tp)
    -- First, check if this is a valid card to banish
    if not c:IsAbleToRemoveAsCost() then return false end
    
    -- For Light Crest's effect (ID: 2001000016), protect the last negatable monster
    if Duel.GetCurrentChain()>0 then
        local ce=Duel.GetChainInfo(Duel.GetCurrentChain(),CHAININFO_TRIGGERING_EFFECT)
        if ce and ce:GetHandler():IsCode(2001000016) then
            -- Count negatable monsters
            local negatables=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsNegatable),tp,0,LOCATION_MZONE,nil)
            if #negatables<=1 and c:IsLocation(LOCATION_MZONE) and c:IsNegatable() then
                return false
            end
        end
    end
    return true
end

function s.repcon(e)
    local tp=e:GetHandlerPlayer()
    return Duel.IsExistingMatchingCard(s.repcfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil,tp)
end

function s.repval(base,e,tp,eg,ep,ev,re,r,rp,chk,extracon)
    local c=e:GetHandler()
    return c and c:IsSetCard(0x77b) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsLocation(LOCATION_GRAVE)
end

function s.repop(base,e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.repcfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil,tp)
    if #g>0 then
        Duel.Remove(g,POS_FACEUP,REASON_COST+REASON_REPLACE)
    end
end