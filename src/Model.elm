module Model exposing (Model, initial)

import Critter exposing (Critter)
import Dict
import Markov
import Time exposing (Time)

type alias Model =
  { critter : Critter
  , babbles : Markov.Model Char
  , speech  : Markov.Model String
  , babbleTimer : Int
  , hatched : Maybe String -- name when hatched
  , meal : String
  , eating : Maybe { timer : Time, chunkSize : Int }
  , voice : String }

initial : Model
initial =
  { critter = Critter.dummy
  , babbles = Dict.empty
  , speech  = Dict.empty
  , babbleTimer = 10
  , hatched = Nothing
  , meal = ""
  , eating = Nothing
  , voice = "" }
