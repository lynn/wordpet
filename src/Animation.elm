port module Animation exposing (..)

{-| Animate #critter by temporarily adding the given class name. -}
port trigger : String -> Cmd msg
