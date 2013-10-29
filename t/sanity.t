# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 2);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "/usr/local/openresty-debug/lualib/?.so;/usr/local/openresty/lualib/?.so;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();

log_level('debug');

run_tests();

__DATA__

=== TEST 1: sanity
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local ck = require "resty.cookie"
            local cookie, err = ck:new()
            if not cookie then
                ngx.log(ngx.ERR, err)
                return
            end

            local fields = cookie:get_all()

            for k, v in pairs(fields) do
                ngx.say(k, " => ", v)
            end
        ';
    }
--- request
GET /t
--- more_headers
Cookie: SID=31d4d96e407aad42; lang=en-US
--- response_body
SID => 31d4d96e407aad42
lang => en-US



=== TEST 2: sanity 2
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local ck = require "resty.cookie"
            local cookie, err = ck:new()
            if not cookie then
                ngx.log(ngx.ERR, err)
                return
            end

            local field = cookie:get("lang")
            ngx.say("lang", " => ", field)
        ';
    }
--- request
GET /t
--- more_headers
Cookie: SID=31d4d96e407aad42; lang=en-US
--- response_body
lang => en-US

