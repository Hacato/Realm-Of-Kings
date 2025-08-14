--Civilians of The Ashened City
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon from hand if "Obsidim, the Ashened City" is in Field Zone
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.selfspcon)
	c:RegisterEffect(e1)
	
	--Special Summon Cast Tokens when sent from field to GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCondition(s.tkcon)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
end

s.listed_names={03055018,900000029} --Obsidim, the Ashened City and Cast Token

--Condition: "Obsidim, the Ashened City" is in Field Zone
function s.selfspcon(e,c)
	if c==nil then return true end
	return Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,03055018),0,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end

--Condition: Sent from field to GY
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousControler(tp)
end

--Target for Token Summon
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		local ft1=Duel.GetLocationCount(tp,LOCATION_MZONE)
		local ft2=Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)
		return (ft1>0 or ft2>0) and Duel.IsPlayerCanSpecialSummonMonster(tp,900000029,0,TYPES_TOKEN,0,0,1,RACE_PYRO,ATTRIBUTE_DARK)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,0)
end

--Operation: Special Summon Cast Tokens
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,900000029,0,TYPES_TOKEN,0,0,1,RACE_PYRO,ATTRIBUTE_DARK) then return end
	
	local ft1=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local ft2=Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)
	
	if ft1+ft2<=0 then return end
	
	--Determine how many tokens can be summoned (max 2 total)
	local max=math.min(2,ft1+ft2)
	
	--Ask how many tokens to summon
	local count=1
	if max>1 then
		local options={}
		for i=1,max do
			table.insert(options,i)
		end
		count=Duel.AnnounceNumber(tp,table.unpack(options))
	end
	
	--Distribute tokens between fields
	for i=1,count do
		local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		local b2=Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)>0
		
		local p=tp
		if b1 and b2 then
			p=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))==0 and tp or 1-tp
		elseif b2 then
			p=1-tp
		end
		
		local token=Duel.CreateToken(tp,900000029)
		if Duel.SpecialSummonStep(token,0,tp,p,false,false,POS_FACEUP) then
			--Cannot be destroyed by card effects
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CLIENT_HINT)
			e1:SetDescription(aux.Stringid(id,4))
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			token:RegisterEffect(e1,true)
			
			--When this token leaves the field, its controller must destroy 1 card
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_LEAVE_FIELD)
			e2:SetOperation(s.destroyop)
			token:RegisterEffect(e2,true)
		end
	end
	Duel.SpecialSummonComplete()
end

--Operation when token leaves field - controller destroys 1 card
function s.destroyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local p=c:GetPreviousControler()
	local dg=Duel.GetMatchingGroup(s.desfilter,p,LOCATION_HAND+LOCATION_ONFIELD,0,nil)
	if #dg>0 then
		Duel.Hint(HINT_CARD,0,900000029)
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_DESTROY)
		local sg=dg:Select(p,1,1,nil)
		Duel.Destroy(sg,REASON_EFFECT)
	end
	e:Reset()
end

--Filter: Cards that can be destroyed (exclude tokens)
function s.desfilter(c)
	return not c:IsType(TYPE_TOKEN)
end