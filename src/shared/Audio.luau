--!strict
-- Sons locais distribuídos com o engine; não dependem de HTTP nem assets externos.
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Audio={muted=false}
local lastImpact=0
local function play(id: string,volume: number,speed: number)
	if Audio.muted then return end
	local sound=Instance.new("Sound") sound.SoundId=id sound.Volume=volume sound.PlaybackSpeed=speed sound.Parent=SoundService
	SoundService:PlayLocalSound(sound) Debris:AddItem(sound,5)
end
function Audio.click() play("rbxasset://sounds/volume_slider.ogg",0.12,1.3) end
function Audio.quest()
	for i=1,3 do task.delay((i-1)*0.16,function() play("rbxasset://sounds/volume_slider.ogg",0.16,0.9+i*0.2) end) end
end
function Audio.impact()
	if os.clock()-lastImpact<0.3 then return end lastImpact=os.clock()
	play("rbxasset://sounds/impact_explosion_03.mp3",0.12,0.85)
end
return Audio
