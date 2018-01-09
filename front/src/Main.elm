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
    { shows : List Show
    , query : String
    , show : Maybe Show.Model
    , pendingRequests : Int
    }


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, cmd1 ) =
            update (Goto location)
                { shows = []
                , query = ""
                , pendingRequests = 1
                , show = Nothing
                }

        cmd2 =
            Request.shows |> Http.send LoadShows
    in
    ( model, Cmd.batch [ cmd1, cmd2 ] )



-- UPDATE


type Msg
    = LoadShows (Result Http.Error (List Show))
    | LoadShow (Result Http.Error Show)
    | UpdateQuery String
    | Select String
    | Reset
    | Goto Location
    | ShowMsg Show.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        done model =
            { model | pendingRequests = model.pendingRequests - 1 }
    in
    case msg of
        LoadShows (Ok shows) ->
            done { model | shows = shows } ! []

        LoadShows (Err error) ->
            done { model | shows = [] } ! []

        LoadShow (Ok show) ->
            done { model | query = show.primaryTitle, show = Just <| Show.init show } ! [ Ports.plot show ]

        LoadShow (Err error) ->
            done { model | show = Nothing } ! []

        UpdateQuery query ->
            { model | query = query } ! []

        Select id ->
            { model | query = "" }
                ! [ Navigation.newUrl ("/" ++ id) ]

        Reset ->
            { model | show = Nothing, query = "" } ! []

        Goto location ->
            case Route.parse location of
                Just Route.Home ->
                    model ! []

                Just (Route.Show id) ->
                    { model | pendingRequests = model.pendingRequests + 1 }
                        ! [ Request.show id |> Http.send LoadShow ]

                Nothing ->
                    model ! []

        ShowMsg msg ->
            case model.show of
                Just show ->
                    let
                        ( show2, cmd ) =
                            Show.update msg show
                    in
                    { model | show = Just show2 } ! [ cmd |> Cmd.map ShowMsg ]

                Nothing ->
                    model ! []



-- VIEW


view : Model -> Html Msg
view model =
    let
        query =
            model.query |> String.toLower

        filtered =
            model.shows
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
        , h3 [ class "ui center aligned header" ] [ text "Visualize IMDb Ratings of any TV Show's Episodes" ]
        , a [ class "ui black github button", href "https://github.com/obtuseio/tv" ] [ text "GitHub" ]
        , div
            [ class "ui fluid search dropdown selection active visible"
            , classList
                [ ( "current", isJust model.show )
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
                    (if isJust model.show then
                        "out"
                     else
                        "in"
                    )
                , style
                    [ ( "display"
                      , if isJust model.show then
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
            Just show ->
                Show.view show |> Html.map ShowMsg

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
