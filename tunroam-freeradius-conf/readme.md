# TUNroam auth-server config

## Decision tree snippets

#### sites-enabled/default

Decision tree for 'desires to be proxied' and 'is proxied'

```
# 0 0 do nothing, let the server pass it to inner-tunnel
# 0 1 something went from: reject
# 1 0 proxy to remote
# 1 1 we are the remote server: perform check
```

#### sites-enabled/inner-tunnel

The `inner-tunnel` doesn't care about the 'is proxied'
(`$Proxy-State`).
It also does not care about the need for proxying,
since the `default` server only lets it reach the
`inner-tunnel` if it does not needs to be proxied to a remote machine.

