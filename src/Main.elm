import Dom
import Dom.Scroll
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

import SFX

import Model exposing (Model)
import Msg exposing (..)
import View


main : Program Never Model Msg
main = program
  { init = Model.initial ! []
  , view = View.view
  , update = update
  , subscriptions = subscriptions }

-- Take a bite out of the meal, and reset the eatingTimer if we're not done eating.
-- If we are done eating, chirp, refocus the plate, and maybe babble.
chomp : Int -> Model -> (Model, Cmd Msg)
chomp chunkSize model =
  let
    remaining = String.dropLeft chunkSize model.meal
    done = String.isEmpty remaining
  in
    { model
      | meal = remaining
      , eating = if done
        then Nothing
        else Just { timer = 150 * Time.millisecond, chunkSize = chunkSize }
      , voice = if done then "" else "♫" }
    ! if done
      then [refocusPlate, maybeBabble model]
      else []

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  Idle -> model ! []
  TrackInput text ->
    { model | meal = text } ! []
  Feed ->
    if String.isEmpty model.meal
      then model ! [] -- TODO give some sort of feedback?
      else train
        { model
          | eating = Just
            { timer = 0
            , chunkSize =
              if Maybe.isJust model.hatched
                then Basics.max 8 (String.length model.meal // 8)
                else 1 }
          , babbleTimer = model.babbleTimer - 1 }
  ChompTick diff ->
    case model.eating of
      Nothing -> model ! []
      Just ({timer, chunkSize} as eating) ->
        if timer <= 0
          then chomp chunkSize model
          else { model | eating = Just { eating | timer = timer - diff } } ! []
  Pet ->
    if Maybe.isJust model.hatched
      then { model | babbleTimer = model.babbleTimer - 1 } ! [speak model]
      else model ! [SFX.play SFX.Chirp] -- TODO: some sort of better feedback for petting the egg
  Babble bab ->
    maybeHatch bab { model | voice = bab } ! []
  Speak speech ->
    { model | voice = speech } ! []
  ResetBabbleTimer t ->
    { model | babbleTimer = t } ! []
  ReceivedSentences sentences ->
    trainSpeech sentences model ! []
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
babble model = Cmd.batch
  [ sample 1 (Babble << String.fromList) model.babbles
  , Random.generate ResetBabbleTimer <| Random.int 10 25 ]

-- the first time we babble, hatch and set our name to our first word
maybeHatch : String -> Model -> Model
maybeHatch bab model =
  case model.hatched of
    Just _ -> model
    Nothing -> { model | hatched = Just bab }

sample : Int -> (List comparable -> Msg) -> Markov.Model comparable -> Cmd Msg
sample n k = Random.generate k << Markov.walk n

refocusPlate : Cmd Msg
refocusPlate = Task.attempt (always Idle) <| Dom.focus "plate"

scrollPlate : Cmd Msg
scrollPlate = Task.attempt (always Idle) <| Dom.Scroll.toTop "plate"

maybeBabble : Model -> Cmd Msg
maybeBabble model = if model.babbleTimer == 0
  then babble model
  else Cmd.none

speak : Model -> Cmd Msg
speak model = if model.babbleTimer == 0 || Dict.isEmpty model.speech
  then babble model
  else sample 2 (Speak << String.join " ") model.speech

train : Model -> (Model, Cmd Msg)
train model = case model.hatched of
  Nothing ->
    -- not yet hatched! train the babble model
    { model
      | babbles = Markov.addSample 1 (String.toList model.meal) model.babbles }
    ! []
  Just _ ->
    -- hatched! train the speech model.
    -- first we need to split the meal into sentences.
    -- also scroll the text entry to the top so the chomps are visible
    model ! [scrollPlate, Compromise.sentences model.meal]

-- train the speech model
-- TODO: need to normalize first
trainSpeech : List String -> Model -> Model
trainSpeech sentences model =
  let
    addSentence sentence = Markov.addSample 2 (String.split " " sentence)
  in
    { model
      | speech = List.foldl addSentence model.speech sentences }
