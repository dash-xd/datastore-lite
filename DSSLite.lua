local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

-- Define shared functions
local DSSLiteMethods = {}

function DSSLiteMethods:copyTable(t)
    return HttpService:JSONDecode(HttpService:JSONEncode(t))
end

function DSSLiteMethods:initStore(key)
    print("Initializing store: " .. key)
    if not self.DataStore then
        self.DataStore = DataStoreService:GetDataStore(key)
        return true
    end
    print("Use DSSLite:ReleaseStore() before running DSSLite:InitStore(key) again")
    return false
end

function DSSLiteMethods:releaseStore()
    if self.DataStore then
        self.DataStore = nil
        return true
    end
    print("There is no DataStore to release")
    return false
end

function DSSLiteMethods:getData(key)
    local success, result = pcall(function()
        return self.DataStore:GetAsync(key)
    end)
    if not success then
        warn(result)
    end
    return success, result
end

function DSSLiteMethods:saveData(key, data)
    local success, result = pcall(function()
        self.DataStore:SetAsync(key, data)
    end)
    if not success then
        warn(result)
    end
    return success, result
end

function DSSLiteMethods:loadIntoCache(key)
    print("Loading data into read-only cache")
    self.entryKey = key
    local success
    success, self.cache = self:getData(key)
    print("Did system load cache: " .. tostring(success))
    return success
end

function DSSLiteMethods:releaseCache()
    self.cache = nil
    self.entryKey = nil
    return true
end

-- Define SavableDSSLiteMethods
local SavableDSSLiteMethods = {}

function SavableDSSLiteMethods:saveCache()
    return self:saveData(self.entryKey, self.cache)
end

function SavableDSSLiteMethods:saveAndReleaseCache()
    self:saveCache()
    self:releaseCache()
end

function SavableDSSLiteMethods:saveCacheAndReleaseFull()
    self:saveAndReleaseCache()
    self:releaseStore()
end

-- METATABLE INHERITOR FOR MULTIPLE INHERITANCE
local function SearchParents(key, parents)
    for i = 1, #parents do
        local found = parents[i][key]
        if found then
            return found
        end
    end
end

local function RegisterParents(parents)
    return {
        __index = function(self, key)
            return SearchParents(key, parents)
        end
    }
end

-- Define constructor for DataStoreLite instances
local function CreateDataStoreLite()
    local dsInstance = {
        DataStore = nil,
        entryKey = nil,
        cache = nil
    }

    -- Set metatable to access shared functions and private data
    local mt = {
        __index = DSSLiteMethods,
        __newindex = function(tbl, key, value)
            if dsInstance[key] ~= nil then
                error("Cannot directly set '" .. key .. "'")
            else
                rawset(tbl, key, value)
            end
        end
    }

    setmetatable(dsInstance, mt)

    return dsInstance
end

-- Define constructor for SavableDSSLite instances
local function CreateSavableDataStoreLite()
    local savableDsInstance = CreateDataStoreLite()
    local savableMt = RegisterParents({SavableDSSLiteMethods, savableDsInstance})

    setmetatable(savableDsInstance, savableMt)

    return savableDsInstance
end

return {
    NewDSSLite = CreateDataStoreLite,
    NewSavableDSSLite = CreateSavableDataStoreLite
}
