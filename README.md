# Elm cookie consent

Provider-independent consent snapshots and configurable host checks for Elm.
Applications supply their own ports, consent provider, host rules and UI.
Version 2 replaces the OneTrust-specific host/group payload in version 1.

```elm
import Cookie

videoRules =
    [ ( "youtube.com", Cookie.Marketing )
    , ( "vimeo.com", Cookie.Marketing )
    ]

-- Initialize with Cookie.empty; replace the entire snapshot on every update.
-- Unknown hosts are blocked; matching is exact, including subdomains.
Cookie.checkHost videoRules "youtube.com" consent
Cookie.hasGivenConsent Cookie.Statistical consent
```

## CookieTractor adapter

Keep this JavaScript in each application's initialization, after Elm is ready:

```js
const send = categories => app.ports.onCookieConsentChange.send(categories);
window.addEventListener('CookieConsent', event => send(event.detail.current));
send(window.cookieTractor?.consent.current || []);
```

Subscribe before reading the current snapshot so both saved consent and later
changes are handled. Send the **whole** current array, including an empty array
when consent is withdrawn. Replace the Elm state, rather than merging it.

```elm
port onCookieConsentChange : (Decode.Value -> msg) -> Sub msg

-- Decode using Decode.decodeValue Cookie.decoder.
-- For a decoding error, reset to Cookie.empty (fail closed).
```

The decoder accepts `necessary`, `functional`, `statistical`, `marketing` and
`undefined` (represented by `Cookie.Unclassified`). Unknown string aliases are
ignored; malformed payloads fail decoding. Categories are never implicitly
accepted, including `Necessary`.

Install the provider's main script before application/tracking scripts. If Elm
controls whether video iframes exist, disable CookieTractor's YouTube/Vimeo
wrappers to avoid two layers controlling the same videos. Each application owns
its website ID, cookie declaration, settings button and tracking integration.
GTM tags need appropriate consent requirements independently of this Elm model.

See CookieTractor's [API](https://www.cookietractor.se/dokumentation/funktion-konfiguration/javascript-api),
[events](https://www.cookietractor.se/dokumentation/hantera-cookies/javascript-events-och-funktioner)
and [video wrapper settings](https://www.cookietractor.se/dokumentation/funktion-konfiguration/inaktivera-video-wrapper).

## Migrating from 1.0.0

- `List Cookie.Host` becomes `Cookie.Consent`.
- `Cookie.defaultHosts` becomes `Cookie.empty`.
- `Cookie.decoder` now accepts a JSON array of category aliases, not OneTrust groups.
- Replace `Cookie.hasGivenConsent host hosts` with
  `Cookie.checkHost appRules host consent`.
- `Cookie.NoConsent` now contains a `Cookie.Category`, rather than a translated
  group name. The application owns the display labels.
- `Cookie.hasGivenConsent category consent` directly checks a category.
- Replace the Optanon callback and settings button with the new provider's API.

`examples/` demonstrates an application-owned video rule and consent withdrawal.
The checkbox is a demo only, not a production consent interface.

## Verify

With Elm 0.19.1 and Node installed:

```sh
cd tests
elm make Main.elm --output=/tmp/elm-cookie-consent-tests.js
node run.cjs /tmp/elm-cookie-consent-tests.js
cd ../examples
elm make src/Main.elm --output=/tmp/elm-cookie-consent-example.js
cd ..
elm make --docs=docs.json
```

## Release

Version 2.0.0 is a breaking API change. Commit the library changes, tag `2.0.0`
(no `v` prefix), and push the commit and tag before deploying a consumer pinned
to that version. A sibling checkout can be used as a temporary local source
for verification; production `elm-git.json` must reference the released tag.
