module Request exposing (..)

import Data exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder)


decodeRating : Decoder Rating
decodeRating =
    Decode.map2 Rating
        (Decode.field "a" Decode.float)
        (Decode.field "c" Decode.int)


decodeEpisode : Decoder Episode
decodeEpisode =
    Decode.map7 Episode
        (Decode.field "id" Decode.string)
        (Decode.field "pt" Decode.string)
        (Decode.field "sy" Decode.int)
        (Decode.field "ey" (Decode.maybe Decode.int))
        (Decode.field "sn" Decode.int)
        (Decode.field "en" Decode.int)
        (Decode.field "r" decodeRating)


decodeShow : Decoder Show
decodeShow =
    Decode.map6 Show
        (Decode.field "id" Decode.string)
        (Decode.field "pt" Decode.string)
        (Decode.field "sy" Decode.int)
        (Decode.field "ey" (Decode.maybe Decode.int))
        (Decode.field "r" decodeRating)
        (Decode.oneOf [ Decode.field "es" (Decode.list decodeEpisode), Decode.succeed [] ])


shows : Http.Request (List Show)
shows =
    Http.get "/data/shows.json" (Decode.list decodeShow)


show : String -> Http.Request Show
show id =
    Http.get ("/data/shows/" ++ id ++ ".json") decodeShow
