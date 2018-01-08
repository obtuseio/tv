module Request exposing (..)

import Data exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder)


decodeRating : Decoder Rating
decodeRating =
    Decode.map2 Rating
        (Decode.field "a" Decode.float)
        (Decode.field "c" Decode.int)


decodeSeries : Decoder Series
decodeSeries =
    Decode.map5 Series
        (Decode.field "id" Decode.string)
        (Decode.field "pt" Decode.string)
        (Decode.field "sy" Decode.int)
        (Decode.field "ey" (Decode.maybe Decode.int))
        (Decode.field "r" decodeRating)


index : Http.Request (List Series)
index =
    Http.get "/data/series.json" (Decode.list decodeSeries)
