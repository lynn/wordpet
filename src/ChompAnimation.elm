module ChompAnimation exposing (tick, setup)

import Dom
import Dom.Scroll
import Task

import Maybe.Extra as Maybe

import Time exposing (Time)

import Model exposing (Model)
import Msg exposing (Msg)

import SFX
import Speech

-- called each frame of animation in the browser; chomp every `duration`
tick : Time -> Model -> (Model, Cmd Msg)
tick diff model =
  case model.eating of
    Nothing -> model ! []
    Just ({timer, state} as eating) ->
      if timer <= 0
        then chomp state model
        else { model | eating = Just { eating | timer = timer - diff } } ! []

-- Take a bite out of the meal, and reset the eatingTimer if we're not done eating.
-- If we are done eating, chirp, refocus the plate, and maybe babble.
chomp : Model.MealState -> Model -> (Model, Cmd Msg)
chomp oldState model =
  let
    remaining : String
    remaining =
      case oldState of
        Model.Chomping {chunkSize} -> String.dropLeft chunkSize model.meal
        Model.Swallowing -> ""

    newState : Maybe Model.MealState
    newState =
      case oldState of
        Model.Swallowing -> Nothing
        Model.Chomping c -> Just <|
          if String.isEmpty remaining
            then Model.Swallowing
            else Model.Chomping c
  in
    { model
      | meal = remaining
      , eating = newState |> Maybe.map (\ state ->
        { timer = model.critter.chompDuration
        , state = state })
      , voice = if Maybe.isJust newState then "♫" else "" }
    ! case newState of
        Just _ -> -- still eating...
          [SFX.play SFX.Chomp]
        Nothing -> -- done!
          [SFX.play (if Maybe.isJust model.hatched then SFX.Gulp else if model.babbleTimer == 0 then SFX.Hatch else SFX.Rattle)
          , refocusPlate
          , Speech.maybeBabble model]

-- commands to run when we finish up eating
finishEating : Model -> Cmd Msg
finishEating model = Cmd.batch
  [ refocusPlate
  , Speech.maybeBabble model
  , SFX.play <|
    if Maybe.isJust model.hatched then
      SFX.Gulp
    else if model.babbleTimer == 0 then
      SFX.Hatch
    else
      SFX.Rattle ]

-- set up the chomp animation!
setup : Model -> (Model, Cmd Msg)
setup model =
  if model.hatched == Nothing then
    { model | meal = "" } ! [finishEating model]
  else
    { model
      | eating = Just
        { timer = 0 -- chomp immediately!
        , state = Model.Chomping
          { chunkSize = Basics.max 8 (String.length model.meal // 8) } } }
    ! [scrollPlate]

refocusPlate : Cmd Msg
refocusPlate = Task.attempt (always Msg.Idle) <| Dom.focus "plate"

scrollPlate : Cmd Msg
scrollPlate = Task.attempt (always Msg.Idle) <| Dom.Scroll.toTop "plate"
