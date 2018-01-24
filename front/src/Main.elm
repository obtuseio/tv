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
    , isOpen : Bool
    , chartOptions : ChartOptions
    }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, cmd1 ) =
            update (Goto location)
                { shows = Loading
                , query = ""
                , show = NotAsked
                , isOpen = True
                , chartOptions = ChartOptions False False True
                }

        cmd2 =
            Request.shows |> RemoteData.sendRequest |> Cmd.map ShowsResponse
    in
    ( model, Cmd.batch [ cmd1, cmd2 ] )



-- UPDATE


type Msg
    = ShowsResponse (WebData (List Show))
    | ShowResponse (WebData Show)
    | UpdateQuery String
    | Select String
    | Reset
    | Goto Location
    | ShowMsg Show.Msg
    | ToggleDropdown


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ShowsResponse shows ->
            { model | shows = shows } ! []

        ShowResponse (Success show) ->
            let
                ( showModel, cmd ) =
                    Show.init show model.chartOptions
            in
            { model | query = show.primaryTitle, show = Success showModel } ! [ cmd ]

        ShowResponse show ->
            { model | show = show |> RemoteData.map (flip Show.init model.chartOptions >> Tuple.first) } ! []

        UpdateQuery query ->
            { model | query = query } ! []

        Select id ->
            { model | query = "" }
                ! [ Navigation.newUrl ("/" ++ id) ]

        Reset ->
            model ! [ Navigation.newUrl "/" ]

        Goto location ->
            case Route.parse location of
                Just Route.Home ->
                    { model | isOpen = True, query = "", show = NotAsked } ! []

                Just (Route.Show id) ->
                    { model | show = Loading, isOpen = False }
                        ! [ Request.show id |> RemoteData.sendRequest |> Cmd.map ShowResponse ]

                Nothing ->
                    model ! []

        ShowMsg msg ->
            case model.show of
                Success show ->
                    let
                        ( show2, cmd, chartOptions ) =
                            Show.update msg show model.chartOptions
                    in
                    { model
                        | chartOptions = chartOptions
                        , show = Success show2
                    }
                        ! [ cmd |> Cmd.map ShowMsg ]

                _ ->
                    model ! []

        ToggleDropdown ->
            case ( model.isOpen, model.show ) of
                ( True, Success { show } ) ->
                    { model | isOpen = False, query = show.primaryTitle } ! []

                _ ->
                    { model | isOpen = True, query = "" } ! []



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
                [ ( "current", not model.isOpen )
                , ( "loading", isLoading )
                ]
            ]
            [ i [ class "dropdown icon unclickable" ] []
            , input [ class "search", value model.query, onClick ToggleDropdown, onInput UpdateQuery ] []
            , div [ class "default text", classList [ ( "filtered", query /= "" ) ] ]
                [ text "Type the name of the show here..."
                ]
            , div
                [ class "menu transition visible animating slide down"
                , class
                    (if model.isOpen then
                        "in"
                     else
                        "out"
                    )
                , style
                    [ ( "display"
                      , if model.isOpen then
                            "none"
                        else
                            "block"
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
                Show.view show model.chartOptions |> Html.map ShowMsg

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
