module Cookie exposing
    ( Host, hasGivenConsent, defaultHosts
    , ConsentError(..)
    , decoder
    )

{-| A helper package to deal with cookie consent changes when using CookiePro.


# Host and consent

CookiePro provides data on the groups of cookies (Marketing cookies, Performance cookies etc) discovered on your website through `window.Optanon?.GetDomainData?.().Groups` and `OptanonActiveGroups` property. These has to be fed into this module via a port (see **README.md**).

@docs Host, hasGivenConsent, defaultHosts


# Errors

@docs ConsentError


# Decoder

Data from CookiePro has to imported via a port and needs to be decoded using this decoder

@docs decoder

-}

import Json.Decode as Decode exposing (Decoder)


{-| Internal type that holds data about which hosts (domains) that the user has accepted cookies from.
-}
type Host
    = Host Internals


type alias Internals =
    { id : String
    , name : String
    , groupName : String
    , isActive : Bool
    }


{-| Intermidiate type to help decoding the object from CookiePro.
-}
type alias Group =
    { name : String
    , id : String
    , hosts :
        List
            { id : String
            , name : String
            }
    }


{-| A domain could be prohibited from being embedded for two reasons, either the user has not censented to the type of cookies that the host uses, or we have no information about a host. Since cookies are opt-in by law, we have to disable any unknown hosts since we cannot garantee that the host won't place any cookies not allowed by the user.
-}
type ConsentError
    = NoConsent String
    | UnknownHost


{-| An empty list serves as the list of hosts before the data has been initialized through the port.
-}
defaultHosts : List Host
defaultHosts =
    []


{-| Determine of the host's cookies have been accepted
-}
hasGivenConsent : String -> List Host -> Result ConsentError ()
hasGivenConsent hostName hosts =
    hosts
        |> List.filter (\(Host { name }) -> name == hostName)
        |> List.head
        |> Maybe.map hostIsActive
        |> Maybe.withDefault (Err UnknownHost)


hostIsActive : Host -> Result ConsentError ()
hostIsActive (Host internals) =
    if internals.isActive then
        Ok ()

    else
        Err (NoConsent internals.groupName)


toHosts : List Group -> List String -> List Host
toHosts allGroups activeGroupIds =
    List.concatMap (groupToHosts activeGroupIds) allGroups


groupToHosts : List String -> Group -> List Host
groupToHosts activeGroupIds group =
    List.map (groupToHost group.name (List.member group.id activeGroupIds)) group.hosts


groupToHost : String -> Bool -> { id : String, name : String } -> Host
groupToHost groupName isActive { id, name } =
    Host
        { id = id
        , name = name
        , groupName = groupName
        , isActive = isActive
        }


{-| Decodes 2 keys into the list of hosts, `allGroups` must include the data from `window.Optanon?.GetDomainData?.().Groups` and `activeGroupIdsString` must include the data from `OptanonActiveGroups`.
-}
decoder : Decoder (List Host)
decoder =
    Decode.map2 toHosts
        (Decode.field "allGroups" (Decode.list groupDecoder))
        (Decode.field "activeGroupIdsString" activeGroupsDecoder)


activeGroupsDecoder : Decoder (List String)
activeGroupsDecoder =
    Decode.string
        |> Decode.map
            (\str ->
                str
                    |> String.split ","
                    |> List.filter (String.isEmpty >> not)
            )


groupDecoder : Decoder Group
groupDecoder =
    Decode.map3 Group
        (Decode.field "GroupName" Decode.string)
        (Decode.field "CustomGroupId" Decode.string)
        (Decode.field "Hosts" (Decode.list groupHostDecoder))


groupHostDecoder : Decoder { id : String, name : String }
groupHostDecoder =
    Decode.map2 (\id name -> { id = id, name = name })
        (Decode.field "HostId" Decode.string)
        (Decode.field "DisplayName" Decode.string)
