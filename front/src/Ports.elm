port module Ports exposing (plot)

import Data exposing (Show)


port plot : Show -> Cmd msg
