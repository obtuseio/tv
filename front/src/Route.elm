module Route exposing (..)

import Navigation
import UrlParser exposing (..)


type Route
    = Home
    | Show String


routes : Parser (Route -> c) c
routes =
    oneOf
        [ map Home top
        , map Show string
        ]


parse : Navigation.Location -> Maybe Route
parse =
    parsePath routes
