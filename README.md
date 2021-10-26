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

