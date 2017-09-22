import Random.Pcg as Random exposing (Generator)
import Html exposing (..)

import AnimationFrame
import ChompAnimation
import Critter
import Dizzy
import FoodProcessor
import Speech

import Compromise
import Debug
import Util

import Maybe.Extra as Maybe

import Model exposing (Model)
import Msg exposing (..)

import SFX
import View


main : Program Never Model Msg
main = program
  { init = Model.initial ! [Random.generate SetCritter Critter.generator]
  , view = View.view
  , update = update
  , subscriptions = subscriptions }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  Idle -> model ! []
  TrackInput text ->
    FoodProcessor.process { model | meal = text } ! []
  Feed ->
    if String.isEmpty model.meal
      then model ! [] -- TODO give some sort of feedback?
      else Speech.train model
        |> Util.cmdThen ChompAnimation.setup
  ChompTick diff -> ChompAnimation.tick diff model
  DizzyTick diff -> Dizzy.tick diff model ! []
  Pet ->
    if Maybe.isJust model.hatched
      then Speech.speak <| Dizzy.stimulate model -- TODO maybe change pet sfx when overstimulated
      else model ! [SFX.play SFX.Chirp] -- TODO: some sort of better feedback for petting the egg
  Vocalize voicetype voice ->
    maybeHatch { model | voice = voice } ! [Speech.handleSpeech voicetype]
  ResetBabbleTimer t ->
    { model | babbleTimer = t } ! []
  SetCritter c ->
    { model | critter = c } ! []
  ReceivedSentences sentences ->
    Speech.trainSpeech sentences model ! []
  ReceivedNormalize normalizedText ->
    Debug.log (toString normalizedText) model ! [] -- TODO

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    when cond sub = if cond then sub else Sub.none
  in Sub.batch
    -- Listen to chomp ticks so long as we're eating words.
    [ when (Maybe.isJust model.eating) (AnimationFrame.diffs ChompTick)
    -- Listen to dizzy ticks if we're
    , when (model.dizziness /= Model.Calm) (AnimationFrame.diffs DizzyTick)
    -- Always listen to Compromise ports.
    , Compromise.receiveSentences ReceivedSentences
    , Compromise.receiveNormalize ReceivedNormalize ]

-- the first time we babble, hatch and set our name to our first word
maybeHatch : Model -> Model
maybeHatch model =
  case model.hatched of
    Just _ -> model
    -- `model.voice` will be punctuated, so strip that first
    Nothing -> { model | hatched =
      Just <| String.dropRight 1 model.voice }
