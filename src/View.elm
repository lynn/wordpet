module View exposing (..)

import Color
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Style exposing (..)
import Style.Border as Border
import Style.Color as Color
import Style.Font as Font
import String exposing (contains)

import Json.Decode as Json
import Random.Pcg as Random exposing (Generator)

import Critter exposing (Critter)
import OldView
import Model exposing (..)
import Msg exposing (..)


{-| The type we use for identifiers for our styles.
-}
type Styles
  = None
  | Main
  | H1
  | CritterLayer


{-| First, we create a stylesheet.
Styles only deal with properties that are not related to layout, position, or size.
Generally all properties only have one allowed unit, which is usually px.
If you want to use something like em
-}
stylesheet : StyleSheet Styles v
stylesheet =
  Style.styleSheet
    [ style None [] -- It's handy to have a blank style
    , style Main
      [ Color.text Color.white
      , Color.background (Color.rgb 125 119 168)
      , Font.typeface [ Font.font "Lato", Font.font "sans-serif" ]
      , Font.size 16
      , Font.lineHeight 1.3 -- line height, given as a ratio of current font size.
      ]
    , style H1
      [ Font.size 36
      ]
    , style CritterLayer []
    ]


-- A 300x240 element with one layer of the critter set as the background image.
-- Usage:  critterLayer "palette3" "body1"
critterLayer : String -> String -> Element Styles v Msg
critterLayer palette part =
  let
    wiggleAnim = "up4px 0.8s alternate infinite steps(2, end)"
    imageUrl = "url('assets/critter/" ++ palette ++ "/" ++ part ++ ".png')"
    -- Non-moving parts.
    isStatic = List.any (\k -> part |> contains k) ["legs", "shadow", "egg", "crack"]
  in el CritterLayer
    [ width (px 300)
    , height (px 240)
    , inlineStyle
      [ ("background-image", imageUrl)
      , ("background-size", "100%")
      , ("image-rendering", "pixelated")
      , ("animation", if isStatic then "none" else wiggleAnim)
      , ("opacity", if part |> contains "shadow" then "0.75" else "1.0")
      ]
    ]
    empty


-- A 300x240 element containing critterLayers stacked on top of each other.
critterElement : Critter -> Element Styles v Msg
critterElement c =
  el None [ width (px 300), height (px 240) ] empty
    |> within (List.map (critterLayer c.palette) c.parts)


renderCritter : Model -> Element Styles v Msg
renderCritter model =
  let
    emote =
      case model.hatched of
        Nothing -> Critter.egg (toFloat (10 - model.babbleTimer) / 10.0)
        Just _ ->
          case model.eating of
            Nothing -> identity
            Just e -> Critter.eating e.timer
  in
    critterElement (emote model.critter)

onEnter : Msg -> Attribute v Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)


inputArea : Model -> Element Styles v Msg
inputArea model = column None [] <|
  let (eating, options) =
    case model.eating of
      Just _ -> (True, [Input.disabled])
      Nothing -> (False, [Input.focusOnLoad])

  in case model.hatched of
    Nothing ->
      [ Input.text None
        [ id "plate"
        , onEnter Feed ]
        { onChange = TrackInput
        , value = model.meal
        , label = Input.placeholder { text = "feed words", label = Input.hiddenLabel "plate" }
        , options = options }
        -- , placeholder "feed words"
        -- , value model.meal
        -- , disabled whenEating
        -- , autofocus True ]
      ]
    Just name ->
      [ text name
      , Input.multiline None
        [ id "plate" ]
        { onChange = TrackInput
        , value = model.meal
        , label = Input.placeholder { text = "feed paragraphs", label = Input.hiddenLabel "plate" }
        , options = options }
      , button None
        (if eating || String.isEmpty model.meal then [] else [onClick Feed])
        (text "Feed!") ]


speechBox : Model -> Element Styles v Msg
speechBox model = text model.voice


-- TODO: the critter itself should just be clickable, probably?
petButton : Model -> Element Styles v Msg
petButton model = button None [ onClick Pet ] (text "Pet!")


-- TODO: this should actually take the model and use it.
view : Model -> Html Msg
view model =
  Element.layout stylesheet <|
    full Main [center] <| column None [center] <|
      [ h1 H1 [paddingTop 20] (text "wordpet")
      -- , html (OldView.inputArea model)
      , inputArea model
      -- , html (OldView.speechBox model)
      , speechBox model
      -- , html (OldView.petButton model)
      , petButton model
      , renderCritter model
      ]
