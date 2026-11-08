--!strict
-- Executado no runtime Luau do Studio com adapter determinístico, sem dados reais.
return function(Store: any)
	local passed={}
	local function copy(t: any): any
		if typeof(t)~="table" then return t end
		local out={} for k,v in t do out[k]=copy(v) end return out
	end
	local records={}
	local adapter={}
	function adapter:UpdateAsync(key: string,transform: (any) -> any)
		local nextValue=transform(copy(records[key]))
		if nextValue==nil then return nil end
		records[key]=copy(nextValue)
		return copy(nextValue)
	end
	local now=100
	local a=Store.new(adapter,"server-A",function() return now end)
	local b=Store.new(adapter,"server-B",function() return now end)
	local profile,reason=a:load("player")
	assert(profile and not reason and profile.quest==1 and profile.coins==0,"fresh profile")
	table.insert(passed,"perfil novo válido")
	profile.classId="Explorer" profile.coins=25 profile.quest=3 profile.runes.Dawn=true profile.rewards["2"]=true
	assert(a:save("player",profile,false),"save owner")
	profile.coins=999
	assert(records.player.profile.coins==25,"saved snapshot must be isolated")
	table.insert(passed,"snapshot isolado e progresso preservado")
	local denied,busy=b:load("player")
	assert(denied==nil and busy=="BUSY","second live session must not acquire")
	table.insert(passed,"sessão concorrente bloqueada")
	now=281
	local recovered=b:load("player")
	assert(recovered and recovered.coins==25 and recovered.runes.Dawn and recovered.classId=="Explorer","expired lease recovery")
	local ok,stale=a:save("player",profile,false)
	assert(not ok and stale=="LOST_LEASE" and records.player.profile.coins==25,"stale session cannot overwrite")
	table.insert(passed,"lease expirada recuperada; servidor antigo não sobrescreve")
	assert(b:save("player",recovered,true),"release")
	assert(records.player.lease==nil,"released lease")
	local loaded=a:load("player")
	assert(loaded and loaded.quest==3 and loaded.rewards["2"],"reload exact progress")
	table.insert(passed,"liberação e recarga sem perda")
	records.corrupt={profile={version=2,quest=99,coins=0,runes={},rewards={}}}
	local bad,corrupt=a:load("corrupt")
	assert(bad==nil and corrupt=="CORRUPT" and records.corrupt.profile.quest==99,"corrupt data must not reset")
	table.insert(passed,"dados inválidos preservados sem reset destrutivo")
	for _, value in {-1,math.huge,0/0,1.5} do
		local invalid=Store.fresh() invalid.coins=value
		assert(Store.sanitize(invalid)==nil,"invalid balance accepted")
	end
	table.insert(passed,"saldo negativo, infinito, NaN e fracionário rejeitados")
	for _, value in {-1,4,math.huge,0/0,1.5,"2"} do
		local invalid=Store.fresh() invalid.seals=value
		assert(Store.sanitize(invalid)==nil,"invalid temple progress accepted")
	end
	for stage=0,3 do
		local valid=Store.fresh() valid.seals=stage
		assert(Store.sanitize(valid).seals==stage,"valid temple progress changed")
	end
	local legacy=Store.fresh() legacy.seals=nil
	assert(Store.sanitize(legacy).seals==0,"missing optional seals must default to zero")
	table.insert(passed,"progresso inválido do templo rejeitado; etapas válidas preservadas")
	local withControls=Store.fresh() withControls.controls={opacity=0.6,buttons={Jump={x=0.2,y=0.8,s=1.1}}}
	local keptControls=Store.sanitize(withControls)
	assert(keptControls and keptControls.controls.opacity==0.6 and keptControls.controls.buttons.Jump.s==1.1,"valid control layout must persist")
	local badControls=Store.fresh() badControls.controls={buttons={Hack={x=0,y=0,s=1}}}
	local keptProfile=Store.sanitize(badControls)
	assert(keptProfile and keptProfile.controls==nil,"invalid control layout must be dropped without rejecting the profile")
	table.insert(passed,"layout de controles válido preservado; inválido descartado sem perder o perfil")
	local broken=Store.new({UpdateAsync=function() error("simulated outage") end},"offline",function() return now end)
	local networkOK=pcall(function() broken:load("player") end)
	assert(not networkOK and records.player.profile.coins==25,"network failure cannot overwrite good data")
	table.insert(passed,"falha de rede não altera dados bons")
	return {passed=#passed,cases=passed}
end
