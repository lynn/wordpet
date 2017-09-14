import Html exposing (..)
import Html.Events exposing (..)
import Dict
import Random.Pcg as Random exposing (Generator, generate)

import Markov

type alias Model = String

type Msg
  = GetSample
  | GotSample (List Char)

main = program
  { init = "" ! [sample]
  , view = view
  , update = update
  , subscriptions = \ _ -> Sub.none }

markovModel : Markov.Model Char
markovModel = Markov.addSample 1 ['c', 'o', 'o', 'l'] Dict.empty

view : Model -> Html Msg
view model = button [onClick GetSample] [text model]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  GetSample ->
    model ! [sample]
  GotSample text ->
    String.fromList text ! []

sample : Cmd Msg
sample = generate GotSample <| Markov.walk 1 markovModel
