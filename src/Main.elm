import Dom
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Html exposing (..)
import Task

import AnimationFrame
import Time exposing (Time)

import Dict
import Markov
import Random.Pcg as Random

import Compromise
import Debug
import Maybe.Extra as Maybe


type alias Model =
  { babbles : Markov.Model Char
  , speech  : Markov.Model String
  , hatched : Maybe String -- name when hatched
  , babbleTimer : Int
  , meal : String
  , eatingTimer : Maybe Time
  , voice : String }

type Msg
  = Idle
  | TrackInput String
  | Feed
  | Babble String
  | Speak String
  | ChompTick Time
  | ResetBabbleTimer Int
  -- NLP ports
  | ReceivedSentences (List String)
  | ReceivedNormalize String

main : Program Never Model Msg
main = program
  { init = initialModel ! []
  , view = view
  , update = update
  , subscriptions = subscriptions }

initialModel : Model
initialModel =
  { babbles = Dict.empty
  , speech  = Dict.empty
  , hatched = Nothing
  , babbleTimer = 10
  , meal = ""
  , eatingTimer = Nothing
  , voice = "" }

view : Model -> Html Msg
view model = div []
  [ inputArea model
  , speechBox model ]

inputArea : Model -> Html Msg
inputArea model = div [] <|
  let whenEating = Maybe.isJust model.eatingTimer
  in case model.hatched of
    Nothing ->
      [ input
        [ id "plate"
        , onInput TrackInput
        , onEnter Feed
        , placeholder "feed words"
        , value model.meal
        , disabled whenEating
        , autofocus True ]
        [] ]
    Just name ->
      [ span [] [text name]
      , textarea
        [ id "plate"
        , onInput TrackInput
        , placeholder "feed paragraphs"
        , value model.meal
        , disabled whenEating ]
        []
      , button
        [onClick Feed, disabled <| whenEating || String.isEmpty model.meal]
        [text "Feed!"] ]

speechBox : Model -> Html Msg
speechBox model = p [] [text model.voice]

-- Take a bite out of the meal, and reset the eatingTimer if we're not done eating.
-- If we are done eating, chirp, refocus the plate, and maybe babble.
chomp : Model -> (Model, Cmd Msg)
chomp model =
  let
    remaining = String.dropLeft 1 model.meal
    done = String.isEmpty remaining
  in
    { model
      | meal = remaining
      , eatingTimer = if done
        then Nothing
        else Just <| 100 * Time.millisecond
      , voice = if done then "" else "♫" }
    ! if done
      then [refocusPlate, maybeBabble model]
      else []

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
  Idle -> model ! []
  TrackInput text ->
    { model | meal = text } ! []
  Feed ->
    if String.isEmpty model.meal
      then model ! [] -- TODO give some sort of feedback?
      else
        { model
          | eatingTimer = Just 0
          , babbles = Markov.addSample 1 (String.toList model.meal) model.babbles
          , babbleTimer = model.babbleTimer - 1 }
        ! []
  ChompTick diff ->
    case model.eatingTimer of
      Nothing -> model ! []
      Just timer ->
        if timer <= 0
          then chomp model
          else { model | eatingTimer = Just (timer - diff) } ! []
  Babble bab ->
    maybeHatch bab { model | voice = bab } ! []
  Speak speech ->
    { model | voice = speech } ! []
  ResetBabbleTimer t ->
    { model | babbleTimer = t } ! []
  ReceivedSentences sentences ->
    Debug.log (toString sentences) model ! [] -- TODO
  ReceivedNormalize normalizedText ->
    Debug.log (toString normalizedText) model ! [] -- TODO

subscriptions : Model -> Sub Msg
subscriptions model =
  let
    when cond sub = if cond then sub else Sub.none
  in Sub.batch
    -- Listen to chomp ticks so long as we're eating words.
    [ when (Maybe.isJust model.eatingTimer) (AnimationFrame.diffs ChompTick)
    -- Always listen to Compromise ports.
    , Compromise.receiveSentences ReceivedSentences
    , Compromise.receiveNormalize ReceivedNormalize ]

babble : Model -> Cmd Msg
babble model = Cmd.batch
  [ sample 1 (Babble << String.fromList) model.babbles
  , Random.generate ResetBabbleTimer <| Random.int 10 25 ]

-- the first time we babble, hatch and set our name to our first word
maybeHatch : String -> Model -> Model
maybeHatch bab model =
  case model.hatched of
    Just _ -> model
    Nothing -> { model | hatched = Just bab }

speak : Model -> Cmd Msg
speak = sample 2 (Speak << String.join "") << .speech

sample : Int -> (List comparable -> Msg) -> Markov.Model comparable -> Cmd Msg
sample n k = Random.generate k << Markov.walk n

refocusPlate : Cmd Msg
refocusPlate = Task.attempt (always Idle) <| Dom.focus "plate"

maybeBabble : Model -> Cmd Msg
maybeBabble model = if model.babbleTimer == 0
  then babble model
  else Cmd.none
