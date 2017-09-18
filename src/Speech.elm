module Speech exposing (train, trainSpeech, speak, maybeBabble)

import Dict
import Markov
import Random.Pcg as Random

import Compromise

import Model exposing (Model)
import Msg exposing (Msg)


sample : Int -> (List comparable -> msg) -> Markov.Model comparable -> Cmd msg
sample n k = Random.generate k << Markov.walk n

-- train the babble model
trainBabbles : Model -> Model
trainBabbles model =
  { model |
    babbles = Markov.addSample 1 (String.toList model.meal) model.babbles }

-- train the speech model
-- TODO: need to normalize
trainSpeech : List String -> Model -> Model
trainSpeech sentences model =
  let
    addSentence sentence = Markov.addSample 2 (String.split " " sentence)
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
  if model.babbleTimer == 0 || Dict.isEmpty model.speech
    then model ! [babble model]
    else model ! [sample 2 (Msg.Speak << String.join " ") model.speech]

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
  [ sample 1 (Msg.Babble << String.fromList) model.babbles
  , Random.generate Msg.ResetBabbleTimer <| Random.int 10 25 ]
