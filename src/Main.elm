import Html exposing (..)

main = beginnerProgram { model = (), view = view, update = update }

view model = span [] [text "hi"]

update msg model = model
