module Critter exposing (..)
import Random.Pcg as Random exposing (Generator)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)

-- A *visual* representation of the critter you're taking care of.
-- e.g. { palette = "palette5", parts = ["wings2", "body0", "eyes1"], dizzy = "dizzy0", ... }
-- There are some functions Critter -> Critter below to make the critter emote!
type alias Critter =
  { palette : String
  , parts : List String  -- (sorted from back to front)
  , dizzy : String
  , chompDuration : Time
  , stats : List (String, Int)  -- scores from 1 to 5
  }

chompDuration : Time
chompDuration = 280 * Time.millisecond

-- This dummy critter is used in the initial model. When the program starts,
-- a command is immediately issued to generate a better one randomly.
dummy : Critter
dummy = { palette = "", parts = [], dizzy = "", chompDuration = chompDuration, stats = [] }

-- Generate `Just` a random item from the list with probability p,
-- or `Nothing` with probability (1 − p).
pick : Float -> List a -> Generator (Maybe a)
pick p options =
  Random.float 0 1
  |> Random.andThen (\x ->
    if x <= p
      then Random.map Just (Random.choices (List.map Random.constant options))
      else Random.constant Nothing)

-- A generator for critter parts.
partsGenerator : Generator (List String)
partsGenerator =
  let
    sequence = List.foldr (Random.map2 (::)) (Random.constant [])
  in
    [ pick 1.0 ["shadow0"]
    , pick 0.7 ["tail0", "tail1"]
    , pick 0.7 ["legs0", "legs1"]
    , pick 0.7 ["wings0", "wings1", "wings2", "wings3"]
    , pick 1.0 ["body0", "body1", "body2", "body3"]
    , pick 1.0 ["eyes0", "eyes1", "eyes2", "eyes3", "eyes4"]
    ]
    |> sequence
    |> Random.map Maybe.values

statNames : List String
statNames =
  [ "Adventure"
  , "Aerodynamics"
  , "Affection"
  , "Bookishness"
  , "Buoyancy"
  , "Caprice"
  , "Charm"
  , "Clumsiness"
  , "Curiosity"
  , "Fashion"
  , "Friendship"
  , "Grace"
  , "Guts"
  , "Honesty"
  , "Humor"
  , "Jitteriness"
  , "Laziness"
  , "Magic"
  , "Moé"
  , "Mystery"
  , "Optimism"
  , "Patience"
  , "Pep"
  , "Persistence"
  , "Puns"
  , "Rhyme"
  , "Shyness"
  , "Sleepiness"
  , "Speed"
  , "Spunk"
  , "Squishiness"
  , "Strength"
  , "Stress"
  , "Tenderness"
  , "Viscosity"
  , "Whimsy"
  , "Wisdom"
  ]

-- Pick out a random element x from a list, generating (Just x, all elements but x).
-- If the list is empty, (Nothing, []) is generated.
pickOut : List a -> Generator (Maybe a, List a)
pickOut xs =
  Random.int 0 (List.length xs - 1)
  |> Random.map (\i ->
    (List.getAt i xs, List.take i xs ++ List.drop (i+1) xs))

-- Shuffle a list.
shuffle : List a -> Generator (List a)
shuffle xs =
  pickOut xs
  |> Random.andThen (\t ->
    case t of
      (Just x, rest) -> Random.map ((::) x) (shuffle rest)
      _ -> Random.constant [])

-- Generate `count` random stats.
statsGenerator : Int -> Generator (List (String, Int))
statsGenerator count =
  shuffle statNames
  |> Random.andThen (\names ->
    Random.list count (Random.int 2 5)
    |> Random.map (\scores ->
      List.map2 (,) names scores))

-- A generator for random critters!
generator : Generator Critter
generator =
  Random.map4
    (\i j p s ->
      { palette = "palette" ++ toString i
      , parts = p
      , dizzy = "dizzy" ++ toString j
      , chompDuration = chompDuration
      , stats = s })
    (Random.int 0 7)
    (Random.int 0 1)
    partsGenerator
    (statsGenerator 4)

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

-- Add an item to the end of a list.
add : a -> List a -> List a
add x xs = xs ++ [x]

dizzy : Critter -> Critter
dizzy c = { c | parts = c.parts |> change "eyes" c.dizzy |> add "heart0" }

drool : Critter -> Critter
drool c = { c | parts = c.parts |> change "eyes" "drool0" |> add "surprise0" }

eating : Time -> Critter -> Critter
eating timer c =
  let sprite = if timer < c.chompDuration / 2 then "eat0" else "eat1"
  in { c | parts = c.parts |> change "eyes" sprite }

-- Return a critter's "shape": the numeric part of its body layer.
-- e.g. If the critter has a "body2" part, the result is "2".
shape : Critter -> String
shape c =
  case List.filter (String.contains "body") c.parts of
    [body] -> String.dropLeft 4 body
    _ -> "0"

-- `crackedness` ranges from 0 (no cracks) to 1 (fully cracked).
egg : Float -> Critter -> Critter
egg crackedness c =
  let
    crackLevels = 4
    crack = floor (crackedness * crackLevels) |> clamp 0 (crackLevels - 1)
    eggParts = ["eggshadow0", "eggbot" ++ shape c, "eggtop" ++ shape c, "crack" ++ toString crack]
  in
    { c | parts = eggParts }
