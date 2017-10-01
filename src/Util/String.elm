module Util.String exposing (..)

words : String -> List String
words s =
  case String.words s of
    [""] -> []
    ws -> ws
