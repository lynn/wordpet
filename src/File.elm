port module File exposing (..)

{-| Start a download for a file with the given file name and contents. -}
port download : (String, String) -> Cmd msg

{-| Open a file upload dialog. -}
port upload : () -> Cmd msg

{-| Port for received file contents. -}
port receiveContents : (String -> msg) -> Sub msg
