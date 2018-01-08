module Data exposing (..)


type alias Rating =
    { average : Float
    , count : Int
    }


type alias Series =
    { id : String
    , primaryTitle : String
    , startYear : Int
    , endYear : Maybe Int
    , rating : Rating
    }
