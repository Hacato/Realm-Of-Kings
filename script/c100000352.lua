--Lunar Eclipse Supreme Scarlet Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Pendulum procedure
	Pendulum.AddProcedure(c)

	--Always treated as "Odd-Eyes"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x99)
	c:RegisterEffect(e0)

	--Pendulum Effects

	--You cannot Pendulum Summon monsters, except DARK and LIGHT monsters. This effect cannot be negated.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)

	--The first time each DARK or LIGHT Dragon/Cyberse Ritual/Fusion/Synchro/Xyz/Pendulum/Link Monster would be destroyed each turn, it is not destroyed.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e2:SetRange(LOCATION_PZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.indestg)
	e2:SetValue(s.indesval)
	c:RegisterEffect(e2)

	--If you have no cards in your other Pendulum Zone: place 1 "Eclipse", "Odd-Eyes" or "Magician" Pendulum from Deck or face-up Extra Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCondition(s.plcon)
	e3:SetTarget(s.pltg)
	e3:SetOperation(s.plop)
	c:RegisterEffect(e3)

	--If this card in the Pendulum Zone is destroyed: Special Summon 1 "Odd-Eyes", "Supreme King" or "Eclipse" monster
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg1)
	e4:SetOperation(s.spop1)
	e4:SetCountLimit(1,id)
	c:RegisterEffect(e4)

	--If this card in the Pendulum Zone is banished: Special Summon 1 "Odd-Eyes", "Supreme King" or "Eclipse" monster
	local e5=e4:Clone()
	e5:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e5)

	--Monster Effects

	--Ritual Level
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e6:SetCode(EFFECT_RITUAL_LEVEL)
	e6:SetValue(s.rlevel)
	c:RegisterEffect(e6)

	--Must first be Ritual Summoned
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_SINGLE)
	e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e7:SetCode(EFFECT_SPSUMMON_CONDITION)
	e7:SetValue(s.splimit2)
	c:RegisterEffect(e7)

	--Double battle damage
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e8:SetValue(aux.ChangeBattleDamage(1,DOUBLE_DAMAGE))
	c:RegisterEffect(e8)

	--Special Summon monster destroyed by battle
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,2))
	e9:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e9:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e9:SetCode(EVENT_BATTLE_DESTROYING)
	e9:SetCondition(aux.bdcon)
	e9:SetTarget(s.sptg2)
	e9:SetOperation(s.spop2)
	e9:SetCountLimit(1,{id,1})
	c:RegisterEffect(e9)
end

s.listed_names={id}
s.listed_series={0x04B2,0x99,0xa2,0xf8} --Eclipse, Odd-Eyes, Magician, Supreme King

--Pendulum Summon restriction
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
		and not (c:IsAttribute(ATTRIBUTE_DARK) or c:IsAttribute(ATTRIBUTE_LIGHT))
end

--Protection target
function s.indestg(e,c)
	return (c:IsRace(RACE_DRAGON) or c:IsRace(RACE_CYBERSE))
		and (c:IsAttribute(ATTRIBUTE_DARK) or c:IsAttribute(ATTRIBUTE_LIGHT))
		and (c:IsType(TYPE_RITUAL) or c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO)
			or c:IsType(TYPE_XYZ) or c:IsType(TYPE_PENDULUM) or c:IsType(TYPE_LINK))
end

function s.indesval(e,re,r,rp)
	return (r&(REASON_BATTLE|REASON_EFFECT))~=0
end

--Must have no card in your other Pendulum Zone
function s.plcon(e,tp,eg,ep,ev,re,r,rp)
	local seq=e:GetHandler():GetSequence()
	local otherseq=1-seq
	return Duel.CheckLocation(tp,LOCATION_PZONE,otherseq)
end

--Place filter
function s.plfilter(c)
	return c:IsType(TYPE_PENDULUM)
		and (c:IsSetCard(0x04B2) or c:IsSetCard(0x99) or c:IsSetCard(0xa2))
		and not c:IsForbidden()
		and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
end

function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil)
	end
end

function s.plop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local seq=c:GetSequence()
	local otherseq=1-seq
	if not Duel.CheckLocation(tp,LOCATION_PZONE,otherseq) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

--Destroyed or banished from Pendulum Zone
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_PZONE)
end

--Special Summon filter
function s.spfilter1(c,e,tp)
	return (c:IsSetCard(0x99) or c:IsSetCard(0xf8) or c:IsSetCard(0x04B2))
		and not c:IsCode(id)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (not c:IsLocation(LOCATION_EXTRA) or c:IsFaceup())
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_EXTRA+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Ritual level
function s.rlevel(e,c)
	return e:GetHandler():GetLevel()
end

--Must first be Ritual Summoned
function s.splimit2(e,se,sp,st)
	return (st&SUMMON_TYPE_RITUAL)==SUMMON_TYPE_RITUAL
end

--Special Summon destroyed monster
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleTarget()
	if chk==0 then
		return bc and bc:IsLocation(LOCATION_GRAVE)
			and bc:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetTargetCard(bc)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,bc,1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--ATK becomes 0
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)

		--DEF becomes 0
		local e2=e1:Clone()
		e2:SetCode(EFFECT_SET_DEFENSE)
		tc:RegisterEffect(e2)

		--Can be treated as Level 7 for Synchro Summon
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_SYNCHRO_LEVEL)
		e3:SetValue(s.synlv)
		e3:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e3)
	end
end

function s.synlv(e,c,sc)
	return 7
end