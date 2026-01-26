--Amazoness Battle Fusion
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Fusion.CreateSummonEff{handler=c,aux.FilterBoolFunction(Card.IsSetCard,0x4),matfilter=Fusion.OnFieldMat,extraop=s.extraop,stage2=s.stage2,extrafil=s.fextra}
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_DESTROY)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	c:RegisterEffect(e1)
    aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_DESTROYED)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end
s.listed_series={0x4}
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:GetFirst()
	local p1=false
	local p2=false
	for tc in aux.Next(eg) do
		if tc:IsType(TYPE_MONSTER) and tc:IsPreviousLocation(LOCATION_MZONE) 
		and tc:IsReason(REASON_BATTLE) and tc:GetPreviousControler()~=tc:GetReasonPlayer() then
				if tc:GetReasonPlayer()==0 then
					p1=true
				else
					p2=true
				end
		end
	end
	if p1 then Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1) end
	if p2 then Duel.RegisterFlagEffect(1,id,RESET_PHASE+PHASE_END,0,1) end
end
function s.filterchk(c)
	return c:IsSetCard(0x4) and c:IsDestructable()
end
function s.fcheck(tp,sg,fc)
	if Duel.GetFlagEffect(tp, id)~=0 then
        return true
    end
end
function s.fextra(e,tp,mg)
	if Duel.GetFlagEffect(tp, id)~=0 then
		local eg=Duel.GetMatchingGroup(Fusion.IsMonsterFilter(s.filterchk),tp,LOCATION_HAND+LOCATION_DECK,0,nil)
		if eg and #eg>0 then
			return eg, s.fcheck
		end
	end
	return nil
end
function s.extraop(e,tc,tp,sg)
	local rg=sg:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_DECK)
	if #rg>0 then
		Duel.Destroy(rg,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		sg:Sub(rg)
	end
end
function s.stage2(e,tc,tp,sg,chk)
	if chk==1 then
        --Cannot be destroyed by battle or card effects
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(3008)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
        e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		tc:RegisterEffect(e2)
    end
end