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


decodeSeries : Decoder Series
decodeSeries =
    Decode.map6 Series
        (Decode.field "id" Decode.string)
        (Decode.field "pt" Decode.string)
        (Decode.field "sy" Decode.int)
        (Decode.field "ey" (Decode.maybe Decode.int))
        (Decode.field "r" decodeRating)
        (Decode.oneOf [ Decode.field "es" (Decode.list decodeEpisode), Decode.succeed [] ])


index : Http.Request (List Series)
index =
    Http.get "/data/series.json" (Decode.list decodeSeries)


series : String -> Http.Request Series
series id =
    Http.get ("/data/series/" ++ id ++ ".json") decodeSeries
