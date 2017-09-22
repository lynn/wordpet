module Speech exposing (train, trainSpeech, speak, maybeBabble, handleSpeech)

import Dict
import Markov
import Random.Pcg as Random

import Compromise
import Regex exposing (Regex, regex)

import Model exposing (Model)
import Msg exposing (Msg)


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
  , if model.babbleTimer == 0
    then babble model
    else Random.generate identity
      (Markov.walk 2 normalizeWord model.speech |>
        Random.andThen (\ voice ->
          -- if the speech model is empty, babble instead
          if List.isEmpty voice
            then Random.map (Msg.Vocalize Msg.Babble) <|
              babbleText model
            else Random.constant <|
              Msg.Vocalize Msg.Speech (String.join " " voice))) )

-- for actions that can babble! decrease the babble timer
babbleTick : Model -> Model
babbleTick model = { model | babbleTimer = model.babbleTimer - 1 }

-- randomly babble sometimes
maybeBabble : Model -> Cmd Msg
maybeBabble model = if model.babbleTimer == 0
  then babble model
  else Cmd.none

babbleText : Model -> Random.Generator String
babbleText model = Random.map2 (++)
  (Random.map String.fromList << Markov.walk 1 identity <| model.babbles)
  (Random.map (Maybe.withDefault "☺") <| Random.sample ["!", "?", "~", "…"])

-- sample the babble model
babble : Model -> Cmd Msg
babble = Random.generate (Msg.Vocalize Msg.Babble) << babbleText

-- handle any additional work after speaking:
-- when we babble, reset the babble timer, so we don't babble too often
handleSpeech : Msg.VoiceType -> Cmd Msg
handleSpeech voiceType =
  case voiceType of
    Msg.Speech -> Cmd.none
    Msg.Babble -> Random.generate Msg.ResetBabbleTimer <| Random.int 10 25

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
