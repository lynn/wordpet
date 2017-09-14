module Markov exposing (Model, addSample, walk)

import Dict exposing (Dict)
import List.Extra as List
import Random.Pcg as Random exposing (Generator)
import Debug


type alias Ngram a = List a

-- model: given an n-gram of words, how frequently does each possible
-- next word occur?
type alias Model word = Dict (Ngram word) (Tally word)

-- tally: what is the frequency of each next occurring word, and also how
-- frequently do we end here (no next word)
type alias Tally word =
  { wordTally : Dict word Int
  , endTally : Int
  , total : Int }


blankTally =
  { wordTally = Dict.empty
  , endTally = 0
  , total = 0 }

-- add a tally mark for a given word!
markTally : Maybe comparable -> Tally comparable -> Tally comparable
markTally item tally = case item of
  Nothing ->
    { tally
      | endTally = tally.endTally + 1
      , total = tally.total + 1 }
  Just word ->
    let
      addTally count = case count of
        Nothing -> Just 1
        Just n  -> Just (n + 1)
    in
      { tally
        | wordTally = Dict.update word addTally tally.wordTally
        , total = tally.total + 1 }

-- slice up a sample into (n+1)-grams for tallying
windows : Int -> List word -> List (Ngram word, Maybe word)
windows n words =
  let
    initial = List.inits words
      |> List.drop 1
      |> List.map2 List.splitAt (List.range 0 (n - 1))
      |> List.map format

    midsample = List.tails words
      |> List.map (format << List.splitAt n << List.take (n + 1))
      |> List.filter ((==) n << List.length << Tuple.first)

    format = Tuple.mapSecond List.head
  in
    initial ++ midsample

-- scan over a list of words and tally up word frequencies following each
-- n-gram, for a given n, adding them to the transition table
addSample : Int -> List comparable -> Model comparable -> Model comparable
addSample n words model =
  let
    tally (ngram, next) =
      Dict.update ngram (Just << markTally next << Maybe.withDefault blankTally)
  in
    List.foldl tally model (windows n words)


-- random word generator using the distribution given by a Tally
pickWord : Tally comparable -> Generator (Maybe comparable)
pickWord tally =
  let
    frequencies = (Nothing, tally.endTally)
      :: List.map (Tuple.mapFirst Just) (Dict.toList tally.wordTally)

    pickWith wordcounts index = case wordcounts of
      ((word, count) :: tail) ->
        if index < count
          then word
          else pickWith tail (index - count)
      [] -> Debug.crash "oh no. this shouldn't happen"
  in
    Random.int 0 (tally.total - 1) |> Random.map (pickWith frequencies)

-- generate the next word and get the next state from a given state
step : Int -> Model comparable -> Ngram comparable
  -> Generator (Maybe (comparable, Ngram comparable))
step n model ngram =
  let
    tally = Maybe.withDefault blankTally <| Dict.get ngram model
    slide next = (next, List.take (n - 1) ngram ++ [next])
  in
    Random.map (Maybe.map slide) <| pickWord tally

-- generate a whole sentence!! wow!!
walk : Int -> Model comparable -> Generator (List comparable)
walk n model =
  let
    go ngram = step n model ngram |> Random.andThen continue

    continue nextState = case nextState of
      Nothing -> Random.constant []
      Just (word, ngram) -> go ngram |> Random.map ((::) word)
  in
    go []
