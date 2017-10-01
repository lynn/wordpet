port module Download exposing (..)

{-| Start a download for a file with the given file name and contents. -}
port download : (String, String) -> Cmd msg
