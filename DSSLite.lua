local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- DataStorServiceeLite (DSSLite)
local function DSSLite()
	local dsmod = {}
	local DataStore = nil;
	local cache = nil;
	local entryKey = nil

	function dsmod.CopyTable(t)
		return HttpService:JSONDecode(HttpService:JSONEncode(t))
	end

	function dsmod.InitStore(key)
		print("Initializing store: " .. key)
		if not DataStore then
			DataStore = DataStoreService:GetDataStore(key)
			return true
		end
		print("use DSSLite:ReleaseStore() before running DSSLite:InitStore(key) again")
		return false
	end

	function dsmod.GetStore()
		return DataStore;
	end

	function dsmod.ReleaseStore()
		if DataStore then
			DataStore = nil
			return true
		end
		print("There is no DataStore to release")
		return false;
	end

	-------------------------------------------------------
	function dsmod.GetData(key)
		local success, result = pcall(function()
			return DataStore:GetAsync(key)
		end)
		if not success then
			warn(result)
		end
		return success, result
	end

	function dsmod:GetCacheCopy()
		return self.CopyTable(cache);
	end

	function dsmod.LoadIntoCache(key)
		print("loading data into read only cache")
		entryKey = key;
		local success;
		success, cache = dsmod.GetData(key)
		print("did system load cache: " .. tostring(success))
		return success
	end
	
	function dsmod.SaveData(key, data)
		local success, result = pcall(function()
			DataStore:SetAsync(key, data)
		end)
		if not success then
			warn(result)
		end
		return success, result 
	end

	function dsmod.ReleaseCache()
		cache = nil;
		entryKey = nil;
		return true;
	end

	function dsmod:SaveCache()
		return self:SaveData(entryKey, cache)
	end

	function dsmod:SaveAndReleaseCache()
		self.SaveCache();
		self.ReleaseCache();
	end

	function dsmod:SaveCacheAndReleaseFull()
		self.SaveAndReleaseCache();
		self.ReleaseStore();
	end
	-------------------------------------------------------------

	function dsmod.UpdateCache(newData, ...) -- variadic args are any number of nested keys
		local function update(t, newData, ...)
			print("searching for key " .. (...) .. " in: ")
			print(t)
			if type(t) == "table" then
				if t[(...)] then
					print((...) .. " is found in cache")
					print(select('#', ...))
					if select('#', ...) == 0 then
						print("reached end, updating value for key: " .. ((...)))
						t[(...)] = newData;
						return true;
					else
						return update(t[(...)], newData, select(2, ...))
					end
				else
					return false;
				end
			end
			return false;
		end
		return update(cache, newData, ...)
	end
	return dsmod
end

return DSSLite


