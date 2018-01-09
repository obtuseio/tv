module Main exposing (..)

import Data exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href, style, target, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Encode
import Navigation exposing (Location)
import Ports
import Regex
import Request
import Route
import Series
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
    { index : List Series
    , query : String
    , series : Maybe Series.Model
    , pendingRequests : Int
    }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, cmd1 ) =
            update (Goto location)
                { index = []
                , query = ""
                , pendingRequests = 1
                , series = Nothing
                }

        cmd2 =
            Request.index |> Http.send LoadIndex
    in
    ( model, Cmd.batch [ cmd1, cmd2 ] )



-- UPDATE


type Msg
    = LoadIndex (Result Http.Error (List Series))
    | LoadSeries (Result Http.Error Series)
    | UpdateQuery String
    | Select String
    | Reset
    | Goto Location
    | SeriesMsg Series.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        done model =
            { model | pendingRequests = model.pendingRequests - 1 }
    in
    case msg of
        LoadIndex (Ok index) ->
            done { model | index = index } ! []

        LoadIndex (Err error) ->
            done { model | index = [] } ! []

        LoadSeries (Ok series) ->
            done { model | query = series.primaryTitle, series = Just <| Series.init series } ! [ Ports.plot series ]

        LoadSeries (Err error) ->
            done { model | series = Nothing } ! []

        UpdateQuery query ->
            { model | query = query } ! []

        Select id ->
            { model | query = "" }
                ! [ Navigation.newUrl ("/" ++ id) ]

        Reset ->
            { model | series = Nothing, query = "" } ! []

        Goto location ->
            case Route.parse location of
                Just Route.Home ->
                    model ! []

                Just (Route.Series id) ->
                    { model | pendingRequests = model.pendingRequests + 1 }
                        ! [ Request.series id |> Http.send LoadSeries ]

                Nothing ->
                    model ! []

        SeriesMsg msg ->
            case model.series of
                Just series ->
                    let
                        ( series2, cmd ) =
                            Series.update msg series
                    in
                    { model | series = Just series2 } ! [ cmd |> Cmd.map SeriesMsg ]

                Nothing ->
                    model ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        query =
            model.query |> String.toLower

        filtered =
            model.index
                |> List.filter (\series -> series.primaryTitle |> String.toLower |> String.contains query)
                |> List.sortBy
                    (\series ->
                        let
                            first =
                                if series.primaryTitle |> String.toLower |> String.startsWith query then
                                    0
                                else
                                    1

                            second =
                                -series.rating.count
                        in
                        ( first, second )
                    )
                |> List.take 12

        isJust maybe =
            case maybe of
                Just _ ->
                    True

                Nothing ->
                    False

        isNothing =
            not << isJust
    in
    div []
        [ h1 [ class "ui center aligned header", onClick Reset ] [ text "tv.obtuse.io" ]
        , a [ class "ui black github button", href "https://github.com/obtuseio/tv" ] [ text "GitHub" ]
        , div
            [ class "ui fluid search dropdown selection active visible"
            , classList
                [ ( "current", isJust model.series )
                , ( "loading", model.pendingRequests > 0 )
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
                    (if isJust model.series then
                        "out"
                     else
                        "in"
                    )
                , style
                    [ ( "display"
                      , if isJust model.series then
                            "block"
                        else
                            "none"
                      )
                    ]
                ]
                (filtered
                    |> List.map
                        (\series ->
                            div [ class "item unselectable", onClick (Select series.id) ]
                                [ strong [ highlight query series.primaryTitle ] []
                                , text <|
                                    " ["
                                        ++ toString series.startYear
                                        ++ "-"
                                        ++ (Maybe.map toString series.endYear |> Maybe.withDefault "")
                                        ++ "] ("
                                        ++ toString series.rating.average
                                        ++ "/10 - "
                                        ++ Util.formatInt series.rating.count
                                        ++ " votes)"
                                ]
                        )
                )
            ]
        , case model.series of
            Just series ->
                Series.view series |> Html.map SeriesMsg

            Nothing ->
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
