module FoodProcessor exposing (process)

import Char
import Maybe.Extra as Maybe

import Model exposing (Model)

process : Model -> Model
process ({meal, hatched} as model) =
  if Maybe.isJust hatched then
    model -- anything is fine once we've hatched
  else
    { model | meal = simplify meal } -- need simple food for eggs!!

-- make edible for eggs: remove spaces, punctuation; make letters lowercase
simplify : String -> String
simplify = String.filter (\ c -> Char.isDigit c || isLetter c) >> String.toLower

-- heuristic for telling if something is a letter--this *usually* works
isLetter : Char -> Bool
isLetter c = Char.toUpper c /= Char.toLower c
