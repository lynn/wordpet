module OldView exposing (..)

import Model exposing (Model)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onEnter)
import Msg exposing (..)
import Maybe
import Maybe.Extra as Maybe

inputArea : Model -> Html Msg
inputArea model = div [] <|
  let whenEating = Maybe.isJust model.eating
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

petButton : Model -> Html Msg
petButton model = button
  [ onClick Pet, disabled <| Maybe.isJust model.eating ]
  [ text "Pet!" ]
