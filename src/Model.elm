module Model exposing (..)

import Critter exposing (Critter)
import Dict
import Markov
import Time exposing (Time)
import Maybe.Extra exposing (isJust)

type alias Model =
  { critter : Critter
  , babbles : Markov.Model Char
  , speech  : Markov.Model String
  , babbleTimer : Int
  , hatched : Maybe String -- name when hatched
  , meal : String
  , eating : Maybe { timer : Time, state : MealState }
  , voice : String
  }

type MealState
  = Chomping { chunkSize : Int }
  | Swallowing

initial : Model
initial =
  { critter = Critter.dummy
  , babbles = Dict.empty
  , speech  = Dict.empty
  , babbleTimer = 6
  , hatched = Nothing
  , meal = ""
  , eating = Nothing
  , voice = "" }

busy : Model -> Bool
busy model =
    isJust model.eating

