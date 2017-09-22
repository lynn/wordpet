module Model exposing (..)

import Critter exposing (Critter)
import Dict
import Markov
import Time exposing (Time)
import Maybe.Extra exposing (isJust, isNothing)

type alias Model =
  { critter : Critter
  , babbles : Markov.Model Char
  , speech  : Markov.Model String
  , babbleTimer : Int
  , hatched : Maybe String -- name when hatched
  , meal : String
  , eating : Maybe { timer : Time, state : MealState }
  , voice : String
  , dizziness : DizzyState
  }

type MealState
  = Chomping { chunkSize : Int }
  | Swallowing

type DizzyState
  = Calm
  | Enduring { decay : Float }
  | Overwhelmed { decay : Float }

initial : Model
initial =
  { critter = Critter.dummy
  , babbles = Dict.empty
  , speech  = Dict.empty
  , babbleTimer = 6
  , hatched = Nothing
  , meal = ""
  , eating = Nothing
  , voice = ""
  , dizziness = Calm }

busy : Model -> Bool
busy model =
  isJust model.eating

isHatched : Model -> Bool
isHatched model =
  isJust model.hatched

isEgg : Model -> Bool
isEgg model =
  isNothing model.hatched
