--Lunar Eclipse Celestial Venom Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as "Starving Venom"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x1050)
	c:RegisterEffect(e0)
	
	--Pendulum Procedure
	Pendulum.AddProcedure(c)
	
	--Pendulum Effect 1: Summon restriction
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	
	--Pendulum Effect 2: Fusion Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.fuscon)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)
	
	--Pendulum Effect 3: Battle damage redirect
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCondition(s.damcon)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
	
	--Monster Effect: Cannot Normal Summon/Set
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e4:SetCode(EFFECT_SPSUMMON_CONDITION)
	e4:SetValue(s.splimmon)
	c:RegisterEffect(e4)
	
	--Monster Effect: Fusion Material restriction
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e5:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e5:SetValue(s.fuslimit)
	c:RegisterEffect(e5)
	
	--Monster Effect 1: Fusion Spell effect
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,2))
	e6:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e6:SetCountLimit(1,{id,2})
	e6:SetTarget(s.spelltg)
	e6:SetOperation(s.spellop)
	c:RegisterEffect(e6)
	
	--Monster Effect 2: Special Summon on leave field
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,3))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetProperty(EFFECT_FLAG_DELAY)
	e7:SetCode(EVENT_TO_GRAVE)
	e7:SetCountLimit(1,{id,3})
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e8)
	local e9=e7:Clone()
	e9:SetCode(EVENT_CUSTOM+90000001)
	c:RegisterEffect(e9)
	
	--Register when added to Extra Deck face-up
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e10:SetCode(EVENT_TO_DECK)
	e10:SetCondition(s.regcon)
	e10:SetOperation(s.regop)
	c:RegisterEffect(e10)
end

s.listed_names={CARD_POLYMERIZATION}
s.listed_series={0xf8,0x04B2,0x1050,0x14B2}

--Pendulum restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	if c:IsAttribute(ATTRIBUTE_LIGHT+ATTRIBUTE_DARK) then return false end
	return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Fusion Summon condition
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(nil,tp,LOCATION_PZONE,0,1,e:GetHandler())
end

--Fusion filter
function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) and (c:IsSetCard(0xf8) or c:IsSetCard(0x04B2))
end

--Extra fusion materials
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsFaceup,Card.IsAbleToDeck),tp,LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA,0,nil)
end

--Extra target declaration
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local params = {fusfilter=s.fusfilter,matfilter=Fusion.OnFieldMat(Card.IsAbleToDeck),extrafil=s.fextra,extraop=Fusion.ShuffleMaterial,extratg=s.extratg}
		return Fusion.SummonEffTG(params)(e,tp,eg,ep,ev,re,r,rp,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED|LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local params = {fusfilter=s.fusfilter,matfilter=Fusion.OnFieldMat(Card.IsAbleToDeck),extrafil=s.fextra,extraop=Fusion.ShuffleMaterial,extratg=s.extratg}
	Fusion.SummonEffOP(params)(e,tp,eg,ep,ev,re,r,rp)
end

--Battle damage redirect condition
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	if ep~=tp or ev<=0 or e:GetHandler():HasFlagEffect(id+1) then return false end
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a or not d then return false end
	local bc=nil
	-- Check if attacking monster is yours and qualifies
	if a:IsControler(tp) then
		if a:IsSetCard(0x04B2) or a:IsSetCard(0x50) then -- Eclipse or Venom (any type)
			bc=a
		elseif a:IsSetCard(0xf8) and a:IsType(TYPE_FUSION) then -- Supreme King Fusion
			bc=a
		end
	end
	-- Check if defending monster is yours and qualifies
	if not bc and d and d:IsControler(tp) then
		if d:IsSetCard(0x04B2) or d:IsSetCard(0x50) then -- Eclipse or Venom (any type)
			bc=d
		elseif d:IsSetCard(0xf8) and d:IsType(TYPE_FUSION) then -- Supreme King Fusion
			bc=d
		end
	end
	return bc~=nil
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,1)) then
		c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
		Duel.Hint(HINT_CARD,0,id)
		Duel.ChangeBattleDamage(tp,0)
		Duel.Damage(1-tp,ev,REASON_EFFECT)
	end
end

--Monster summon limit
function s.splimmon(e,se,sp,st)
	return (st&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Fusion Material limit
function s.fuslimit(e,c,sumtype)
	if not c then return false end
	return not (c:IsSetCard(0x1050) or c:IsSetCard(0xf8) or c:IsSetCard(0x04B2))
end

--Spell effect filter
function s.spellfilter(c)
	return (c:IsCode(CARD_POLYMERIZATION) or aux.IsCodeListed(c,CARD_POLYMERIZATION)) 
		and c:IsType(TYPE_SPELL) and c:IsAbleToDeck()
end

function s.spelltg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.spellfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.spellfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.spellfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
end

function s.spellop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 
		and tc:IsLocation(LOCATION_DECK) then
		local te=tc:GetActivateEffect()
		if te then
			local tg=te:GetTarget()
			local op=te:GetOperation()
			e:SetCategory(te:GetCategory())
			e:SetProperty(te:GetProperty())
			Duel.ClearTargetCard()
			if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
			Duel.BreakEffect()
			if op then op(e,tp,eg,ep,ev,re,r,rp) end
		end
	end
end

--Special Summon filter
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x14B2) and c:IsType(TYPE_PENDULUM) and c:IsLevel(5)
		and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end

--Register Extra Deck face-up condition
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)
end

--Register Extra Deck face-up
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RaiseSingleEvent(e:GetHandler(),EVENT_CUSTOM+90000001,e,0,tp,tp,0)
end