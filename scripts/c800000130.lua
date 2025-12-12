--SZS Ichaival - Chris
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon if added from Deck to hand (except by drawing)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon1)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
	--Special Summon instead of sending to GY from hand, then draw 1
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_SEND_REPLACE)
	e2:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	e2:SetCountLimit(1,{id,1})
	c:RegisterEffect(e2)
	--Inflict damage on attack declaration, then discard
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DAMAGE+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_ATTACK_ANNOUNCE)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
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
	--Register if added from Deck to hand (except by draw)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_TO_HAND)
	e5:SetOperation(s.regop1)
	c:RegisterEffect(e5)
	--Register Special Summon for Quick Effect timing
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_SPSUMMON_SUCCESS)
	e6:SetOperation(s.regop2)
	c:RegisterEffect(e6)
end
s.listed_series={0x2406}

--E1: Register when added from Deck to hand (not by draw)
function s.regop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsPreviousLocation(LOCATION_DECK) and not c:IsReason(REASON_DRAW) then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end

--E1: Special Summon condition (if added from Deck except by draw)
function s.spcon1(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:GetFlagEffect(id)>0
end

-----------------------------------------
-- E2: Replacement Effect (from hand → summon instead)
-----------------------------------------
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsLocation(LOCATION_HAND) and c:GetDestination()==LOCATION_GRAVE
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    return Duel.SelectYesNo(tp,aux.Stringid(id,1))
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end

--E3: Damage on attack, then discard
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(ct*500)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*500)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	local d=Duel.Damage(p,ct*500,REASON_EFFECT)
	if d>0 then
		Duel.BreakEffect()
		Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end

--E4: Register Special Summon for Quick Effect condition
function s.regop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then
		e:GetHandler():RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,2)
	end
end

--E4: Quick Synchro/Xyz condition
function s.scxyzcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return e:GetHandler():GetFlagEffect(id+100)>0 and Duel.GetTurnPlayer()==1-tp
		and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2 or ph==PHASE_BATTLE)
		and not Duel.IsPhase(PHASE_DAMAGE)
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
		if tc:IsXyzSummonable(mg) and tc:IsSynchroSummonable(nil,mg) then
			--Both possible, ask which to perform
			if Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
				Duel.SynchroSummon(tp,tc,nil,mg)
			else
				Duel.XyzSummon(tp,tc,mg)
			end
		elseif tc:IsSynchroSummonable(nil,mg) then
			Duel.SynchroSummon(tp,tc,nil,mg)
		else
			Duel.XyzSummon(tp,tc,mg)
		end
	end
end