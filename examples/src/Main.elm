module Main exposing (main)

import Browser
import Cookie
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events


main : Program () Bool Bool
main =
    Browser.sandbox
        { init = False
        , update = \accepted _ -> accepted
        , view = view
        }


view : Bool -> Html Bool
view accepted =
    let
        consent =
            Cookie.fromCategories
                (if accepted then
                    [ Cookie.Marketing ]

                 else
                    []
                )
    in
    Html.div []
        [ Html.p [] [ Html.text "Demo only: production consent comes from your consent provider." ]
        , Html.label []
            [ Html.input [ Attributes.type_ "checkbox", Attributes.checked accepted, Events.onCheck identity ] []
            , Html.text "Accept marketing cookies"
            ]
        , case Cookie.checkHost [ ( "youtube.com", Cookie.Marketing ) ] "youtube.com" consent of
            Ok () ->
                Html.iframe [ Attributes.src "https://www.youtube.com/embed/3GwjfUFyY6M" ] []

            Err _ ->
                Html.p [] [ Html.text "Accept marketing cookies to load the video." ]
        ]
