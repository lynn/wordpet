module Model exposing (Model, initial)

import Dict
import Markov
import Time exposing (Time)

type alias Model =
  { babbles : Markov.Model Char
  , speech : Markov.Model String
  , hatched : Maybe String -- name when hatched
  , babbleTimer : Int
  , meal : String
  , eating : Maybe { timer : Time, chunkSize : Int }
  , voice : String }

initial : Model
initial =
  { babbles = Dict.empty
  , speech  = Dict.empty
  , hatched = Nothing
  , babbleTimer = 10
  , meal = ""
  , eating = Nothing
  , voice = "" }
