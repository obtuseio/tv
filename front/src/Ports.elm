port module Ports exposing (plot)

import Data exposing (Chart)


port plot : Chart -> Cmd msg
