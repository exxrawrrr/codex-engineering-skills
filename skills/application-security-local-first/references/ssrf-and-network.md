# SSRF and network safety

Primary reference model: OWASP SSRF Prevention guidance.

## Allowed schemes

For website crawling, allow only explicitly supported schemes, normally:

```
http:
https:
```

Reject schemes such as:
- file:
- ftp:
- gopher:
- data:
- javascript:
- smb:
- other application-specific protocols.

Do not normalize an unsupported scheme into a supported one.

## Parse, do not regex

Use the platform URL parser.

Validate:
- scheme;
- hostname;
- port policy;
- credentials/userinfo policy;
- resolved addresses;
- redirect targets.

Regex alone is not a safe URL parser.

## Public-address policy

For public-web mode, block non-public destinations including at minimum:

IPv4:
- loopback;
- RFC1918 private ranges;
- link-local;
- unspecified;
- multicast;
- carrier/shared ranges where policy requires;
- metadata-service addresses.

IPv6:
- loopback;
- unique-local;
- link-local;
- multicast;
- unspecified;
- IPv4-mapped forms that resolve into blocked IPv4 ranges.

Use a battle-tested IP parser and compare normalized addresses/ranges.

## DNS rebinding / pinning

Hostname string validation is insufficient.

Resolve all relevant A/AAAA results and reject the destination if any address violates policy according to the chosen connection model.

Avoid the gap:

```
validate DNS result A
↓
HTTP client performs unrelated DNS lookup B
↓
connects somewhere else
```

Where practical, bind connection behavior to the validated resolution or use a transport with socket-level address checks.

Re-check on each connection attempt if the transport can re-resolve.

## Redirects

Do not blindly auto-follow redirects.

For each hop:
1. parse Location;
2. resolve relative redirect;
3. validate scheme;
4. resolve destination;
5. apply public/private policy;
6. enforce scope policy;
7. enforce max redirects;
8. only then fetch.

A public URL redirecting to `127.0.0.1` or private RFC1918 space must be blocked in public-web mode.

## Local-network opt-in

If the product supports localhost/internal scanning, require explicit user configuration such as:

```
Allow Local Network Scanning
```

Treat it as a separate security mode, not an exception sprinkled through the code.

Even local mode should retain:
- scheme validation;
- redirect caps;
- body/time limits;
- user-agent identification;
- explicit target scope.

## Metadata services

Block cloud metadata endpoints in public-web mode.

Do not rely only on hostname blocking; validate resolved IP ranges too.

## Tests

Include:
- decimal/hex/IPv4 odd-form parsing according to chosen parser;
- IPv4-mapped IPv6;
- localhost names;
- DNS resolving to private ranges;
- public→private redirect;
- redirect loops;
- unsupported schemes;
- userinfo/credential edge cases;
- multiple A/AAAA records with one unsafe address.
