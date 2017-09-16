port module Compromise exposing (..)

{-| Ask for `nlp(text).sentences().out('array')`. -}
port sentences : String -> Cmd msg

{-| Port for results from `sentences` requests. -}
port receiveSentences : (List String -> msg) -> Sub msg

{-| Ask for `nlp(text).normalize().out('text')`. -}
port normalize : String -> Cmd msg

{-| Port for results from `normalize` requests. -}
port receiveNormalize : (String -> msg) -> Sub msg
