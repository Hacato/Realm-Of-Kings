--Qliphort Updater
--Scripted by: Assistant
local s,id=GetID()
function s.initial_effect(c)
	--Pendulum Summon
	Pendulum.AddProcedure(c)
	--Pendulum Effects
	--Restrict to Pendulum Summon Qli only
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.pslimit)
	c:RegisterEffect(e1)
	--Register player flag effect (Pendulum)
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_FIELD)
	e1b:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1b:SetCode(id)
	e1b:SetRange(LOCATION_PZONE)
	e1b:SetTargetRange(1,0)
	c:RegisterEffect(e1b)
	--Modify other Qli pendulum effects (Pendulum)
	local e1c=Effect.CreateEffect(c)
	e1c:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1c:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1c:SetCode(EVENT_ADJUST)
	e1c:SetRange(LOCATION_PZONE)
	e1c:SetOperation(s.adjustop)
	c:RegisterEffect(e1c)
	--Grant effect to Qli monsters in hand
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_PZONE)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetTarget(s.eftg)
	e2:SetLabelObject(s.GrantedEffect(c))
	c:RegisterEffect(e2)
	--Change Pendulum Scale to 9
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.sccon)
	e3:SetOperation(s.scop)
	c:RegisterEffect(e3)
	--Monster Effects
	--Restrict to Pendulum Summon Qli only (Monster version)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(1,0)
	e4:SetTarget(s.pslimit)
	c:RegisterEffect(e4)
	--Register player flag effect (Monster)
	local e4b=Effect.CreateEffect(c)
	e4b:SetType(EFFECT_TYPE_FIELD)
	e4b:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e4b:SetCode(id)
	e4b:SetRange(LOCATION_MZONE)
	e4b:SetTargetRange(1,0)
	c:RegisterEffect(e4b)
	--Modify other Qli pendulum effects (Monster)
	local e4c=Effect.CreateEffect(c)
	e4c:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4c:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e4c:SetCode(EVENT_ADJUST)
	e4c:SetRange(LOCATION_MZONE)
	e4c:SetOperation(s.adjustop)
	c:RegisterEffect(e4c)
	--Set Qli Spell/Trap when Special Summoned or Tributed
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetCountLimit(1,id)
	e5:SetTarget(s.settg)
	e5:SetOperation(s.setop)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EVENT_RELEASE)
	c:RegisterEffect(e6)
	--Add from Extra Deck during Standby Phase
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_TOHAND)
	e7:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e7:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e7:SetRange(LOCATION_EXTRA)
	e7:SetCountLimit(1)
	e7:SetCondition(s.thcon)
	e7:SetTarget(s.thtg)
	e7:SetOperation(s.thop)
	c:RegisterEffect(e7)
end
s.listed_series={0xaa}

--Pendulum Effects
function s.pslimit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsSetCard(0xaa) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Grant target: Qli monsters in hand
function s.eftg(e,c)
	return c:IsSetCard(0xaa) and c:IsMonster()
end

--The effect that will be granted to Qli monsters in hand
function s.GrantedEffect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ADD_EXTRA_TRIBUTE)
	e1:SetTargetRange(LOCATION_SZONE,0)
	e1:SetTarget(s.extratg)
	e1:SetValue(POS_FACEUP)
	return e1
end

--Target for extra tribute: Face-up Qli cards in Pendulum Zones
function s.extratg(e,c)
	return c:IsSetCard(0xaa) and c:IsFaceup() and c:IsType(TYPE_PENDULUM)
end

--Modify other Qli monsters' restrictions
function s.qlistochange(c)
	return c:IsSetCard(0xaa) and c:IsFaceup() and not c:HasFlagEffect(id)
end

function s.qlinewsplimit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsSetCard(0xaa) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.qlistochange,tp,LOCATION_PZONE,0,nil)
	if #g==0 then return end
	for qli_card in g:Iter() do
		local effs={qli_card:GetCardEffect(EFFECT_CANNOT_SPECIAL_SUMMON)}
		for _,eff in ipairs(effs) do
			if eff:GetOwner()==qli_card and (eff:GetProperty()&EFFECT_FLAG_PLAYER_TARGET)>0 and not qli_card:HasFlagEffect(id) then
				qli_card:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
				local orig_con=eff:GetCondition()
				if not orig_con then orig_con=aux.TRUE end
				--Disable the default effect when player is affected by Updater
				eff:SetCondition(function(e,...) 
					return not Duel.IsPlayerAffectedByEffect(tp,id) and orig_con(e,...)
				end)
				--Create new Pendulum-only restriction
				local new_eff=eff:Clone()
				new_eff:SetCondition(function(e,...) 
					return Duel.IsPlayerAffectedByEffect(tp,id) and orig_con(e,...)
				end)
				new_eff:SetTarget(s.qlinewsplimit)
				new_eff:SetReset(RESET_EVENT|RESETS_STANDARD)
				qli_card:RegisterEffect(new_eff)
			end
		end
	end
end

function s.scconfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xaa)
end
function s.sccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.scconfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler())
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LSCALE)
	e1:SetValue(9)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CHANGE_RSCALE)
	c:RegisterEffect(e2)
end

--Monster Effects
function s.setfilter(c)
	return c:IsSetCard(0xaa) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and e:GetHandler():IsFaceup()
end
function s.retfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xaa) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() 
		and Duel.IsExistingMatchingCard(s.retfilter,tp,LOCATION_ONFIELD,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	if Duel.SendtoHand(c,nil,REASON_EFFECT)>0 and c:IsLocation(LOCATION_HAND) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local g=Duel.SelectMatchingCard(tp,s.retfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
		end
	end
end