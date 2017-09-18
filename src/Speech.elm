module Speech exposing (train, trainSpeech, speak, maybeBabble)

import Dict
import Markov
import Random.Pcg as Random

import Compromise
import Regex exposing (Regex, regex)

import Model exposing (Model)
import Msg exposing (Msg)


sample : (List comparable -> msg) -> Int -> (comparable -> comparable)
  -> Markov.Model comparable -> Cmd msg
sample k n normalize = Random.generate k << Markov.walk n normalize

-- train the babble model
trainBabbles : Model -> Model
trainBabbles model =
  { model | babbles =
    Markov.addSample 1 identity (String.toList model.meal) model.babbles }

-- train the speech model
-- TODO: need to normalize
trainSpeech : List String -> Model -> Model
trainSpeech sentences model =
  let
    addSentence sentence =
      Markov.addSample 2 normalizeWord (String.words sentence)
  in
    { model
      | speech = List.foldl addSentence model.speech sentences }

-- train the appropriate model
train : Model -> (Model, Cmd Msg)
train = babbleTick >> \ model ->
  case model.hatched of
    Nothing ->
      -- not yet hatched! train the babble model
      trainBabbles model ! []
    Just _ ->
      -- hatched! train the speech model.
      -- first we need to split the meal into sentences.
      model ! [Compromise.sentences model.meal]

-- sample the appropriate model, usually speaking but sometimes babbling
speak : Model -> (Model, Cmd Msg)
speak = babbleTick >> \ model ->
  ( model
  , if model.babbleTimer == 0 || Dict.isEmpty model.speech
    then babble model
    else sample (Msg.Speak << String.join " ") 2 normalizeWord model.speech )

-- for actions that can babble! decrease the babble timer
babbleTick : Model -> Model
babbleTick model = { model | babbleTimer = model.babbleTimer - 1 }

-- randomly babble sometimes
maybeBabble : Model -> Cmd Msg
maybeBabble model = if model.babbleTimer == 0
  then babble model
  else Cmd.none

-- sample the babble model and reset the babble timer,
-- so we don't babble too often
babble : Model -> Cmd Msg
babble model = Cmd.batch
  [ sample (Msg.Babble << String.fromList) 1 identity model.babbles
  , Random.generate Msg.ResetBabbleTimer <| Random.int 10 25 ]

-- normalize words for speech training and sampling
normalizeWord : String -> String
normalizeWord =
  let
    -- be careful not to strip sentence terminators or we'll end up with
    -- periods and exclamation points and question marks in the middle of the
    -- sentence! if we want to handle those, we'll need to do a bit more work,
    -- but probably it's fine not to
    stripPunctuation =
      Regex.replace Regex.All (regex "[,~\"']") (always "")
  in
    stripPunctuation >> String.toLower
