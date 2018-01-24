port module Ports exposing (plot)

import Data exposing (ChartOptions, Show)


port plot : ( Show, ChartOptions ) -> Cmd msg
