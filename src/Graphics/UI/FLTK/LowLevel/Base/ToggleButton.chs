{-# LANGUAGE CPP, EmptyDataDecls, TypeSynonymInstances, FlexibleInstances, MultiParamTypeClasses, FlexibleContexts #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Graphics.UI.FLTK.LowLevel.Base.ToggleButton
    (
     toggleButtonNew
     -- * Hierarchy
     --
     -- $hierarchy

     -- * Functions
     --
     -- $functions
    )
where
#include "Fl_ExportMacros.h"
#include "Fl_Types.h"
#include "Fl_Toggle_ButtonC.h"
#include "Fl_WidgetC.h"
import C2HS hiding (cFromEnum, cFromBool, cToBool,cToEnum)

import Graphics.UI.FLTK.LowLevel.Fl_Types
import Graphics.UI.FLTK.LowLevel.Utils
import Graphics.UI.FLTK.LowLevel.Hierarchy
import Graphics.UI.FLTK.LowLevel.Base.Widget
import Graphics.UI.FLTK.LowLevel.Dispatch
import qualified Data.Text as T

{# fun Fl_Toggle_Button_New as widgetNew' { `Int',`Int',`Int',`Int',id `FunPtr DestroyCallbacksPrim'  } -> `Ptr ()' id #}
{# fun Fl_Toggle_Button_New_WithLabel as widgetNewWithLabel' { `Int',`Int',`Int',`Int',`CString',id `FunPtr DestroyCallbacksPrim'} -> `Ptr ()' id #}
toggleButtonNew :: Rectangle -> Maybe T.Text -> IO (Ref ToggleButton)
toggleButtonNew rectangle l' =
    let (x_pos, y_pos, width, height) = fromRectangle rectangle
    in do
    destroyFptr <- toDestroyCallbacksPrim (defaultDestroyCallbacks :: (Ref ToggleButton -> [Maybe (FunPtr (IO ()))] -> IO ()))
    ref <- case l' of
            Nothing -> widgetNew' x_pos y_pos width height destroyFptr >>= toRef
            Just l -> copyTextToCString l >>= \l' -> widgetNewWithLabel' x_pos y_pos width height l' destroyFptr >>= toRef
    setFlag (safeCast ref :: Ref WidgetBase ) WidgetFlagCopiedLabel
    setFlag (safeCast ref :: Ref WidgetBase ) WidgetFlagCopiedTooltip
    return ref


{# fun Fl_Toggle_Button_Destroy as widgetDestroy' { id `Ptr ()' } -> `()' supressWarningAboutRes #}
instance (impl ~ (IO ())) => Op (Destroy ()) ToggleButtonBase orig impl where
  runOp _ _ button = swapRef button $
                    \buttonPtr ->
                     widgetDestroy' buttonPtr >>
                     return nullPtr

-- $hierarchy
-- @
-- "Graphics.UI.FLTK.LowLevel.Base.Widget"
--  |
--  v
-- "Graphics.UI.FLTK.LowLevel.Base.Button"
--  |
--  v
-- "Graphics.UI.FLTK.LowLevel.Base.ToggleButton"
-- @

-- $functions
-- @
-- destroy :: 'Ref' 'ToggleButtonBase' -> 'IO' ()
-- @
