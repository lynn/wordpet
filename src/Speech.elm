module Speech exposing (train, trainSpeech, speak, maybeBabble, handleSpeech)

import Markov
import Random.Pcg as Random
import Util.Random as Random exposing (trySatisfy)

import Compromise
import Regex exposing (Regex, regex)

import Model exposing (Model, isEgg, isHatched)
import Msg exposing (Msg)

import Bad
import Petting exposing (isOverwhelmed)


-- Train the babble model on `model.meal`.
trainBabbles : Model -> Model
trainBabbles model =
  { model | babbles =
    Markov.addSample 1 identity (String.toList model.meal) model.babbles }

-- Train the speech model on the given list of sentences.
-- TODO: need to normalize
trainSpeech : List String -> Model -> Model
trainSpeech sentences model =
  let
    addSentence sentence =
      Markov.addSample 2 normalizeWord (String.words sentence)
  in
    { model
      | speech = List.foldl addSentence model.speech sentences }

-- Train the appropriate model.
train : Model -> (Model, Cmd Msg)
train = babbleTick >> \ model ->
  if isEgg model then
    -- Not yet hatched! Train the babble model.
    trainBabbles model ! []
  else
    -- Hatched! Train the speech model.
    -- First we need to split the meal into sentences.
    model ! [Compromise.sentences model.meal]

-- Sample the appropriate model, usually speaking but sometimes babbling.
speak : Model -> (Model, Cmd Msg)
speak = babbleTick >> \ model ->
  ( model
  , if model.babbleTimer == 0 || isOverwhelmed model
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

-- Decrease the babble timer.
babbleTick : Model -> Model
babbleTick model = { model | babbleTimer = model.babbleTimer - 1 }

-- Babble if the babble timer is zero. (Babbling resets this timer.)
maybeBabble : Model -> Cmd Msg
maybeBabble model = if model.babbleTimer == 0
  then babble model
  else Cmd.none

babbleText : Model -> Random.Generator String
babbleText model =
  let
    bab = Random.map String.fromList (Markov.walk 1 identity model.babbles)
    randomRepeat i j s = Random.int i j |> Random.map (\count -> String.repeat count s)
    punctuation =
      case model.dizziness of
        Model.Overwhelmed _ ->
          case model.critter.punctuation of
            "…" -> Random.oneOf ["…!", "…!!"]
            p   -> randomRepeat 2 3 p
        _ -> Random.constant model.critter.punctuation
  in
    Random.map2 (++) bab punctuation

babbleTextSatisfying : (String -> Bool) -> Model -> Random.Generator String
babbleTextSatisfying predicate model =
  trySatisfy 100 predicate (babbleText model)

-- Is this babble an adequate name? We check for ≥4 characters and no naughty cuss words.
-- TODO: avoid names that equal a word the user taught the egg. (this is why `model` is passed here)
isGoodName : Model -> String -> Bool
isGoodName model babble =
  let name = String.dropRight 1 babble
  in String.length name >= 4 && not (List.member name Bad.words)

-- Sample the babble model.
-- As an egg, make a babble that works as a name; otherwise anything goes.
babble : Model -> Cmd Msg
babble model =
  model
  |> (if isHatched model
      then babbleText
      else babbleTextSatisfying (isGoodName model))
  |> Random.generate (Msg.Vocalize Msg.Babble)

-- Handle any additional work after speaking:
-- When we babble, reset the babble timer, so we don't babble too often.
handleSpeech : Msg.VoiceType -> Cmd Msg
handleSpeech voiceType =
  case voiceType of
    Msg.Speech -> Cmd.none
    Msg.Babble -> Random.generate Msg.ResetBabbleTimer (Random.int 2 9)

-- Normalize words for speech training and sampling.
normalizeWord : String -> String
normalizeWord =
  let
    -- Be careful not to strip sentence terminators or we'll end up with
    -- periods and exclamation points and question marks in the middle of the
    -- sentence! If we want to handle those, we'll need to do a bit more work,
    -- but probably it's fine not to.
    stripPunctuation =
      Regex.replace Regex.All (regex "[,~\"']") (always "")
  in
    stripPunctuation >> String.toLower
