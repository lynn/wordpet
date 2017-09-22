module Petting exposing (dizzyTick, pet)

import Time exposing (Time)

import Animation
import SFX

import Model exposing (Model, DizzyState(..))
import Msg exposing (..)


-- cutoff for when we become dizzy
enduranceLimit : Float
enduranceLimit = 3

-- initial time to stay dizzy, on a log scale
baseDizziness : Float
baseDizziness = 2


-- reduce dizziness every frame
dizzyTick : Time -> Model -> Model
dizzyTick diff model =
  { model | dizziness =
    case model.dizziness of
      Calm -> Calm
      Enduring {decay} ->
        if decay <= 1
          then Calm
          else Enduring { decay = decayTick diff decay }
      Overwhelmed {decay} ->
        if decay <= 1
          then Enduring { decay = decayTick diff enduranceLimit }
          else Overwhelmed { decay = decayTick (2 * diff) decay } }

decayTick : Time -> Float -> Float
decayTick diff decay = decay / 2^(diff / Time.second)


-- pet pet pet
pet : Model -> (Model, Cmd Msg)
pet = stimulate >> \ model -> model
  ! [chirp model, Animation.trigger "pet"]

-- increase dizziness when poked
stimulate : Model -> Model
stimulate model =
  { model | dizziness =
    case model.dizziness of
      Calm -> Enduring { decay = 2 }
      Enduring {decay} ->
        if decay >= enduranceLimit
          then Overwhelmed { decay = baseDizziness }
          else Enduring { decay = decay + 1 }
      Overwhelmed {decay} -> Overwhelmed { decay = decay + 1 } }

chirp : Model -> Cmd Msg
chirp model = SFX.play <|
  case model.dizziness of
    Overwhelmed _ -> SFX.Screech
    _ -> SFX.Chirp


isOverwhelmed : Model -> Bool
isOverwhelmed model =
  case model.dizziness of
    Overwhelmed _ -> True
    _ - False
