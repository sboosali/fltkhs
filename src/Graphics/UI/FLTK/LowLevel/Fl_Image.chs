{-# LANGUAGE CPP, ExistentialQuantification, TypeSynonymInstances, FlexibleInstances, MultiParamTypeClasses, FlexibleContexts, ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Graphics.UI.FLTK.LowLevel.Fl_Image
       (
       ImageFuncs(..),
       defaultImageFuncs,
       imageNew,
       ColorAverageCallback,
       ImageDrawCallback,
       ImageCopyCallback,
       toImageDrawCallbackPrim,
       toColorAverageCallbackPrim,
       toImageCopyCallbackPrim
       )
where
#include "Fl_ExportMacros.h"
#include "Fl_Types.h"
#include "Fl_ImageC.h"
import C2HS hiding (cFromEnum, cFromBool, cToBool,cToEnum)
import Foreign.C.Types
import Graphics.UI.FLTK.LowLevel.Fl_Enumerations
import Graphics.UI.FLTK.LowLevel.Fl_Types
import Graphics.UI.FLTK.LowLevel.Utils
import Graphics.UI.FLTK.LowLevel.Fl_Widget
import Graphics.UI.FLTK.LowLevel.Hierarchy
import Graphics.UI.FLTK.LowLevel.Dispatch

type ColorAverageCallback        = Ref Image -> Color -> Float -> IO ()
type ImageDrawCallback           = Ref Image -> Position -> Size -> Maybe X -> Maybe Y -> IO ()
type ImageCopyCallback           = Ref Image -> Size -> IO (Ref Image)
toImageDrawCallbackPrim :: ImageDrawCallback -> IO (FunPtr ImageDrawCallbackPrim)
toImageDrawCallbackPrim f =
    mkImageDrawCallbackPrimPtr
    (\ptr x_pos' y_pos' width' height' x_offset' y_offset' ->
       let _x_offset = fmap X $ integralToMaybe x_offset'
           _y_offset = fmap Y $ integralToMaybe y_offset'
           position' = Position (X $ fromIntegral x_pos')
                                (Y $ fromIntegral y_pos')
           size' = Size (Width $ fromIntegral width')
                        (Height $ fromIntegral height')
       in
        toRef ptr >>= \refPtr -> f refPtr position' size' _x_offset _y_offset
    )

toColorAverageCallbackPrim :: ColorAverageCallback -> IO (FunPtr ColorAverageCallbackPrim)
toColorAverageCallbackPrim f =
    mkColorAverageCallbackPtr
    (\ptr cint cfloat ->
         wrapNonNull ptr "Null pointer. toColorAverageCallbackPrim" >>= \pp ->
         f (wrapInRef pp) (Color (fromIntegral cint)) (realToFrac cfloat)
    )

toImageCopyCallbackPrim :: ImageCopyCallback -> IO (FunPtr ImageCopyCallbackPrim)
toImageCopyCallbackPrim f =
    mkImageCopyCallbackPrimPtr
    (\ptr width' height' -> do
         pp <- wrapNonNull ptr "Null pointer. toImageCopyCallbackPrim"
         refPtr <- f (wrapInRef pp) (Size (Width $ fromIntegral width')
                                           (Height $ fromIntegral height'))
         unsafeRefToPtr refPtr
    )


data ImageFuncs a b =
  ImageFuncs
  {
    imageDrawOverride  :: Maybe (ImageDrawCallback),
    imageColorAverageOverride :: Maybe (ColorAverageCallback),
    imageCopyOverride :: Maybe (ImageCopyCallback),
    imageDesaturateOverride :: Maybe (Ref Image -> IO ()),
    imageUncacheOverride :: Maybe (Ref Image -> IO ())
  }
imageFunctionStruct :: (ImageFuncs a b) -> IO (Ptr ())
imageFunctionStruct funcs = do
  p <- mallocBytes {# sizeof fl_Image_Virtual_Funcs #}
  toImageDrawCallbackPrim `orNullFunPtr` (imageDrawOverride funcs) >>=
                            {# set fl_Image_Virtual_Funcs->draw #} p
  toColorAverageCallbackPrim `orNullFunPtr` (imageColorAverageOverride funcs) >>=
                            {# set fl_Image_Virtual_Funcs->color_average #} p
  toImageCopyCallbackPrim `orNullFunPtr` (imageCopyOverride funcs) >>=
                            {# set fl_Image_Virtual_Funcs->copy #} p
  toCallbackPrim `orNullFunPtr` (imageDesaturateOverride funcs) >>=
                            {# set fl_Image_Virtual_Funcs->desaturate #} p
  toCallbackPrim `orNullFunPtr` (imageUncacheOverride funcs) >>=
                            {# set fl_Image_Virtual_Funcs->uncache #} p
  return p

defaultImageFuncs :: ImageFuncs a b
defaultImageFuncs = ImageFuncs Nothing Nothing Nothing Nothing Nothing

{# fun unsafe Fl_Image_New as flImageNew' { `Int',`Int',`Int' } -> `Ptr ()' id #}
{# fun unsafe Fl_OverriddenImage_New as flOverriddenImageNew' { `Int',`Int',`Int', id `Ptr ()'} -> `Ptr ()' id #}
imageNew :: Size -> Depth -> Maybe (ImageFuncs a b) -> IO (Ref Image)
imageNew (Size (Width width') (Height height')) (Depth depth') funcs =
  case funcs of
    Just fs -> do
            fptr <- imageFunctionStruct fs
            obj <- flOverriddenImageNew' width' height' depth' (castPtr fptr)
            toRef obj
    Nothing -> flImageNew' width' height' depth' >>= toRef

{# fun unsafe Fl_Image_Destroy as flImageDestroy' { id `Ptr ()' } -> `()' id #}
instance Op (Destroy ()) Image ( IO ()) where
  runOp _ image = withRef image $ \imagePtr -> flImageDestroy' imagePtr
{# fun unsafe Fl_Image_w as w' { id `Ptr ()' } -> `Int' #}
instance Op (GetW ()) Image (  IO (Int)) where
  runOp _ image = withRef image $ \imagePtr -> w' imagePtr
{# fun unsafe Fl_Image_h as h' { id `Ptr ()' } -> `Int' #}
instance Op (GetH ()) Image (  IO (Int)) where
  runOp _ image = withRef image $ \imagePtr -> h' imagePtr
{# fun unsafe Fl_Image_d as d' { id `Ptr ()' } -> `Int' #}
instance Op (GetD ()) Image (  IO (Int)) where
  runOp _ image = withRef image $ \imagePtr -> d' imagePtr
{# fun unsafe Fl_Image_ld as ld' { id `Ptr ()' } -> `Int' #}
instance Op (GetLd ()) Image (  IO (Int)) where
  runOp _ image = withRef image $ \imagePtr -> ld' imagePtr
{# fun unsafe Fl_Image_count as count' { id `Ptr ()' } -> `Int' #}
instance Op (GetCount ()) Image (  IO (Int)) where
  runOp _ image = withRef image $ \imagePtr -> count' imagePtr

{# fun unsafe Fl_Image_copy_with_w_h as copyWithWH' { id `Ptr ()',`Int',`Int' } -> `Ptr ()' id #}
{# fun unsafe Fl_Image_copy as copy' { id `Ptr ()' } -> `Ptr ()' id #}
instance Op (Copy ()) Image (  Maybe Size -> IO (Ref Image)) where
  runOp _ image size' = case size' of
    Just (Size (Width w) (Height h)) -> withRef image $ \imagePtr -> copyWithWH' imagePtr w h >>= toRef
    Nothing -> withRef image $ \imagePtr -> copy' imagePtr >>= toRef

{# fun unsafe Fl_Image_color_average as colorAverage' { id `Ptr ()',cFromColor `Color',`Float' } -> `()' #}
instance Op (ColorAverage ()) Image ( Color -> Float ->  IO ()) where
  runOp _ image c i = withRef image $ \imagePtr -> colorAverage' imagePtr c i

{# fun unsafe Fl_Image_inactive as inactive' { id `Ptr ()' } -> `()' #}
instance Op (Inactive ()) Image (  IO ()) where
  runOp _ image = withRef image $ \imagePtr -> inactive' imagePtr

{# fun unsafe Fl_Image_desaturate as desaturate' { id `Ptr ()' } -> `()' #}
instance Op (Desaturate ()) Image (  IO ()) where
  runOp _ image = withRef image $ \imagePtr -> desaturate' imagePtr

{# fun unsafe Fl_Image_draw_with_cx_cy as drawWithCxCy' { id `Ptr ()',`Int',`Int',`Int',`Int',`Int',`Int' } -> `()' #}
{# fun unsafe Fl_Image_draw_with_cx as drawWithCx' { id `Ptr ()',`Int',`Int',`Int',`Int',`Int' } -> `()' #}
{# fun unsafe Fl_Image_draw_with_cy as drawWithCy' { id `Ptr ()',`Int',`Int',`Int',`Int',`Int' } -> `()' #}
{# fun unsafe Fl_Image_draw_with as drawWith' { id `Ptr ()',`Int',`Int',`Int',`Int' } -> `()' #}

instance Op (DrawResize ()) Image ( Position -> Size -> Maybe X -> Maybe Y -> IO ()) where
  runOp _ image (Position (X x) (Y y)) (Size (Width w) (Height h)) xOffset yOffset =
    case (xOffset, yOffset) of
      (Just (X xOff), Just (Y yOff)) ->
        withRef image $ \imagePtr -> drawWithCxCy' imagePtr x y w h (fromIntegral xOff) (fromIntegral yOff)
      (Just (X xOff), Nothing) ->
        withRef image $ \imagePtr -> drawWithCx' imagePtr x y w h (fromIntegral xOff)
      (Nothing, Just (Y yOff)) ->
        withRef image $ \imagePtr -> drawWithCy' imagePtr x y w h (fromIntegral yOff)
      (Nothing, Nothing) ->
        withRef image $ \imagePtr -> drawWith' imagePtr x y w h

{# fun unsafe Fl_Image_draw as draw' { id `Ptr ()',`Int',`Int' } -> `()' #}
instance Op (Draw ()) Image ( Position ->  IO ()) where
  runOp _ image (Position (X x_pos') (Y y_pos')) = withRef image $ \imagePtr -> draw' imagePtr x_pos' y_pos'
{# fun unsafe Fl_Image_uncache as uncache' { id `Ptr ()' } -> `()' #}
instance Op (Uncache ()) Image (  IO ()) where
  runOp _ image = withRef image $ \imagePtr -> uncache' imagePtr
