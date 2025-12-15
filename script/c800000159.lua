--Pursuer of Justice - Myrrh the Great Dragon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Summon procedure: 5 "Pursuer of Justice" monsters with different names
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetCondition(s.fuscon)
	e0:SetOperation(s.fusop)
	c:RegisterEffect(e0)
	--Cannot Special Summon except "Pursuer of Justice" monsters (cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	--Opponent can only activate 1 Spell/Trap per turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.actlimit)
	c:RegisterEffect(e2)
	--Banish 1 opponent's card when Fusion Summoned
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.rmcon)
	e3:SetTarget(s.rmtg)
	e3:SetOperation(s.rmop)
	c:RegisterEffect(e3)
	--Banish 5 cards from Deck and Special Summon next Standby Phase
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id+100)
	e4:SetTarget(s.bantg)
	e4:SetOperation(s.banop)
	c:RegisterEffect(e4)
	--Limit to 1
	c:SetUniqueOnField(1,0,id)
end
s.listed_series={0x816}

--Fusion material filter
function s.ffilter(c,fc,sub,mg,sg)
	return c:IsSetCard(0x816) and (not sg or not sg:IsExists(Card.IsCode,1,c,c:GetCode()))
end

--Fusion condition
function s.fuscon(e,g,gc,chkf)
	if g==nil then return true end
	local c=e:GetHandler()
	local mg=g:Filter(s.ffilter,nil,c,false,nil,nil)
	if gc then
		if not mg:IsContains(gc) then return false end
		local sg=Group.CreateGroup()
		return s.fuscheck(mg,sg,gc,5,chkf,c)
	end
	local sg=Group.CreateGroup()
	return s.fuscheck(mg,sg,nil,5,chkf,c)
end

function s.fuscheck(mg,sg,gc,ct,chkf,fc)
	if ct==0 then
		return sg:GetClassCount(Card.GetCode)==5 and (not gc or sg:IsContains(gc)) 
			and Duel.GetLocationCountFromEx(0,0,sg,fc)>0
	end
	local res=false
	for tc in aux.Next(mg) do
		if not sg:IsExists(Card.IsCode,1,nil,tc:GetCode()) then
			sg:AddCard(tc)
			res=s.fuscheck(mg,sg,gc,ct-1,chkf,fc)
			sg:RemoveCard(tc)
			if res then return true end
		end
	end
	return false
end

--Fusion operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
	local c=e:GetHandler()
	local mg=eg:Filter(s.ffilter,nil,c,false,nil,nil)
	local sg=Group.CreateGroup()
	for i=1,5 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local tc=mg:FilterSelect(tp,s.matcheck,1,1,nil,sg,gc,i==5):GetFirst()
		sg:AddCard(tc)
		if gc and tc==gc then gc=nil end
	end
	Duel.SetFusionMaterial(sg)
end

function s.matcheck(c,sg,gc,last)
	if sg:IsExists(Card.IsCode,1,nil,c:GetCode()) then return false end
	if last then
		sg:AddCard(c)
		local res=(not gc or sg:IsContains(gc))
		sg:RemoveCard(c)
		return res
	end
	return true
end

--Cannot Special Summon except "Pursuer of Justice" monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsSetCard(0x816)
end

--Spell/Trap activation limit
function s.actlimit(e,re,tp)
	local rc=re:GetHandler()
	if not re:IsHasType(EFFECT_TYPE_ACTIVATE) or not rc:IsType(TYPE_SPELL+TYPE_TRAP) then return false end
	if Duel.GetFlagEffect(1-e:GetHandlerPlayer(),id)==0 then
		Duel.RegisterFlagEffect(1-e:GetHandlerPlayer(),id,RESET_PHASE+PHASE_END,0,1)
		return false
	end
	return true
end

--Banish condition: Fusion Summoned
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

--Banish target
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

--Banish operation
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
	end
end

--Banish from Deck target
function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=5 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,5,tp,LOCATION_DECK)
end

--Banish from Deck operation
function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetDecktopGroup(tp,5)
	if #g==5 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)==5 then
		--Special Summon during next Standby Phase
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
		e1:SetCountLimit(1)
		e1:SetLabel(Duel.GetTurnCount())
		e1:SetCondition(s.spcon2)
		e1:SetOperation(s.spop2)
		e1:SetReset(RESET_PHASE+PHASE_STANDBY,2)
		Duel.RegisterEffect(e1,tp)
		c:RegisterFlagEffect(id+200,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY,0,2)
		e1:SetLabelObject(c)
	end
end

--Special Summon condition: next Standby Phase
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	return Duel.GetTurnCount()~=e:GetLabel() and Duel.GetTurnPlayer()==tp
		and c and c:GetFlagEffect(id+200)>0
end

--Special Summon operation
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetLabelObject()
	if c and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end