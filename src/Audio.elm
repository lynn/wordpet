port module Audio exposing (..)

{-| Ask for one sound from the given list of paths to be played at random. -}
port playOneOf : List String -> Cmd msg

{-| Ask for the sound at the given path to be played. -}
play : String -> Cmd msg
play sound = playOneOf [sound]
