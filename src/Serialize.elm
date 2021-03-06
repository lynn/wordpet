module Serialize exposing (..)
-- Functions for converting the model to and from JSON.

import Critter exposing (Critter)
import Dict
import Markov
import Model exposing (Model)

import Json.Decode as D
import Json.Encode as E

-- { critter : Critter
--  , babbles : Markov.Model Char
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

maybeEncode : (a -> E.Value) -> Maybe a -> E.Value
maybeEncode encoder m =
  case m of
    Just a -> encoder a
    Nothing -> E.null

encodeModel : Model -> E.Value
encodeModel {critter,babbles,speech,babbleTimer,hatched} =
  E.object
    [ ("critter", encodeCritter critter)
    , ("babbles", Markov.encodeModel babbles)
    , ("speech", Markov.encodeModel speech)
    , ("babbleTimer", E.int babbleTimer)
    , ("hatched", maybeEncode E.string hatched)
    ]

modelToJson : Model -> String
modelToJson = encodeModel >> E.encode 0

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

decodeModel : D.Decoder Model
decodeModel =
  let initial = Model.initial in
  D.map5 (\a b c d e -> { initial | critter = a, babbles = b, speech = c, babbleTimer = d, hatched = e })
    (D.field "critter" decodeCritter)
    (D.field "babbles" Markov.decodeModel)
    (D.field "speech" Markov.decodeModel)
    (D.field "babbleTimer" (D.int))
    (D.field "hatched" (D.nullable D.string))

decodeCritter : D.Decoder Critter
decodeCritter =
  D.map6 (\a b c d e f -> {palette = a, parts = b, dizzy = c, chompDuration = d, stats = e, punctuation = f})
    (D.field "palette" D.string)
    (D.field "parts" (D.list D.string))
    (D.field "dizzy" D.string)
    (D.field "chompDuration" D.float)
    (D.field "stats" (D.map Dict.toList (D.dict D.int)))
    (D.field "punctuation" D.string)

