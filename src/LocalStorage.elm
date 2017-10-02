port module LocalStorage exposing (..)

{-| Save JSON-encoded model to local storage. -}
port saveModel : String -> Cmd msg

{-| Load model from local storage if possible. -}
port loadModel : () -> Cmd msg

{-| Answers from loadModel. An empty string reply signifies no model was loaded. -}
port receiveLoadModel : (String -> msg) -> Sub msg
