module Model exposing (Model, initial)

import Dict
import Markov
import Time exposing (Time)

type alias Model =
  { babbles : Markov.Model Char
  , speech  : Markov.Model String
  , babbleTimer : Int
  , hatched : Maybe String -- name when hatched
  , meal : String
  , eating : Maybe { timer : Time, chunkSize : Int }
  , voice : String }

initial : Model
initial =
  { babbles = Dict.empty
  , speech  = Dict.empty
  , babbleTimer = 10
  , hatched = Nothing
  , meal = ""
  , eating = Nothing
  , voice = "" }
