module Route exposing (..)

import Navigation
import UrlParser exposing (..)


type Route
    = Home
    | Series String


routes : Parser (Route -> c) c
routes =
    oneOf
        [ map Home top
        , map Series string
        ]


parse : Navigation.Location -> Maybe Route
parse =
    parsePath routes
