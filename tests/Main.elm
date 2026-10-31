port module Main exposing (main)

import Cookie
import Json.Decode as Decode
import Json.Encode as Encode
import Platform


port results : Encode.Value -> Cmd msg


main : Program () () Never
main =
    Platform.worker
        { init = \_ -> ( (), results (Encode.list encodeCheck checks) )
        , update = \msg _ -> never msg
        , subscriptions = \_ -> Sub.none
        }


encodeCheck : ( String, Bool ) -> Encode.Value
encodeCheck ( name, passed ) =
    Encode.object [ ( "name", Encode.string name ), ( "passed", Encode.bool passed ) ]


checks : List ( String, Bool )
checks =
    let
        rules =
            [ ( "youtube.com", Cookie.Marketing ), ( "metrics.example", Cookie.Statistical ) ]

        decode =
            Decode.decodeString Cookie.decoder

        marketing =
            Cookie.fromCategories [ Cookie.Marketing ]

        decodedAllows category json =
            decode json |> Result.map (Cookie.hasGivenConsent category) |> Result.withDefault False
    in
    [ ( "empty denies marketing", not (Cookie.hasGivenConsent Cookie.Marketing Cookie.empty) )
    , ( "empty does not infer necessary", not (Cookie.hasGivenConsent Cookie.Necessary Cookie.empty) )
    , ( "marketing allows configured video", Cookie.checkHost rules "youtube.com" marketing == Ok () )
    , ( "categories do not grant each other", Cookie.checkHost rules "metrics.example" marketing == Err (Cookie.NoConsent Cookie.Statistical) )
    , ( "unknown hosts are blocked", Cookie.checkHost rules "unknown.example" marketing == Err Cookie.UnknownHost )
    , ( "subdomains need explicit rules", Cookie.checkHost rules "www.youtube.com" marketing == Err Cookie.UnknownHost )
    , ( "known host without consent names category", Cookie.checkHost rules "youtube.com" Cookie.empty == Err (Cookie.NoConsent Cookie.Marketing) )
    , ( "provider category snapshot decodes", decodedAllows Cookie.Marketing "[\"necessary\",\"marketing\"]" )
    , ( "all supported aliases decode", List.all (\category -> decodedAllows category "[\"necessary\",\"functional\",\"statistical\",\"marketing\",\"undefined\"]") [ Cookie.Necessary, Cookie.Functional, Cookie.Statistical, Cookie.Marketing, Cookie.Unclassified ] )
    , ( "withdrawal removes consent", not (decodedAllows Cookie.Marketing "[]") )
    , ( "unknown aliases do not grant marketing", not (decodedAllows Cookie.Marketing "[\"future-category\",\"undefined\"]") )
    , ( "unknown aliases preserve known categories", decodedAllows Cookie.Marketing "[\"future-category\",\"marketing\"]" )
    , ( "malformed list fails", Result.toMaybe (decode "[\"marketing\",42]") == Nothing )
    , ( "legacy OneTrust shape fails", Result.toMaybe (decode "{\"allGroups\":[],\"activeGroupIdsString\":\"C0004\"}") == Nothing )
    ]
