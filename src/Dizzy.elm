module Dizzy exposing (tick, stimulate)

import Time exposing (Time)

import Model exposing (Model, DizzyState(..))


-- cutoff for when we become dizzy
enduranceLimit : Float
enduranceLimit = 3

-- initial time to stay dizzy, on a log scale
baseDizziness : Float
baseDizziness = 2


-- reduce dizziness every frame
tick : Time -> Model -> Model
tick diff model =
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
