module Serialize exposing (..)
-- Functions for converting the model to and from JSON.

import Critter exposing (Critter)
import Markov
import Model exposing (Model)
import Json.Encode as E
import Json.Helpers as E

-- { critter : Critter
--   , babbles : Markov.Model Char
--   , speech  : Markov.Model String
--   , babbleTimer : Int
--   , hatched : Maybe String -- name when hatched
--   , meal : String
--   , eating : Maybe { timer : Time, state : MealState }
--   , voice : String
--   , dizziness : DizzyState
--   }

-- type alias Critter =
--   { palette : String
--   , parts : List String  -- (sorted from back to front)
--   , dizzy : String
--   , chompDuration : Time
--   , stats : List (String, Int)  -- scores from 1 to 5
--   , punctuation : String -- punctuation when babbling
--   }

encodeModel : Model -> E.Value
encodeModel {critter,babbles,speech,hatched} =
  E.object
    [ ("critter", encodeCritter critter)
    , ("babbles", Markov.encodeModel String.fromChar babbles)
    , ("speech", Markov.encodeModel identity speech)
    , ("hatched", E.maybeEncode E.string hatched)
    ]

encodeCritter : Critter -> E.Value
encodeCritter {palette, parts, dizzy, chompDuration, stats, punctuation} =
  E.object
    [ ("palette", E.string palette)
    , ("parts", E.list (List.map E.string parts))
    , ("dizzy", E.string dizzy)
    , ("chompDuration", E.float chompDuration)
    , ("stats", List.map (\(s, i) -> (s, E.int i)) stats |> E.object)
    , ("punctuation", E.string punctuation)
    ]
