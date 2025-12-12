--SZS Airgetlam - Maria
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon if you Normal/Special Summoned 2 "SZS" monsters with different names this turn
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon1)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
	--Track Normal/Special Summons of "SZS" monsters
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
		local ge2=ge1:Clone()
		ge2:SetCode(EVENT_SPSUMMON_SUCCESS)
		Duel.RegisterEffect(ge2,0)
	end)
	--Special Summon instead of sending to GY from hand, then draw 1
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_SEND_REPLACE)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	e2:SetCountLimit(1,{id,1})
	c:RegisterEffect(e2)
	--Special Summon "SZS" monster when opponent Special Summons
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.spcon2)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	e3:SetCountLimit(1,{id,2})
	c:RegisterEffect(e3)
	--Quick Synchro/Xyz Summon during opponent's Main/Battle Phase
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetHintTiming(TIMING_BATTLE_PHASE+TIMING_MAIN_END,TIMING_BATTLE_PHASE+TIMING_MAIN_END)
	e4:SetCondition(s.scxyzcon)
	e4:SetTarget(s.scxyztg)
	e4:SetOperation(s.scxyzop)
	e4:SetCountLimit(1)
	c:RegisterEffect(e4)
	--Register Special Summon for Quick Effect timing
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetOperation(s.regop)
	c:RegisterEffect(e5)
end
s.listed_series={0x2406}

--E1: Track "SZS" monster summons
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	for tc in aux.Next(eg) do
		if tc:IsSetCard(0x2406) and tc:IsFaceup() then
			local p=tc:GetSummonPlayer()
			if Duel.GetFlagEffect(p,id)==0 then
				Duel.RegisterFlagEffect(p,id,RESET_PHASE+PHASE_END,0,1)
				Duel.RegisterFlagEffect(p,id+100,RESET_PHASE+PHASE_END,0,1,tc:GetCode())
			else
				local code=Duel.GetFlagEffectLabel(p,id+100)
				if code~=tc:GetCode() then
					Duel.RegisterFlagEffect(p,id+200,RESET_PHASE+PHASE_END,0,1)
				end
			end
		end
	end
end

--E1: Special Summon condition (2 different "SZS" monsters summoned)
function s.spcon1(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.GetFlagEffect(tp,id+200)>0
end

--E2: Replacement effect - Special Summon instead of going to GY
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsLocation(LOCATION_HAND) and c:GetDestination()==LOCATION_GRAVE
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	return Duel.SelectYesNo(tp,aux.Stringid(id,1))
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end

--E3: Quick Special Summon when opponent Special Summons
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2406) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end

--E4: Register Special Summon for Quick Effect condition
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then
		e:GetHandler():RegisterFlagEffect(id+300,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
	end
end

--E4: Quick Synchro/Xyz condition
function s.scxyzcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return e:GetHandler():GetFlagEffect(id+300)>0 and Duel.GetTurnPlayer()==1-tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE)
end

--E4: Filter for "SZS" Extra Deck monsters
function s.szsfilter(c)
	return c:IsSetCard(0x2406)
end

--E4: Quick Synchro/Xyz target
function s.scxyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
		if not mg:IsContains(c) then return false end
		local g=Duel.GetMatchingGroup(s.szsfilter,tp,LOCATION_EXTRA,0,nil)
		if g:IsExists(Card.IsSynchroSummonable,1,nil,nil,mg) then return true end
		if g:IsExists(Card.IsXyzSummonable,1,nil,mg) then return true end
		return false
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--E4: Quick Synchro/Xyz operation
function s.scxyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsControler(1-tp) or c:IsFacedown() then return end
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	if not mg:IsContains(c) then return end
	local g=Duel.GetMatchingGroup(s.szsfilter,tp,LOCATION_EXTRA,0,nil)
	local sg1=g:Filter(Card.IsSynchroSummonable,nil,nil,mg)
	local sg2=g:Filter(Card.IsXyzSummonable,nil,mg)
	sg1:Merge(sg2)
	if #sg1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=sg1:Select(tp,1,1,nil):GetFirst()
		if tc:IsSynchroSummonable(nil,mg) 
			and (not tc:IsXyzSummonable(mg) or Duel.SelectYesNo(tp,aux.Stringid(id,4)))
		then
			Duel.SynchroSummon(tp,tc,nil,mg)
		else
			Duel.XyzSummon(tp,tc,mg)
		end
	end
end