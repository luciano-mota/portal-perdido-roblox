--!strict
-- Arte original. Prévia de pixels só no Studio; produção exige asset aprovado.
local RunService=game:GetService("RunService")
local ContentProvider=game:GetService("ContentProvider")
local Face={}
local cached: {[string]: any}={}
local failed: {[string]: boolean}={}
local assets: {[string]: string}={Explorer="rbxassetid://77141053762926"}
local previews={Explorer="ExplorerFacePixels"}
local available: {[string]: boolean}={}

local function contentFor(style: string): Content?
	local asset=assets[style]
	if asset and available[style]==nil and RunService:IsClient() then
		available[style]=false
		pcall(function()
			ContentProvider:PreloadAsync({asset},function(_,status)
				available[style]=status==Enum.AssetFetchStatus.Success
			end)
		end)
	end
	if asset and available[style] then return Content.fromUri(asset) end
	if not RunService:IsStudio() or not RunService:IsClient() or failed[style] then return nil end
	if cached[style] then return Content.fromObject(cached[style]) end
	local source=previews[style]
	if not source then return nil end
	local ok,image=pcall(function()
		local data=require(script.Parent.Assets[source])
		local encoding=game:GetService("EncodingService")
		local packed=encoding:Base64Decode(buffer.fromstring(data.rgbaZstdBase64))
		local expected=data.width*data.height*4
		assert(encoding:GetDecompressedBufferSize(packed,Enum.CompressionAlgorithm.Zstd)==expected,"face buffer size")
		local pixels=encoding:DecompressBuffer(packed,Enum.CompressionAlgorithm.Zstd)
		local result=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(data.width,data.height)})
		assert(result,"face preview budget")
		result:WritePixelsBuffer(Vector2.zero,result.Size,pixels)
		return result
	end)
	if not ok then
		failed[style]=true warn("[PortalPerdido][FacePreview]",style,"prévia indisponível") return nil
	end
	cached[style]=image
	return Content.fromObject(image)
end

function Face.apply(head: BasePart,style: string): boolean
	local existing=head:FindFirstChild("PortalFace")
	if existing and existing:GetAttribute("FaceStyle")==style then return true end
	local content=contentFor(style)
	if not content then return false end
	local decal=Instance.new("Decal") decal.Name="PortalFace" decal.Face=Enum.NormalId.Front
	local ok=pcall(function() decal.TextureContent=content end)
	if not ok then decal:Destroy() return false end
	decal:SetAttribute("FaceStyle",style)
	decal:SetAttribute("StudioPreview",available[style]~=true)
	if existing then existing:Destroy() end
	decal.Parent=head
	return true
end

return Face
