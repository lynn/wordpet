module Critter exposing (..)
import Random.Pcg as Random exposing (Generator)
import Maybe.Extra as Maybe
import Time exposing (Time)

-- e.g. { palette = "palette5", parts = ["wings2", "body0", "eyes1"], dizzy = "dizzy0" }
-- (parts sorted from back to front)
type alias Critter =
  { palette : String
  , parts : List String
  , dizzy : String
  , chompDuration : Time }

chompDuration : Time
chompDuration = 280 * Time.millisecond

dummy : Critter
dummy = { palette = "", parts = [], dizzy = "", chompDuration = chompDuration }

-- Generate `Just` a random item from the list with probability p,
-- or `Nothing` with probability (1 − p).
pick : Float -> List a -> Generator (Maybe a)
pick p options =
  Random.float 0 1
  |> Random.andThen (\x ->
    if x <= p
      then Random.map Just (Random.choices (List.map Random.constant options))
      else Random.constant Nothing)

sequence : List (Generator a) -> Generator (List a)
sequence x =
  case x of
    [] -> Random.constant []
    (g :: gs) -> Random.map2 (::) g (sequence gs)

partsGenerator : Generator (List String)
partsGenerator =
    [ pick 1.0 ["shadow0"]
    , pick 0.7 ["tail0", "tail1"]
    , pick 0.7 ["legs0", "legs1"]
    , pick 0.7 ["wings0", "wings1", "wings2", "wings3"]
    , pick 1.0 ["body0", "body1", "body2", "body3"]
    , pick 1.0 ["eyes0", "eyes1", "eyes2", "eyes3", "eyes4"]
    ]
    |> sequence
    |> Random.map Maybe.values

generator : Generator Critter
generator =
  Random.map3
    (\i j p ->
      { palette = "palette" ++ toString i
      , parts = p
      , dizzy = "dizzy" ++ toString j
      , chompDuration = chompDuration })
    (Random.int 0 7)
    (Random.int 0 1)
    partsGenerator

-- Replace the first part in the list of parts that contains `old` by `new`.
-- For example, to make a critter eat, try `change "eyes" "eat0" critter.parts`.
change : String -> String -> List String -> List String
change old new parts =
  case parts of
    [] -> []
    (part :: rest) ->
      if part |> String.contains old
        then new :: rest
        else part :: change old new rest

add : a -> List a -> List a
add x xs = xs ++ [x]

onParts : (List String -> List String) -> Critter -> Critter
onParts f c = { c | parts = f c.parts }

dizzy : Critter -> Critter
dizzy c = onParts (change "eyes" c.dizzy >> add "heart0") c

drool : Critter -> Critter
drool = onParts (change "eyes" "drool0" >> add "surprise0")

eating : Time -> Critter -> Critter
eating timer c =
  let sprite = if timer < c.chompDuration / 2 then "eat0" else "eat1"
  in onParts (change "eyes" sprite) c
