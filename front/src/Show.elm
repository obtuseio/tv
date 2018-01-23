module Show exposing (..)

import Data exposing (Show)
import Html exposing (..)
import Html.Attributes exposing (class, classList, href, id, target, value)
import Html.Events exposing (onClick, onInput)
import Ports
import Round
import Util


-- MODEL


type Column
    = Number
    | Rating
    | Votes


type Order
    = Asc
    | Desc


type alias Model =
    { show : Show
    , sort :
        { by : Column
        , order : Order
        }
    , ratingFromZero : Bool
    , showTrend : Bool
    }


init : Show -> ( Model, Cmd msg )
init show =
    plot <| Model show { by = Number, order = Asc } False False


plot : Model -> ( Model, Cmd msg )
plot ({ show, ratingFromZero, showTrend } as model) =
    model ! [ Ports.plot { show = show, ratingFromZero = ratingFromZero, showTrend = showTrend } ]



-- UPDATE


type Msg
    = SortBy Column
    | ToggleRatingFromZero
    | ToggleShowTrend


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SortBy column ->
            if model.sort.by == column then
                let
                    sort =
                        { by = model.sort.by
                        , order =
                            if model.sort.order == Asc then
                                Desc
                            else
                                Asc
                        }
                in
                { model | sort = sort } ! []
            else
                { model
                    | sort = { by = column, order = Asc }
                }
                    ! []

        ToggleRatingFromZero ->
            plot { model | ratingFromZero = not model.ratingFromZero }

        ToggleShowTrend ->
            plot { model | showTrend = not model.showTrend }



-- VIEW


view : Model -> Html Msg
view model =
    let
        sortIcon column =
            text <|
                if column == model.sort.by then
                    if model.sort.order == Asc then
                        " ▴"
                    else
                        " ▾"
                else
                    ""

        episodes =
            let
                order =
                    if model.sort.order == Asc then
                        1
                    else
                        -1
            in
            case model.sort.by of
                Number ->
                    model.show.episodes |> List.sortBy (\e -> ( e.seasonNumber * order, e.episodeNumber * order ))

                Rating ->
                    model.show.episodes |> List.sortBy (\e -> e.rating.average * order)

                Votes ->
                    model.show.episodes |> List.sortBy (\e -> e.rating.count * order)
    in
    div []
        [ div [ id "chart" ] []
        , div [ class "ui center aligned segment" ]
            [ div
                [ class "ui button"
                , classList
                    [ ( "green", model.ratingFromZero ) ]
                , onClick ToggleRatingFromZero
                ]
                [ text "Plot Rating from 0?" ]
            , div
                [ class "ui button"
                , classList
                    [ ( "green", model.showTrend ) ]
                , onClick ToggleShowTrend
                ]
                [ text "Show Show Trend?" ]
            ]
        , table [ class "ui unstackable compact selectable celled table" ]
            [ thead []
                [ tr []
                    [ th [ class "right aligned sortable unselectable", onClick (SortBy Number) ] [ text "#", sortIcon Number ]
                    , th [ class "unselectable" ] [ text "Episode" ]
                    , th [ class "right aligned sortable unselectable", onClick (SortBy Rating) ] [ text "Rating", sortIcon Rating ]
                    , th [ class "right aligned sortable unselectable", onClick (SortBy Votes) ] [ text "Votes", sortIcon Votes ]
                    , th [] []
                    ]
                ]
            , tbody
                []
                (episodes
                    |> List.map
                        (\episode ->
                            tr []
                                [ td [ class "right aligned" ] [ text <| toString episode.seasonNumber ++ "." ++ toString episode.episodeNumber ]
                                , td [] [ text episode.primaryTitle ]
                                , td [ class "right aligned" ] [ text <| Round.round 1 <| episode.rating.average ]
                                , td [ class "right aligned" ] [ text <| Util.formatInt <| episode.rating.count ]
                                , td []
                                    [ a
                                        [ class "mini ui yellow button"
                                        , href ("https://www.imdb.com/title/" ++ episode.id)
                                        , target "_blank"
                                        ]
                                        [ text "IMDb" ]
                                    ]
                                ]
                        )
                )
            ]
        ]
