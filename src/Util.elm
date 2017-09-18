module Util exposing (..)

addCmd : Cmd msg -> (model, Cmd msg) -> (model, Cmd msg)
addCmd ours = Tuple.mapSecond <|
  \ theirs -> Cmd.batch [ours, theirs]
