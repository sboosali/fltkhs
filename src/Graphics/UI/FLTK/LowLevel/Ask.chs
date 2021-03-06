{-# LANGUAGE CPP, ExistentialQuantification, TypeSynonymInstances, FlexibleInstances, MultiParamTypeClasses, FlexibleContexts, ScopedTypeVariables #-}
module Graphics.UI.FLTK.LowLevel.Ask
  (
    flBeep,
    BeepType(..),
    flMessage,
    flAlert,
    flInput,
    flPassword
  )
where
#include "Fl_ExportMacros.h"
#include "Fl_Types.h"
#include "Fl_AskC.h"
import C2HS hiding (cFromEnum, cToBool,cToEnum)

import qualified Data.Text as T
import Graphics.UI.FLTK.LowLevel.Utils

#c
enum BeepType {
  BeepDefault = FL_BEEP_DEFAULT,
  BeepMessage = FL_BEEP_MESSAGE,
  BeepError = FL_BEEP_ERROR,
  BeepQuestion = FL_BEEP_QUESTION,
  BeepPassword = FL_BEEP_PASSWORD,
  BeepNotification = FL_BEEP_NOTIFICATION
};
#endc

{#enum BeepType {} deriving (Eq, Show, Ord) #}

{# fun flc_beep as flBeep' {} -> `()' #}
{# fun flc_beep_with_type as flBeepType' { id `CInt' } -> `()' #}
flBeep :: Maybe BeepType -> IO ()
flBeep Nothing = flBeep'
flBeep (Just bt) = flBeepType' (fromIntegral (fromEnum bt))

{# fun flc_input as flInput' { `CString' } -> `CString' #}
flInput :: T.Text -> IO (Maybe T.Text)
flInput msg = do
  r <- copyTextToCString msg >>= flInput'
  cStringToMaybeText r

{# fun flc_password as flPassword' { `CString' } -> `CString' #}
flPassword :: T.Text -> IO (Maybe T.Text)
flPassword msg = do
  r <- copyTextToCString msg >>= flPassword'
  cStringToMaybeText r

{# fun flc_message as flMessage' { `CString' } -> `()' #}
flMessage :: T.Text -> IO ()
flMessage t = copyTextToCString t >>= flMessage'

{# fun flc_alert as flAlert' { `CString' } -> `()' #}
flAlert :: T.Text -> IO ()
flAlert t = copyTextToCString t >>= flAlert'
