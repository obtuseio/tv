module Util exposing (..)


formatInt : Int -> String
formatInt number =
    let
        go string =
            if String.length string > 3 then
                String.left 3 string ++ "," ++ go (String.dropLeft 3 string)
            else
                string
    in
    number |> toString |> String.reverse |> go |> String.reverse
