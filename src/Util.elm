module Util exposing (..)

addCmd : Cmd msg -> (model, Cmd msg) -> (model, Cmd msg)
addCmd ours (model, theirs) = (model, Cmd.batch [ours, theirs])

joinCmds : ((model, Cmd msg), Cmd msg) -> (model, Cmd msg)
joinCmds (pair, cmd) = addCmd cmd pair

cmdThen : (a -> (b, Cmd msg)) -> (a, Cmd msg) -> (b, Cmd msg)
cmdThen f (a, cmd) = addCmd cmd (f a)
