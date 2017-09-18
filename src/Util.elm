module Util exposing (..)

addCmd : Cmd msg -> (model, Cmd msg) -> (model, Cmd msg)
addCmd ours = Tuple.mapSecond <|
  \ theirs -> Cmd.batch [ours, theirs]

joinCmds : ((model, Cmd msg), Cmd msg) -> (model, Cmd msg)
joinCmds (pair, cmd) = addCmd cmd pair

cmdThen : (a -> (b, Cmd msg)) -> (a, Cmd msg) -> (b, Cmd msg)
cmdThen f a = joinCmds <| Tuple.mapFirst f a
