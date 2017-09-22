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
import Critter exposing (Critter)
import Model exposing (Model)
import Msg exposing (..)


{-| The type we use for identifiers for our styles.
-}
type Styles
  = None
  | Main
  | H1
  | CritterStyle
  | SpeechBubble
  | SpeechBubbleHolder
  | SpeechBubbleTail

type Variations
  = Invisible

{-| First, we create a stylesheet.
Styles only deal with properties that are not related to layout, position, or size.
Generally all properties only have one allowed unit, which is usually px.
If you want to use something like em
-}
stylesheet : StyleSheet Styles Variations
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
    , style CritterStyle
      [ cursor "pointer"
      ]
    , style SpeechBubble
      [ Font.size 18
      , Border.rounded 10.0
      , Color.background (Color.rgba 255 255 255 0.7)
      , Color.text Color.darkCharcoal
      , Font.center
      ]
    , style SpeechBubbleHolder
      [ variation Invisible [ opacity 0 ]
      , prop "transition" "opacity 0.2s ease"
      ]
    , style SpeechBubbleTail
      [ pseudo "after"
        [ prop "content" "\"\""
        , prop "position" "absolute"
        , prop "bottom" "-12px"
        , prop "left" "-12px"
        , prop "border-width" "12px 12px 12px 0"
        , prop "border-style" "solid"
        , prop "border-color" "transparent rgba(255,255,255,0.7)"
        ]
      ]
    ]


-- A 300x240 element with one layer of the critter set as the background image.
-- Usage:  critterLayer "palette3" "body1"
critterLayer : String -> String -> Element Styles Variations Msg
critterLayer palette part =
  let
    wiggleAnim = "up4px 0.8s alternate infinite steps(2, end)"
    imageUrl = "url('assets/critter/" ++ palette ++ "/" ++ part ++ ".png')"
    -- Non-moving parts.
    isStatic = List.any (\k -> part |> contains k) ["legs", "shadow", "egg", "crack", "surprise", "heart"]
  in el None
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
critterElement : Critter -> Element Styles Variations Msg
critterElement c =
  el CritterStyle [ width (px 300), height (px 240), onClick Pet ] empty
    |> within (List.map (critterLayer c.palette) c.parts)


speechBubbleHolder : Model -> Element Styles Variations Msg
speechBubbleHolder model =
  el SpeechBubbleHolder
    [ height (px 240)
    , width (px 330)
    , vary Invisible (model.voice == "")
    ]
    empty


speechBubbleTail : Element Styles Variations Msg
speechBubbleTail =
  el SpeechBubbleTail [ verticalCenter ] empty


speechBubble : Model -> Element Styles Variations Msg
speechBubble model =
  el SpeechBubble
    [ minWidth (px 80)
    , maxWidth (px 330)
    , minHeight (px 44)
    , padding 10
    , verticalCenter
    ]
    (paragraph None [] [text model.voice])


renderCritter : Model -> Element Styles Variations Msg
renderCritter model =
  let
    emote : Critter -> Critter
    emote =
      case model.hatched of
        Nothing -> Critter.egg (toFloat (10 - model.babbleTimer) / 10.0)
        Just _ ->
          case model.eating of
            Just e -> Critter.eating e.timer
            Nothing ->
              case model.meal of
                "" -> identity
                _ -> Critter.drool
  in
    critterElement (emote model.critter)
      |> onRight [ speechBubbleHolder model |> within [ speechBubbleTail, speechBubble model ] ]


onEnter : Msg -> Attribute v Msg
onEnter msg =
  on "keydown" (keyCode |> Json.andThen (\code ->
    if code == 13 then Json.succeed msg else Json.fail "not enter"))


inputArea : Model -> Element Styles Variations Msg
inputArea model = column None [] <|
  let
    busy = Model.busy model
    options = if busy then [Input.disabled] else [Input.focusOnLoad]
    canFeed = not busy && model.meal /= ""
  in case model.hatched of
    Nothing ->
      [ Input.text None
        [ id "plate"
        , onEnter Feed ]
        { onChange = TrackInput
        , value = model.meal
        , label = Input.placeholder { text = "feed words", label = Input.hiddenLabel "word to feed" }
        , options = options }
      ]
    Just name ->
      [ text name
      , Input.multiline None
        [ id "plate" ]
        { onChange = TrackInput
        , value = model.meal
        , label = Input.placeholder { text = "feed paragraphs", label = Input.hiddenLabel "paragraphs to feed" }
        , options = options }
      , button None
        (if canFeed then [onClick Feed] else [])
        (text "Feed!") ]


view : Model -> Html Msg
view model =
  Element.layout stylesheet <|
    full Main [center] <| column None [center, spacing 20] <|
      [ h1 H1 [paddingTop 20] (text "wordpet")
      , renderCritter model
      , inputArea model
      ]
