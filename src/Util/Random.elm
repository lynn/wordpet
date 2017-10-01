module Util.Random exposing (..)
import Random.Pcg as Random exposing (Generator)
import List.Extra exposing (getAt)

-- The list given here should always be a non-empty list literal!
oneOf : List a -> Generator a
oneOf xs =
  Random.choices (List.map Random.constant xs)

-- Pick out a random element x from a list, generating (Just x, all elements but x).
-- If the list is empty, (Nothing, []) is generated.
pickOut : List a -> Generator (Maybe a, List a)
pickOut xs =
  Random.int 0 (List.length xs - 1)
  |> Random.map (\i ->
    (getAt i xs, List.take i xs ++ List.drop (i+1) xs))

-- Shuffle a list.
shuffle : List a -> Generator (List a)
shuffle xs =
  pickOut xs
  |> Random.andThen (\t ->
    case t of
      (Just x, rest) -> Random.map ((::) x) (shuffle rest)
      _ -> Random.constant [])

-- Try up to `tries` times to generate an `a` satisfying `predicate`, then give up.
trySatisfy : Int -> (a -> Bool) -> Random.Generator a -> Random.Generator a
trySatisfy tries predicate gen =
  if tries == 0
    then gen
    else gen |> Random.andThen (\result ->
      if predicate result
        then Random.constant result
        else trySatisfy (tries - 1) predicate gen)
