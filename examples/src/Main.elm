module Main exposing (..)

import Browser
import Cookie
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode
import Set exposing (Set)



-- MAIN


json : Set String -> String
json activeGroupIds =
    """
{ "allGroups" : [{"GroupName": "Absolut nödvändiga cookies","Hosts": [{"DisplayName": "sibforms.com","HostId": "H4"}],"CustomGroupId": "C0001"},{"GroupName": "Prestanda-cookies","Hosts": [],"CustomGroupId": "C0002"},{"GroupName": "Funktionella cookies","Hosts": [],"CustomGroupId": "C0003"},{"GroupName": "Riktade cookies","Hosts": [{"DisplayName": "vimeo.com","HostId": "H1"},{"DisplayName": "doubleclick.net","HostId": "H2"},{"DisplayName": "youtube.com","HostId": "H3"}],"CustomGroupId": "C0004"},{"GroupName": "Sociala medier-cookies","Hosts": [],"CustomGroupId": "C0005"}],
"activeGroupIdsString" :
""" ++ "\"" ++ String.join "," (Set.toList activeGroupIds) ++ "\"}"


possibleGroupIds : List String
possibleGroupIds =
    [ "C0001"
    , "C0002"
    , "C0003"
    , "C0004"
    , "C0005"
    ]


main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Model =
    { cookieHosts : List Cookie.Host
    , activeGroupIds : Set String
    }


init : Model
init =
    let
        activeGroupIds =
            Set.empty
    in
    { cookieHosts = decodeCookieHosts (json activeGroupIds)
    , activeGroupIds = activeGroupIds
    }


decodeCookieHosts : String -> List Cookie.Host
decodeCookieHosts string =
    string
        -- |> Debug.log "jsonString"
        |> Decode.decodeString Cookie.decoder
        -- |> Debug.log "result"
        |> Result.withDefault Cookie.defaultHosts



-- UPDATE


type Msg
    = ToggleGroupIdConsent String


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleGroupIdConsent groupId ->
            let
                newActiveGroupIds =
                    if Set.member groupId model.activeGroupIds then
                        Set.remove groupId model.activeGroupIds

                    else
                        Set.insert groupId model.activeGroupIds
            in
            { activeGroupIds = newActiveGroupIds
            , cookieHosts = decodeCookieHosts (json newActiveGroupIds)
            }



-- VIEW


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.h1 [] [ Html.text "Options" ]
        , Html.p [] [ Html.text "The users consent to these cookie groups should not be handled by Elm but by CookiePro. These are just for the same of this example's simplicity. In this example, only C0001 (Absolut nödvändiga cookies) and C0004 (Riktade cookies) will impact the list of hosts." ]
        , Html.p [] [ Html.strong [] [ Html.text "Enable C0004 in order for the youtube iframe to load." ] ]
        , Html.div [] (List.map (viewCheckbox model.activeGroupIds) possibleGroupIds)
        , Html.h1 [] [ Html.text "Cookie.Host Output" ]
        , Html.pre []
            [ Html.code
                [ Attributes.style "max-width" "80ch"
                , Attributes.style "display" "block"
                , Attributes.style "white-space" "normal"
                ]
                [ Html.text (Debug.toString model.cookieHosts) ]
            ]
        , Html.h1 [] [ Html.text "How an embed is viewed" ]
        , Html.div [ Attributes.style "max-width" "80ch" ] [ viewEmbed "youtube.com" model.cookieHosts ]
        ]


viewCheckbox : Set String -> String -> Html Msg
viewCheckbox activeGroupIds groupId =
    Html.p []
        [ Html.label []
            [ Html.input [ Attributes.type_ "checkbox", Events.onClick (ToggleGroupIdConsent groupId), Attributes.checked (Set.member groupId activeGroupIds) ] []
            , Html.text (" " ++ groupId)
            ]
        ]


viewEmbed : String -> List Cookie.Host -> Html Msg
viewEmbed currentHost hosts =
    case Cookie.hasGivenConsent currentHost hosts of
        Ok _ ->
            viewOkEmbed

        Err error ->
            viewConsentError currentHost error


viewOkEmbed : Html Msg
viewOkEmbed =
    Html.iframe [ Attributes.style "width" "80ch", Attributes.style "height" "45ch", Attributes.src "https://www.youtube.com/embed/3GwjfUFyY6M?feature=oembed&start=33&autoplay=1", Attributes.attribute "allow" "autoplay" ] []


viewConsentError : String -> Cookie.ConsentError -> Html Msg
viewConsentError host error =
    (case error of
        Cookie.NoConsent groupName ->
            [ Html.p []
                [ Html.strong [] [ Html.text host ]
                , Html.text " använder cookies på ett sätt som du inte accepterat."
                ]
            , Html.p []
                [ Html.text "För att visa innehållet behöver du acceptera cookies av typen: "
                ]
            , Html.p []
                [ Html.strong [] [ Html.text groupName ] ]
            , viewChangeCookieConsentButton
            ]

        Cookie.UnknownHost ->
            [ Html.p []
                [ Html.text "Vi känner inte till vilka cookies "
                , Html.strong [] [ Html.text host ]
                , Html.text " använder och vi kan därför inte visa innehållet. Hör av dig till "
                , Html.a [ Attributes.href "mailto:partnerzon@specialelektronik.se" ] [ Html.text "partnerzon@specialelektronik.se" ]
                , Html.text " för att få hjälp."
                ]
            ]
    )
        |> Html.div []


viewChangeCookieConsentButton : Html Msg
viewChangeCookieConsentButton =
    Html.button
        [ Attributes.id "ot-sdk-btn", Attributes.class "ot-sdk-show-settings" ]
        [ Html.text "Cookiesinställningar (does't work in this example)"
        ]
