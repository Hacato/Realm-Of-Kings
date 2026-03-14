--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --activate
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SETCARD_YUYUYU}
s.listed_names={YUYUYU_TOKEN}
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanSpecialSummonMonster(tp,YUYUYU_TOKEN,SETCARD_YUYUYU,TYPES_TOKEN,0,0,3,RACE_FAIRY,ATTRIBUTE_LIGHT) 
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(YuYuYu.RitualMonsterCheckFilter,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,6,e,tp) end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,ft,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,ft,tp,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 or not Duel.IsPlayerCanSpecialSummonMonster(tp,YUYUYU_TOKEN,SETCARD_YUYUYU,TYPES_TOKEN,0,0,3,RACE_FAIRY,ATTRIBUTE_LIGHT) then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	local fid=c:GetFieldID()
	local g=Group.CreateGroup()
	for i=1,ft do
		local token=Duel.CreateToken(tp,YUYUYU_TOKEN)
		Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		token:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1,fid)
		g:AddCard(token)
	end
	Duel.SpecialSummonComplete()
	g:KeepAlive()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCountLimit(1)
	e1:SetLabel(fid)
	e1:SetLabelObject(g)
	e1:SetCondition(s.descon)
	e1:SetOperation(s.desop)
	Duel.RegisterEffect(e1,tp)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e4:SetTargetRange(1,0)
	e4:SetTarget(s.splimit)
	e4:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e4,tp)
	YuYuYu.RitualOperation(e,tp,6,LOCATION_HAND+LOCATION_EXTRA,false)
	if YuYuYu.RitualCheck(e,tp,6,LOCATION_HAND+LOCATION_EXTRA,false) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.BreakEffect()
		YuYuYu.RitualOperation(e,tp,6,LOCATION_HAND+LOCATION_EXTRA,false)
	end
end
function s.desfilter(c,fid)
	return c:GetFlagEffectLabel(id)==fid
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	if not g:IsExists(s.desfilter,1,nil,e:GetLabel()) then
		g:DeleteGroup()
		e:Reset()
		return false
	else return true end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()
	local tc=g:Filter(s.desfilter,nil,e:GetLabel())
	Duel.Destroy(tc,REASON_EFFECT)
end
function s.relval(e,c)
    local rc=c:GetReasonCard()
    return not (rc and rc:IsType(TYPE_RITUAL) and rc:IsSetCard(SETCARD_YUYUYU))
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:IsSetCard(SETCARD_YUYUYU) and c:IsType(TYPE_PENDULUM) and c:IsFaceup()) and c:IsLocation(LOCATION_EXTRA)
end
Duel.LoadScript("yuyuyu-utility.lua")