module Markov exposing (Model, addSample, walk, encodeModel)

import Dict exposing (Dict)
import GenericDict as GDict exposing (GenericDict)
import List.Extra as List
import Maybe.Extra as Maybe
import Random.Pcg as Random exposing (Generator)

import Json.Encode as E

-- An "Ngram String" is just a list of Strings, for example.
type alias Ngram a = List a

-- Model: given an n-gram of words, how frequently does each possible
-- next word (or end of sample; represented by Nothing) occur?
type alias Model word = Dict (Ngram word) (Tally (Maybe word))

-- Tally: store frequency distribution of words, for random sampling.
type alias Tally word =
  { wordTally : GenericDict word Int
  , total : Int }

encodeDict : (comparable -> String) -> (v -> E.Value) -> Dict comparable v -> E.Value
encodeDict showK encodeV dict =
  Dict.toList dict
  |> List.map (\(k,v) -> (showK k, encodeV v))
  |> E.object

encodeGDict : (k -> String) -> (v -> E.Value) -> GenericDict k v -> E.Value
encodeGDict showK encodeV dict =
  GDict.toList dict
  |> List.map (\(k,v) -> (showK k, encodeV v))
  |> E.object

encodeModel : (comparable -> String) -> Model comparable -> E.Value
encodeModel wordToString model =
  let
    maybeWordToString = Maybe.map wordToString >> Maybe.withDefault ""
    ngramToString = List.map wordToString >> String.join " "
    encodeWordTally = encodeGDict maybeWordToString E.int
    encodeTally {wordTally, total} = E.list [E.int total, encodeWordTally wordTally]
  in
    encodeDict ngramToString encodeTally model

-- An empty Tally value.
blankTally : (word -> word -> Order) -> Tally word
blankTally comparison =
  { wordTally = GDict.empty comparison
  , total = 0 }

withDefaultTally : (word -> word -> Order) -> Maybe (Tally word) -> Tally word
withDefaultTally = Maybe.withDefault << blankTally

-- A comparison function on Maybe values.
compareMaybes : Maybe comparable -> Maybe comparable -> Order
compareMaybes a b = compare (Maybe.toList a) (Maybe.toList b)

-- Add a tally mark for a given word!
markTally : word -> Tally word -> Tally word
markTally word tally =
  let
    -- Function to update an Int field with.
    addTally : Maybe Int -> Maybe Int
    addTally count = Just (Maybe.withDefault 0 count + 1)
  in
    { tally
      | wordTally = GDict.update word addTally tally.wordTally
      , total = tally.total + 1 }

-- Slice up a sample into (n+1)-grams for tallying.
-- The result is a list of pairs: (ngram, maybe next word).
--
--     windows 3 ["this", "is", "a", "tiny", "test"]
--       ==
--          [ ([],                       Just "this")
--          , (["this"],                 Just "is")
--          , (["this", "is"],           Just "a")
--          , (["this", "is",   "a"],    Just "tiny")
--          , (["is",   "a",    "tiny"], Just "test")
--          , (["a",    "tiny", "test"], Nothing)
--          ]

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

-- Scan over a list of words and tally up word frequencies following each
-- n-gram, for a given n, adding them to the transition table.
addSample : Int -> (comparable -> comparable) -> List comparable
  -> Model comparable -> Model comparable
addSample n normalize words model =
  let
    tally (ngram, next) =
      Dict.update ngram (Just << markTally next << withDefaultTally compareMaybes)
    -- Normalize the n-gram used as keys, leaving the tallied word untouched.
    entries = windows n normalPairs
      |> List.map
        (  Tuple.mapFirst (List.map Tuple.first)
        >> Tuple.mapSecond (Maybe.map Tuple.second) )
    normalPairs = List.map (\ word -> (normalize word, word)) words
  in
    List.foldl tally model entries


-- Random word generator, using the distribution given by a Tally.
pickWord : Tally word -> Generator (Maybe word)
pickWord tally =
  let
    frequencies : List (word, Int)
    frequencies = GDict.toList tally.wordTally

    pickWith : List (word, Int) -> Int -> Maybe word
    pickWith wordcounts index = case wordcounts of
      ((word, count) :: tail) ->
        if index < count
          then Just word
          else pickWith tail (index - count)
      [] -> Nothing
  in
    Random.int 0 (tally.total - 1) |> Random.map (pickWith frequencies)

-- A step in our Markov text synthesis process. This function takes:
--
--   * our n-gram size `n`
--   * our word normalization function
--   * our Markov model
--   * the last n-gram we generated
--       (this is the only argument that changes in successive calls to `step`!)
--
-- Using the Tally stored in the model for the supplied n-gram as a probability function,
-- it returns a Generator that decides what comes next: it randomly yields either
--
--   * Just (next word, new n-gram), signifying that generation will continue, or
--   * Nothing, signifying the end of the generated text.
--
step : Int -> (comparable -> comparable) -> Model comparable -> Ngram comparable
  -> Generator (Maybe (comparable, Ngram comparable))
step n normalize model ngram =
  let
    slideAmount = max 0 (List.length ngram - n + 1)
    slide next = (next, List.drop slideAmount ngram ++ [normalize next])
  in case Dict.get ngram model of
    Nothing -> Random.constant Nothing
    Just tally -> pickWord tally
      |> Random.map (Maybe.join >> Maybe.map slide)

-- Generate a whole sentence! This is just a wrapper around `step`.
walk : Int -> (comparable -> comparable) -> Model comparable
  -> Generator (List comparable)
walk n normalize model =
  let
    go ngram = step n normalize model ngram |> Random.andThen continue

    continue nextState = case nextState of
      Nothing -> Random.constant []
      Just (word, ngram) -> go ngram |> Random.map ((::) word)
  in
    go []
