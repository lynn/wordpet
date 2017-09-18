module ChompAnimation exposing (duration, tick, setup)

import Dom
import Dom.Scroll
import Task

import Maybe.Extra as Maybe

import Time exposing (Time)

import Model exposing (Model)
import Msg exposing (Msg)

import SFX
import Speech

duration : Time
duration = 280 * Time.millisecond

-- called each frame of animation in the browser; chomp every 150 milliseconds
tick : Time -> Model -> (Model, Cmd Msg)
tick diff model =
  case model.eating of
    Nothing -> model ! []
    Just ({timer, chunkSize} as eating) ->
      if timer <= 0
        then chomp chunkSize model
        else { model | eating = Just { eating | timer = timer - diff } } ! []

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
        else Just { timer = duration, chunkSize = chunkSize }
      , voice = if done then "" else "♫" }
    ! if done
      then [refocusPlate, Speech.maybeBabble model]
      else [SFX.play SFX.Chomp]

-- set up the chomp animation!
setup : Model -> (Model, Cmd Msg)
setup model =
  { model
    | eating = Just
      { timer = 0 -- chomp immediately!
      , chunkSize =
        if Maybe.isJust model.hatched
          then Basics.max 8 (String.length model.meal // 8)
          else 1 } }
  ! [scrollPlate]

refocusPlate : Cmd Msg
refocusPlate = Task.attempt (always Msg.Idle) <| Dom.focus "plate"

scrollPlate : Cmd Msg
scrollPlate = Task.attempt (always Msg.Idle) <| Dom.Scroll.toTop "plate"
