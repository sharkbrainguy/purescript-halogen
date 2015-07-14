-- | This module defines an adapter between the `purescript-halogen` and `purescript-css` libraries.

module Halogen.HTML.CSS
  ( Styles(..)
  , runStyles

  , style
  , stylesheet
  ) where

import Prelude

import Data.Array (mapMaybe)
import Data.Either (Either(), either)
import Data.List (fromList, toList)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (joinWith)
import Data.Tuple (Tuple(..))

import qualified Data.StrMap as SM

import Css.Property (Key(), Value())
import Css.Render (render, renderedSheet, collect)
import Css.Stylesheet (Css(), Rule(..), runS)

import qualified Halogen.HTML as H
import qualified Halogen.HTML.Attributes as A

-- | A newtype for CSS styles
newtype Styles = Styles (SM.StrMap String)

-- | Unpack CSS styles
runStyles :: Styles -> SM.StrMap String
runStyles (Styles m) = m

instance stylesIsAttribute :: A.IsAttribute Styles where
  toAttrString _ (Styles m) = joinWith "; " $ (\(Tuple key value) -> key <> ": " <> value) <$> fromList (SM.toList m)

-- | Render a set of rules as an inline style.
-- |
-- | For example:
-- |
-- | ```purescript
-- | H.div [ Css.style do color red
-- |                      display block ]
-- |       [ ... ]
-- | ```
style :: forall i. Css -> A.Attr i
style = A.attr (A.attributeName "style") <<< Styles <<< rules <<< runS
  where
  rules :: Array Rule -> SM.StrMap String
  rules rs = SM.fromList (toList properties)
    where
    properties :: Array (Tuple String String)
    properties = mapMaybe property rs >>= collect >>> rights

  property :: Rule -> Maybe (Tuple (Key Unit) Value)
  property (Property k v) = Just (Tuple k v)
  property _              = Nothing

  rights :: forall a b. Array (Either a b) -> Array b
  rights = mapMaybe (either (const Nothing) Just)

-- | Render a set of rules as a `style` element.
stylesheet :: forall i. Css -> H.HTML i
stylesheet css = H.style [ A.type_ "text/css" ] [ H.text content ]
  where
  content = fromMaybe "" $ renderedSheet $ render css