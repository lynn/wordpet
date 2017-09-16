module Markov exposing (Model, addSample, walk)

import Dict exposing (Dict)
import GenericDict as GDict exposing (GenericDict)
import List.Extra as List
import Maybe.Extra as Maybe
import Random.Pcg as Random exposing (Generator)
import Debug


type alias Ngram a = List a

-- model: given an n-gram of words, how frequently does each possible
-- next word (or end of sample) occur?
type alias Model word = Dict (Ngram word) (Tally (Maybe word))

-- tally: store frequency distribution of words, for random sampling
type alias Tally word =
  { wordTally : GenericDict word Int
  , total : Int }


blankTally : (word -> word -> Order) -> Tally word
blankTally comparison =
  { wordTally = GDict.empty comparison
  , total = 0 }

withDefaultTally : (word -> word -> Order) -> Maybe (Tally word) -> Tally word
withDefaultTally = Maybe.withDefault << blankTally

compareMaybes : Maybe comparable -> Maybe comparable -> Order
compareMaybes a b = compare (Maybe.toList a) (Maybe.toList b)

-- add a tally mark for a given word!
markTally : word -> Tally word -> Tally word
markTally word tally =
  let
    addTally count = Just <| Maybe.withDefault 0 count + 1
  in
    { tally
      | wordTally = GDict.update word addTally tally.wordTally
      , total = tally.total + 1 }

-- slice up a sample into (n+1)-grams for tallying
windows : Int -> List word -> List (Ngram word, Maybe word)
windows n words =
  let
    initial = List.map (format << flip List.splitAt words) (List.range 0 (n - 1))

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
      Dict.update ngram (Just << markTally next << withDefaultTally compareMaybes)
  in
    List.foldl tally model (windows n words)


-- random word generator using the distribution given by a Tally
pickWord : Tally word -> Generator word
pickWord tally =
  let
    frequencies = GDict.toList tally.wordTally

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
    tally = case Dict.get ngram model of
      Just t -> t
      Nothing -> Debug.crash "also shouldn't happen!"
    slideAmount = max 0 (List.length ngram - n + 1)
    slide next = (next, List.drop slideAmount ngram ++ [next])
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
