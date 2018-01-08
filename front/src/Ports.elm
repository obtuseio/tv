port module Ports exposing (plot)

import Data exposing (Series)


port plot : Series -> Cmd msg
