module Main exposing (..)

import Data exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href, style, target, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode
import Navigation exposing (Location)
import Ports
import Regex
import RemoteData exposing (RemoteData(..), WebData)
import Request
import Route
import Show
import Util


main : Program Never Model Msg
main =
    Navigation.program Goto
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { shows : WebData (List Show)
    , query : String
    , show : WebData Show.Model
    }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, cmd1 ) =
            update (Goto location)
                { shows = Loading
                , query = ""
                , show = NotAsked
                }

        cmd2 =
            Request.shows |> RemoteData.sendRequest |> Cmd.map LoadShows
    in
    ( model, Cmd.batch [ cmd1, cmd2 ] )



-- UPDATE


type Msg
    = LoadShows (WebData (List Show))
    | LoadShow (WebData Show)
    | UpdateQuery String
    | Select String
    | Reset
    | Goto Location
    | ShowMsg Show.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadShows shows ->
            { model | shows = shows } ! []

        LoadShow (Success show) ->
            { model | query = show.primaryTitle, show = Success (Show.init show) } ! [ Ports.plot show ]

        LoadShow show ->
            { model | show = show |> RemoteData.map Show.init } ! []

        UpdateQuery query ->
            { model | query = query } ! []

        Select id ->
            { model | query = "" }
                ! [ Navigation.newUrl ("/" ++ id) ]

        Reset ->
            { model | show = NotAsked, query = "" } ! []

        Goto location ->
            case Route.parse location of
                Just Route.Home ->
                    model ! []

                Just (Route.Show id) ->
                    { model | show = Loading }
                        ! [ Request.show id |> RemoteData.sendRequest |> Cmd.map LoadShow ]

                Nothing ->
                    model ! []

        ShowMsg msg ->
            case model.show of
                Success show ->
                    let
                        ( show2, cmd ) =
                            Show.update msg show
                    in
                    { model | show = Success show2 } ! [ cmd |> Cmd.map ShowMsg ]

                _ ->
                    model ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        query =
            model.query |> String.toLower

        filtered =
            case model.shows of
                Success shows ->
                    shows
                        |> List.filter (\show -> show.primaryTitle |> String.toLower |> String.contains query)
                        |> List.sortBy
                            (\show ->
                                let
                                    first =
                                        if show.primaryTitle |> String.toLower |> String.startsWith query then
                                            0
                                        else
                                            1

                                    second =
                                        -show.rating.count
                                in
                                ( first, second )
                            )
                        |> List.take 12

                _ ->
                    []

        isLoading =
            model.shows == Loading || model.show == Loading
    in
    div []
        [ h1 [ class "ui center aligned header", onClick Reset ] [ text "tv.obtuse.io" ]
        , h3 [ class "ui center aligned header" ] [ text "Visualize IMDb Ratings of any TV Show's Episodes" ]
        , a [ class "ui black github button", href "https://github.com/obtuseio/tv" ] [ text "GitHub" ]
        , div
            [ class "ui fluid search dropdown selection active visible"
            , classList
                [ ( "current", RemoteData.isSuccess model.show )
                , ( "loading", isLoading )
                ]
            ]
            [ i [ class "dropdown icon unclickable" ] []
            , input [ class "search", value model.query, onClick Reset, onInput UpdateQuery ] []
            , div [ class "default text", classList [ ( "filtered", query /= "" ) ] ]
                [ text "Type the name of the show here..."
                ]
            , div
                [ class "menu transition visible animating slide down"
                , class
                    (if RemoteData.isSuccess model.show then
                        "out"
                     else
                        "in"
                    )
                , style
                    [ ( "display"
                      , if RemoteData.isSuccess model.show then
                            "block"
                        else
                            "none"
                      )
                    ]
                ]
                (filtered
                    |> List.map
                        (\show ->
                            div [ class "item unselectable", onClick (Select show.id) ]
                                [ strong [ highlight query show.primaryTitle ] []
                                , text <|
                                    " ["
                                        ++ toString show.startYear
                                        ++ "-"
                                        ++ (Maybe.map toString show.endYear |> Maybe.withDefault "")
                                        ++ "] ("
                                        ++ toString show.rating.average
                                        ++ "/10 - "
                                        ++ Util.formatInt show.rating.count
                                        ++ " votes)"
                                ]
                        )
                )
            ]
        , case model.show of
            Success show ->
                Show.view show |> Html.map ShowMsg

            _ ->
                text ""
        ]


highlight : String -> String -> Attribute msg
highlight query title =
    let
        regex =
            query |> Regex.escape |> Regex.regex |> Regex.caseInsensitive

        replaced =
            Regex.replace Regex.All regex (\{ match } -> "<mark>" ++ match ++ "</mark>") title
    in
    Html.Attributes.property "innerHTML" (Json.Encode.string replaced)
