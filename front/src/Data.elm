module Data exposing (..)


type alias Rating =
    { average : Float
    , count : Int
    }


type alias Episode =
    { id : String
    , primaryTitle : String
    , startYear : Int
    , endYear : Maybe Int
    , seasonNumber : Int
    , episodeNumber : Int
    , rating : Rating
    }


type alias Series =
    { id : String
    , primaryTitle : String
    , startYear : Int
    , endYear : Maybe Int
    , rating : Rating
    , episodes : List Episode
    }
