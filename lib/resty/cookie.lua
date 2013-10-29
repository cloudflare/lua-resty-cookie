-- Copyright (C) 2013 Jiale Zhi (calio), Cloudflare Inc.
-- require "luacov"

local type              = type
local get_string_byte   = string.byte
local get_string_sub    = string.sub

local EQUAL         = get_string_byte("=")
local SEMICOLON     = get_string_byte(";")
local SPACE         = get_string_byte(" ")
local HTAB          = get_string_byte("\t")


local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 2)

_M._VERSION = '0.01'


local mt = { __index = _M }


local function get_cookie_table(text_cookie)
    if type(text_cookie) ~= "string" then
        ngx.log(ngx.ERR, string.format(
                "expect text_cookie to be \"string\" but found %s",
                type(text_cookie)))
        return {}
    end

    local cookie_table  = {}
    local EXPECT_KEY    = 1
    local EXPECT_VALUE  = 2
    local EXPECT_SP     = 3

    local state = EXPECT_SP
    local i = 1
    local j = 1
    local key, value

    while j <= #text_cookie do
        if state == EXPECT_KEY then
            if get_string_byte(text_cookie, j) == EQUAL then
                key = get_string_sub(text_cookie, i, j - 1)
                state = EXPECT_VALUE
                i = j + 1
            end
        elseif state == EXPECT_VALUE then
            if get_string_byte(text_cookie, j) == SEMICOLON or
                    get_string_byte(text_cookie, j) == SPACE or
                    get_string_byte(text_cookie, j) == HTAB then

                value = get_string_sub(text_cookie, i, j - 1)
                cookie_table[key] = value

                key, value = nil, nil
                state = EXPECT_SP
                i = j + 1
            end
        elseif state == EXPECT_SP then
            if get_string_byte(text_cookie, j) ~= SPACE and
                    get_string_byte(text_cookie, j) ~= HTAB then
                state = EXPECT_KEY
                i = j
                j = j - 1
            end
        end
        j = j + 1
    end

    if key ~= nil and value == nil then
        cookie_table[key] = get_string_sub(text_cookie, i)
    end

    return cookie_table
end

function _M.new(self)
    local _cookie = ngx.var.http_cookie
    if not _cookie then
        return nil, "no cookie found in current request"
    end
    return setmetatable({ _cookie = _cookie }, mt)
end

function _M.get(self, key)
    if self.cookie_table == nil then
        self.cookie_table = get_cookie_table(self._cookie)
    end

    return self.cookie_table[key]
end

function _M.get_all(self)
    local err

    if self.cookie_table == nil then
        self.cookie_table = get_cookie_table(self._cookie)
    end

    return self.cookie_table
end

return _M
