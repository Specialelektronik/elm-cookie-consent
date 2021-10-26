# CookiePro Consent management helper

This package exposes a host type and an error type to determine how to display embedded video from third party providers like youtube and vimeo.

The application has to implement ports in order to feed data about the user's cookie consent.

## app.js example

```js
// listen for cookie consent changes to display placeholder messages for embeds from hosts without consent
window.OptanonWrapper = function () {
    if (app?.ports?.onCookieConsentChange && window.Optanon?.GetDomainData?.().Groups && OptanonActiveGroups) {
        app.ports.onCookieConsentChange.send({
            allGroups: window.Optanon.GetDomainData().Groups,
            activeGroupIdsString: OptanonActiveGroups
        });
    }
}
```

## Session.elm example

```elm
cookieChanges : (Session -> msg) -> Session -> Sub msg
cookieChanges toMsg session =
    onCookieConsentChange (\value -> toMsg (mapUI (\ui -> { ui | cookieHosts = decodeCookieHosts value }) session))

decodeCookieHosts : Value -> List Cookie.Host
decodeCookieHosts value =
    Result.withDefault Cookie.defaultHosts (Decode.decodeValue Cookie.decoder value)

port onCookieConsentChange : (Value -> msg) -> Sub msg
```

# Release

1. Update documentation: `elm make --docs=docs.json`
2. Create the next tag according to semver in main branch. `git tag -a 1.2.3 -m "Short description of changes in the new version"` The tag should look something like this: "1.2.3", NOT "v1.2.3"
3. Push it real good! `git push origin --force --tags`
