Name
====

lua-resty-cookie - This library parses HTTP Cookie header for Nginx and returns each field in the cookie.

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [get](#get)
    * [get_all](#get_all)
    * [set](#set)
    * [edit](#edit)
    * [parse_set_cookie](#parse_set_cookie)
* [Installation](#installation)
* [Authors](#authors)
* [Copyright and License](#copyright-and-license)

Status
======

This library is production ready.

Synopsis
========
```lua
    lua_package_path "/path/to/lua-resty-cookie/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
                local ck = require "resty.cookie"
                local cookie, err = ck:new()
                if not cookie then
                    ngx.log(ngx.ERR, err)
                    return
                end

                -- get single cookie
                local field, err = cookie:get("lang")
                if not field then
                    ngx.log(ngx.ERR, err)
                    return
                end
                ngx.say("lang", " => ", field)

                -- get all cookies
                local fields, err = cookie:get_all()
                if not fields then
                    ngx.log(ngx.ERR, err)
                    return
                end

                for k, v in pairs(fields) do
                    ngx.say(k, " => ", v)
                end

                -- set one cookie
                local ok, err = cookie:set({
                    key = "Name", value = "Bob", path = "/",
                    domain = "example.com", secure = true, httponly = true,
                    expires = "Wed, 09 Jun 2021 10:18:14 GMT", max_age = 50,
                    samesite = "Strict", extension = "a4334aebaec"
                })
                if not ok then
                    ngx.log(ngx.ERR, err)
                    return
                end

                -- set another cookie, both cookies will appear in HTTP response
                local ok, err = cookie:set({
                    key = "Age", value = "20",
                })
                if not ok then
                    ngx.log(ngx.ERR, err)
                    return
                end
            ';
        }
    }
```

Methods
=======

[Back to TOC](#table-of-contents)

new
---
`syntax: cookie_obj = cookie()`

Create a new cookie object for current request. You can get parsed cookie from client or set cookie to client later using this object.

[Back to TOC](#table-of-contents)

get
---
`syntax: cookie_val, err = cookie_obj:get(cookie_name)`

Get a single client cookie value. On error, returns `nil` and an error message.

[Back to TOC](#table-of-contents)

get_all
-------
`syntax: fields, err = cookie_obj:get_all()`

Get all client cookie key/value pairs in a lua table. On error, returns `nil` and an error message.

[Back to TOC](#table-of-contents)

set
---
```lua
syntax: ok, err = cookie_obj:set({
    key = "Name",
    value = "Bob",
    path = "/",
    domain = "example.com",
    secure = true, httponly = true,
    expires = "Wed, 09 Jun 2021 10:18:14 GMT",
    max_age = 50,
    samesite = "Strict",
    extension = "a4334aebaec"
})
```

Set a cookie to client. This will add a new 'Set-Cookie' response header. `key` and `value` are required, all other fields are optional.
If the same cookie (whole cookie string, e.g. "Name=Bob; Expires=Wed, 09 Jun 2021 10:18:14 GMT; Max-Age=50; Domain=example.com; Path=/; Secure; HttpOnly;") has already been setted, new cookie will be ignored.

[Back to TOC](#table-of-contents)

edit
----
```lua
syntax: ok, err = cookie_obj:edit(cookie_name, {
  value = "Bob",
  path = "/",
  domain = "example.com",
  secure = true, httponly = true,
  expires = "Wed, 09 Jun 2021 10:18:14 GMT",
  max_age = 50,
  samesite = "Strict",
  extension = "a4334aebaec"
})
```

Edits the outgoing `Set-Cookie` header of the specified `cookie_name`, overriding the header's original directives with the ones provided in the table. Returns `true` if the header is edited successfully, and `nil` when there's an error, including when no `Set-Cookie` header matches the supplied `cookie_name`.

The table can contain as many or as few arguments as you need to modify. For example:
```lua
ok, err = cookie_obj:edit("PHPSESSID", {secure = true, samesite = "None"})
```

parse_set_cookie
----------------

```lua
syntax: cookie_obj.parse_set_cookie("Set-Cookie: CookieName=CookieValue; Domain=example.com; Secure; HttpOnly")
```

This function allows you to parse a `Set-Cookie` header into a Lua table, and exists primarily to facilitate the [`edit` function](#edit). Only works on string input. To walk a table and parse, then edit all `Set-Cookie` headers, see the following example:

```lua
local ck = require "resty.cookie"
local cookie, err = ck:new()
if not cookie then
  ngx.log(ngx.ERR, err)
  return
end

-- Check for the Set-Cookie header and quit if we don't see it
if ngx.header['Set-Cookie'] == nil then return end

-- Get all set-cookie headers and gather into a table
local ngx_set_cookie = ngx.header['Set-Cookie']
if type(ngx_set_cookie) == "string" then ngx_set_cookie = {ngx_set_cookie} end

-- Walk the Set-Cookie header table and modify each header
for i,v in ipairs(ngx_set_cookie) do
  -- Extract the cookie names
  local cookie_table, err = cookie.parse_set_cookie(ngx_set_cookie[i])
  if not cookie_table then
    ngx.log(ngx.ERR, err)
    return
  end

  -- Edit the cookie to insert SameSite=None; Secure
  local edit_cookie, err = cookie:edit(cookie_table['key'], { SameSite = "None", Secure = "" })
  if not edit_cookie then
    ngx.log(ngx.ERR, err)
    return
  end
end
```

Installation
============

You need to compile [ngx_lua](https://github.com/chaoslawful/lua-nginx-module/tags) with your Nginx.

You need to configure
the [lua_package_path](https://github.com/chaoslawful/lua-nginx-module#lua_package_path) directive to
add the path of your `lua-resty-cookie` source tree to ngx_lua's Lua module search path, as in

    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-cookie/lib/?.lua;;";
        ...
    }

and then load the library in Lua:

    local ck = require "resty.cookie"

[Back to TOC](#table-of-contents)

Authors
=======

Jiale Zhi <vipcalio@gmail.com>, CloudFlare Inc.

Yichun Zhang (agentzh) <agentzh@gmail.com>, CloudFlare Inc.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2013, by Jiale Zhi <vipcalio@gmail.com>, CloudFlare Inc.

Copyright (C) 2013, by Yichun Zhang <agentzh@gmail.com>, CloudFlare Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)
