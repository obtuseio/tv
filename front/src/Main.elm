module Main exposing (..)

import Data exposing (..)
import Html exposing (..)
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
    }


init : ( Model, Cmd Msg )
init =
    { index = [] } ! [ Request.index |> Http.send LoadIndex ]



-- UPDATE


type Msg
    = LoadIndex (Result Http.Error (List Series))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadIndex (Ok index) ->
            { model | index = index } ! []

        LoadIndex (Err error) ->
            { model | index = [] } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ ul []
            (model.index
                |> List.take 10
                |> List.map (\series -> li [] [ text series.primaryTitle ])
            )
        ]
