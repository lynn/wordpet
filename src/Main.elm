import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Dict
import Random.Pcg as Random
import Time exposing (Time)
import AnimationFrame

import Markov

type alias Model =
  { babbles : Markov.Model Char
  , speech  : Markov.Model String
  , hatched : Bool
  , meal : String
  , eating : Maybe Time
  , voice : String }

type Msg
  = TrackInput String
  | Feed
  | Babble
  | Speak
  | Display String
  | ChompTick Time

main = program
  { init = initialModel ! []
  , view = view
  , update = update
  , subscriptions = subscriptions }

initialModel : Model
initialModel =
  { babbles = Dict.empty
  , speech  = Dict.empty
  , hatched = False
  , meal = ""
  , eating = Nothing
  , voice = "" }

view : Model -> Html Msg
view model = div []
  [ inputArea model
  , speechBox model ]

inputArea : Model -> Html Msg
inputArea model = div [] <|
  if model.hatched
    then
      [ textarea
        [ onInput TrackInput
        , placeholder "feed paragraphs"
        , value model.meal
        , disabled <| model.eating /= Nothing ]
        []
      , button
        [onClick Feed, disabled (String.isEmpty model.meal)]
        [text "Feed!"] ]
    else
      [ input
        [ onInput TrackInput
        , onEnter Feed
        , placeholder "feed words"
        , value model.meal
        , disabled <| model.eating /= Nothing ]
        [] ]

speechBox : Model -> Html Msg
speechBox model = p [] [text model.voice]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  TrackInput text ->
    { model | meal = text } ! []
  Feed ->
    { model | eating = Just 0 } ! []
  ChompTick diff ->
    case model.eating of
      Nothing -> model ! []
      Just timer ->
        if timer <= 0
          then
            let
              remaining = String.dropLeft 1 model.meal
            in
              { model
                | meal = remaining
                , eating = if String.isEmpty remaining
                  then Nothing
                  else Just <| 100 * Time.millisecond } ! []
          else { model | eating = Just <| timer - diff } ! []
  Babble ->
    model ! [sample 1 String.fromList model.babbles]
  Speak ->
    model ! [sample 2 (String.join "") model.speech]
  Display text ->
    { model | voice = text } ! []

subscriptions : Model -> Sub Msg
subscriptions model = AnimationFrame.diffs ChompTick

sample : Int -> (List comparable -> String) -> Markov.Model comparable -> Cmd Msg
sample n k = Random.generate (Display << k) << Markov.walk n
