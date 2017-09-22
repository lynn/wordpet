import Random.Pcg as Random exposing (Generator)
import Html exposing (..)

import AnimationFrame

import ChompAnimation
import Speech

import Compromise
import Critter
import Debug
import Maybe.Extra as Maybe
import Util

import SFX

import Model exposing (Model)
import Msg exposing (..)
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
    { model | meal = text } ! []
  Feed ->
    if String.isEmpty model.meal
      then model ! [] -- TODO give some sort of feedback?
      else ChompAnimation.setup model
        |> Util.cmdThen Speech.train
  ChompTick diff -> ChompAnimation.tick diff model
  Pet ->
    if Maybe.isJust model.hatched
      then Speech.speak model
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
