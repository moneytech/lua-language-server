local listMgr     = require 'vm.list'
local newClass    = require 'emmy.class'
local newType     = require 'emmy.type'
local newTypeUnit = require 'emmy.typeUnit'
local newAlias    = require 'emmy.alias'
local newParam    = require 'emmy.param'
local newReturn   = require 'emmy.return'
local newField    = require 'emmy.field'
local newGeneric  = require 'emmy.generic'

local mt = {}
mt.__index = mt
mt.__name = 'emmyMgr'

function mt:flushClass(name)
    local list = self._class[name]
    if not list then
        return
    end
    local version = listMgr.getVersion()
    if version == list.version then
        return
    end
    for srcId in pairs(list) do
        if not listMgr.get(srcId) then
            list[srcId] = nil
        end
    end
    if not next(list) then
        self._class[name] = nil
        return
    end
    list.version = version
end

function mt:eachClassByName(name, callback)
    self:flushClass(name)
    local list = self._class[name]
    if not list then
        return
    end
    for k, class in pairs(list) do
        if k ~= 'version' then
            local res = callback(class)
            if res ~= nil then
                return res
            end
        end
    end
end

function mt:eachClass(...)
    local n = select('#', ...)
    if n == 1 then
        local callback = ...
        for name in pairs(self._class) do
            local res = self:eachClassByName(name, callback)
            if res ~= nil then
                return res
            end
        end
    else
        local name, callback = ...
        return self:eachClassByName(name, callback)
    end
end

function mt:getClass(name)
    self:flushClass(name)
    local list = self._class[name]
    local version = listMgr.getVersion()
    if not list then
        list = {
            version = version,
        }
        self._class[name] = list
    end
    return list
end

function mt:addClass(source)
    local className = source[1][1]
    local list = self:getClass(className)
    list[source.id] = newClass(self, source)
    return list[source.id]
end

function mt:addType(source)
    local typeObj = newType(self, source)
    for i, obj in ipairs(source) do
        local typeUnit = newTypeUnit(self, obj)
        local className = obj[1]
        local list = self:getClass(className)
        typeUnit:setParent(typeObj)
        list[source.id] = typeUnit
        typeObj._childs[i] = typeUnit
        obj:set('emmy.typeUnit', typeUnit)
    end
    return typeObj
end

function mt:addAlias(source, typeObj)
    local aliasName = source[1][1]
    local aliasObj = newAlias(self, source)
    aliasObj:bindType(typeObj)
    local list = self:getClass(aliasName)
    list[source.id] = aliasObj
    return aliasObj
end

function mt:addParam(source, bind)
    local paramObj = newParam(self, source)
    if bind.type == 'emmy.type' then
        paramObj:bindType(bind)
    elseif bind.type == 'emmy.generic' then
        paramObj:bindGeneric(bind)
    end
    return paramObj
end

function mt:addReturn(source, bind)
    local returnObj = newReturn(self, source)
    if bind.type == 'emmy.type' then
        returnObj:bindType(bind)
    elseif bind.type == 'emmy.generic' then
        returnObj:bindGeneric(bind)
    end
    return returnObj
end

function mt:addField(source, typeObj, value)
    local fieldObj = newField(self, source)
    fieldObj:bindType(typeObj)
    fieldObj:bindValue(value)
    return fieldObj
end

function mt:addGeneric(defs)
    local genericObj = newGeneric(self, defs)
    return genericObj
end

function mt:remove()
end

function mt:count()
    local count = 0
    for _, list in pairs(self._class) do
        for k in pairs(list) do
            if k ~= 'version' then
                count = count + 1
            end
        end
    end
    return count
end

return function ()
    ---@class emmyMgr
    local self = setmetatable({
        _class = {},
    }, mt)
    return self
end
