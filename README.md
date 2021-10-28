HTTPS upgrader
==============

This basic NGINX proxy aims to provide **HTTPS upgrading for insecure HTTP
connections**.

It can obviously be used on any kind of device or software supporting HTTP proxy
configuration.

# Usage

The most basic usage is to run `make`, automatically building and running the
proxy server on default host port 8080. Some configuration is possible, as
demonstrated down below.

```bash
# Run proxy on port 8080
make
# Run the server on a specific port
make PORT=8081
# Deamonize server
make DOCKER_OPTIONS='-d'
```

## DNS configuration
NGINX DNS configuration is automatically generated on Linux systems where
`/etc/resolv.conf` is a valid file. It will fallback to using Google DNS
servers in case of unavailability.

## Domain whitelisting
It is possible to bypass HTTPS upgrading for specific domains by writing
patterns in a text file stored in folder `conf/bypass/`. This will
automatically trigger configuration files (re)generation.

It is possible to write regular expressions by starting patterns with character
`^`.

Here is an example configuration, in `conf/bypass/internet.txt`.
```
# Allows insecure connections to this specific domain
example.com
# Whitelist insecure.com and all subdomains
^(.+\.)?insecure.com$
```

# Limitations

This is a very basic proxy, here are some caveats:
- **No scaling**: most likely has very bad behavior facing a lot of requests
- NGINX configuration "scripting" sucks (let me vent please)
- **Not a server-side HTTPS upgrade**: some websites will break
- And many others :)

# Improvements

Here are some improvement ideas, feel free to contribute through pull requests!

## Active redirection
Add **HTTP 301 redirection** to (working) secured version. If unavailable,
silently fallback to transparent upgrade. Caching is a must to prevent very slow
response in case of unavailability - maybe a background worker updating cache at
a specific time interval?

I currently have no implementation idea other than writing a C module or a Lua
script through unofficial [Lua module].

[Lua module]: https://github.com/openresty/lua-nginx-module

## Drop non-standard insecure connections
Use a very basic heuristic to **detect raw HTTP connection** attempts on
non-standard ports, in order to drop them.

Must be doable by writing a nginx C module.
