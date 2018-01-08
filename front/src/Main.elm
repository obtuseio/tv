module Main exposing (..)

import Data exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, classList, value)
import Html.Events exposing (onClick, onInput)
import Http
import Request


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    { index : List Series
    , query : String
    , current : Maybe Series
    }


init : ( Model, Cmd Msg )
init =
    { index = [], query = "", current = Nothing } ! [ Request.index |> Http.send LoadIndex ]



-- UPDATE


type Msg
    = LoadIndex (Result Http.Error (List Series))
    | UpdateQuery String
    | Select Series
    | Reset


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadIndex (Ok index) ->
            { model | index = index } ! []

        LoadIndex (Err error) ->
            { model | index = [] } ! []

        UpdateQuery query ->
            { model | query = query } ! []

        Select series ->
            { model | current = Just series, query = series.primaryTitle } ! []

        Reset ->
            { model | current = Nothing, query = "" } ! []



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

        when condition node =
            if condition then
                node
            else
                text ""
    in
    div []
        [ div [ class "ui fluid search dropdown selection active visible", classList [ ( "current", isJust model.current ) ] ]
            [ input [ class "search", value model.query, onClick Reset, onInput UpdateQuery ] []
            , div [ class "default text", classList [ ( "filtered", query /= "" ) ] ]
                [ text "Type the name of the show here..."
                ]
            , when (isNothing model.current) <|
                div [ class "menu transition visible" ]
                    (filtered
                        |> List.map
                            (\series ->
                                div [ class "item", onClick (Select series) ]
                                    [ text <|
                                        series.primaryTitle
                                            ++ " ("
                                            ++ toString series.rating.average
                                            ++ "/10 from "
                                            ++ toString series.rating.count
                                            ++ " votes)"
                                    ]
                            )
                    )
            ]
        ]
