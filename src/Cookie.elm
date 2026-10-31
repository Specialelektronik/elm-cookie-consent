module Cookie exposing
    ( Category(..), Consent, empty, fromCategories, hasGivenConsent
    , ConsentError(..), checkHost
    , decoder
    )

{-| Provider-independent cookie consent. Applications send a complete snapshot
of accepted category aliases through a port whenever consent changes.


# Consent

@docs Category, Consent, empty, fromCategories, hasGivenConsent


# Configurable host rules

@docs ConsentError, checkHost


# JSON

@docs decoder

-}

import Json.Decode as Decode exposing (Decoder)


{-| Categories supported by the consent model. `Unclassified` corresponds to the
JSON alias `undefined`; it does not grant permission for any other category.
-}
type Category
    = Necessary
    | Functional
    | Statistical
    | Marketing
    | Unclassified


{-| A complete snapshot of explicitly accepted categories.
-}
type Consent
    = Consent (List Category)


{-| No category is accepted before the consent provider initializes.
-}
empty : Consent
empty =
    Consent []


{-| Build a snapshot from accepted categories, for other providers or tests.
-}
fromCategories : List Category -> Consent
fromCategories =
    Consent


{-| Check whether a category has explicitly been accepted.
-}
hasGivenConsent : Category -> Consent -> Bool
hasGivenConsent category (Consent categories) =
    List.member category categories


{-| A known host requires a category that has not been accepted, or the
application has not configured a rule for this host.
-}
type ConsentError
    = NoConsent Category
    | UnknownHost


{-| Check a host against application-owned rules. Matching is exact: subdomains
need their own rules. Unknown hosts are always denied. The first matching rule
wins, so configure a single rule per host.

    checkHost [ ( "youtube.com", Marketing ) ] "youtube.com" empty
        --> Err (NoConsent Marketing)

-}
checkHost : List ( String, Category ) -> String -> Consent -> Result ConsentError ()
checkHost rules host consent =
    case List.filter (\( name, _ ) -> name == host) rules |> List.head of
        Just ( _, category ) ->
            if hasGivenConsent category consent then
                Ok ()

            else
                Err (NoConsent category)

        Nothing ->
            Err UnknownHost


{-| Decode a complete JSON array of accepted category aliases:
`necessary`, `functional`, `statistical`, `marketing`, `undefined`.
CookieTractor's documented `consent.current` and `CookieConsent` event's
`detail.current` use this shape. Unknown string aliases are ignored and never
grant a known category. Other JSON shapes fail decoding. Replace the previous
snapshot with the result; do not merge it, so withdrawals take effect.
-}
decoder : Decoder Consent
decoder =
    Decode.list Decode.string
        |> Decode.map (List.filterMap categoryFromAlias >> fromCategories)


categoryFromAlias : String -> Maybe Category
categoryFromAlias alias =
    case alias of
        "necessary" ->
            Just Necessary

        "functional" ->
            Just Functional

        "statistical" ->
            Just Statistical

        "marketing" ->
            Just Marketing

        "undefined" ->
            Just Unclassified

        _ ->
            Nothing
