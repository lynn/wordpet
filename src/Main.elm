import Dom
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Html exposing (..)
import Task

import AnimationFrame
import Time exposing (Time)

import Dict
import Markov
import Random.Pcg as Random

import Compromise
import Debug
import Maybe.Extra as Maybe


type alias Model =
  { babbles : Markov.Model Char
  , speech  : Markov.Model String
  , hatched : Bool
  , meal : String
  , eating : Maybe Time
  , voice : String }

type Msg
  = Idle
  | TrackInput String
  | Feed
  | Babble
  | Speak
  | Display String
  | ChompTick Time
  -- NLP ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String

main : Program Never Model Msg
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
        [ id "plate"
        , onInput TrackInput
        , placeholder "feed paragraphs"
        , value model.meal
        , disabled <| model.eating /= Nothing ]
        []
      , button
        [onClick Feed, disabled (String.isEmpty model.meal)]
        [text "Feed!"] ]
    else
      [ input
        [ id "plate"
        , onInput TrackInput
        , onEnter Feed
        , placeholder "feed words"
        , value model.meal
        , disabled <| model.eating /= Nothing
        , autofocus True ]
        [] ]

speechBox : Model -> Html Msg
speechBox model = p [] [text model.voice]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  Idle -> model ! []
  TrackInput text ->
    { model | meal = text } ! []
  Feed ->
    if String.isEmpty model.meal
      then model ! [] -- TODO give some sort of feedback?
      else
        { model
          | eating = Just 0
          , babbles = Markov.addSample 1 (String.toList model.meal) model.babbles }
        ! []
  ChompTick diff ->
    case model.eating of
      Nothing -> model ! []
      Just timer ->
        if timer <= 0
          then
            let
              remaining = String.dropLeft 1 model.meal
              done = String.isEmpty remaining
            in
              { model
                | meal = remaining
                , eating = if done
                  then Nothing
                  else Just <| 100 * Time.millisecond }
              ! if done
                then [babble model, refocusPlate]
                else []
          else { model | eating = Just <| timer - diff } ! []
  Babble ->
    model ! [babble model]
  Speak ->
    model ! [speak model]
  Display text ->
    { model | voice = text } ! []
  ReceivedSentences sentences ->
    Debug.log (toString sentences) model ! [] -- TODO
  ReceivedNormalize normalizedText ->
    Debug.log (toString normalizedText) model ! [] -- TODO

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    when cond sub = if cond then sub else Sub.none
  in Sub.batch
    -- Listen to chomp ticks so long as we're eating words.
    [ when (Maybe.isJust model.eating) (AnimationFrame.diffs ChompTick)
    -- Always listen to Compromise ports.
    , Compromise.receiveSentences ReceivedSentences
    , Compromise.receiveNormalize ReceivedNormalize ]

babble : Model -> Cmd Msg
babble = sample 1 String.fromList << .babbles

speak : Model -> Cmd Msg
speak = sample 2 (String.join "") << .speech

sample : Int -> (List comparable -> String) -> Markov.Model comparable -> Cmd Msg
sample n k = Random.generate (Display << k) << Markov.walk n

refocusPlate : Cmd Msg
refocusPlate = Task.attempt (always Idle) <| Dom.focus "plate"
