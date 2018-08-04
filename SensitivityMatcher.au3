﻿#NoTrayIcon
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GUIComboBox.au3>
#include <GuiEdit.au3>
#include <StaticConstants.au3>
#include <GUIToolTip.au3> ; Tooltips for the options

Global $gMode      = -1
Global $gSens      = 1.0
Global $gPartition = 127
Global $gDelay     = 10
Global $gCycle     = 20
Global $gResidual  = 0.0
Global Const $gPi  = 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116

Global Const $yawQuake          = 0.022
Global Const $yawOverwatch      = 0.0066
Global Const $yawReflex         = 0.018/$gPi
Global Const $yawFortniteConfig = 2.222
Global Const $yawFortniteSlider = 0.5555
;Global Const $yawPaladins       = 0.009157 ; This is wrong - Paladins sens scales by FOV
;Global Const $yawBattalion      = 0.017501 ; Not sure if this is right

Global $gValid = 1


If _Singleton("Sensitivity Matcher", 1) = 0 Then
    MsgBox(0, "Warning", "An occurrence of Sensitivity Matcher is already running.")
    Exit
EndIf
HotKeySet("!{[}" , "SingleCycle")
HotKeySet("!{]}", "AutoCycle")
HotKeySet("!{\}" , "Halt")
MakeGUI()





Func MakeGUI()
   $idGUI = GUICreate("Sensitivity Matcher", 295, 235)                                      ; used to be 250, 180

   GUICtrlCreateLabel( "Select preset yaw:"                ,   5,   7,  90, 15, $SS_LEFT  )
   GUICtrlCreateLabel( "Sens"                              ,   5,  50,  75, 15, $SS_CENTER)
   GUICtrlCreateLabel( "×"                                 ,  80,  33,  15, 15, $SS_CENTER)
   GUICtrlCreateLabel( "Yaw (deg)"                         ,  95,  50, 105, 15, $SS_CENTER)
   GUICtrlCreateLabel( "="                                 , 200,  33,  15, 15, $SS_CENTER)
   GUICtrlCreateLabel( "Increment"                         , 215,  50,  75, 15, $SS_CENTER)
   GUICtrlCreateGraphic(                                       5,  70, 285,  2, $SS_SUNKEN) ; horizontal line
   GUICtrlCreateLabel( "Optional Testing Parameters"       ,   5,  80, 285, 15, $SS_CENTER)
   GUICtrlCreateLabel( "One Revolution is"                 ,   5, 102,  98, 15, $SS_RIGHT )
   GUICtrlCreateLabel( "counts."                           , 200, 102,  60, 15, $SS_LEFT  )
   GUICtrlCreateLabel( "Move in Partitions of"             ,   5, 127,  98, 15, $SS_RIGHT )
   GUICtrlCreateLabel( "counts"                            , 200, 127,  60, 15, $SS_LEFT  )
   GUICtrlCreateLabel( "at a Frequency of"                 ,   5, 152,  98, 15, $SS_RIGHT )
   GUICtrlCreateLabel( "Hz"                                , 200, 152,  60, 15, $SS_LEFT  )
   GUICtrlCreateLabel( "for a Cycle of"                    ,   5, 177,  98, 15, $SS_RIGHT )
   GUICtrlCreateLabel( "rotations."                        , 200, 177,  60, 15, $SS_LEFT  )


   Local $sYawPresets = GUICtrlCreateCombo( "Quake/Source" ,  95,   5, 120, 20)
                        GUICtrlSetData(      $sYawPresets  , "Overwatch|Rainbow6/Reflex|Fortnite Config|Fortnite Slider|Custom", "Quake/Source")
   Local $sSens       = GUICtrlCreateInput( "1"            ,   5,  30,  75, 20)
   Local $sYaw        = GUICtrlCreateInput( "0.022"        ,  95,  30, 105, 20)
   Local $sIncr       = GUICtrlCreateInput( "0.022"        , 215,  30,  75, 20)             ; hardcoded to initialize to product of above two
                        GUICtrlSendMsg(      $sIncr        , $EM_SETREADONLY, 1, 0)
   Local $sCounts     = GUICtrlCreateInput(  360/0.022     , 105, 100,  90, 20)             ; once again, hardcoding initialization
                        GUICtrlSendMsg(      $sCounts      , $EM_SETREADONLY, 1, 0)
   Local $sPartition  = GUICtrlCreateInput( "800"          , 105, 125,  90, 20)
   Local $sTickRate   = GUICtrlCreateInput( "60"           , 105, 150,  90, 20)
   Local $sCycle      = GUICtrlCreateInput( "20"           , 105, 175,  90, 20)

   Local $idHelp      = GUICtrlCreateButton("Info"         , 105, 205,  90, 25)


   Local $hToolTip    =_GUIToolTip_Create(0)                                     ; default tooltip
                                                                                 ; Set the tooltip to last 30 seconds.
                       _GUIToolTip_SetDelayTime($hToolTip, $TTDT_AUTOPOP, 30000) ; if I set this to 60 seconds, it seems to go back to 5.
                       _GUIToolTip_SetDelayTime($hToolTip, $TTDT_RESHOW, 500)    ; don't show a new tooltip till 0.5 secs later
                       _GUIToolTip_SetMaxTipWidth($hToolTip, 500)

   Local $hSens       = GUICtrlGetHandle($sSens)
                       _GUIToolTip_AddTool($hToolTip, 0, "Enter your game's sensitivity here", $hSens)
   Local $hYaw        = GUICtrlGetHandle($sYaw)
                       _GUIToolTip_AddTool($hToolTip, 0, "Base rotator unit for yaw associated with game/configuration (use dropdown menu above if possible).", $hYaw)
   Local $hIncr       = GUICtrlGetHandle($sIncr)
                       _GUIToolTip_AddTool($hToolTip, 0, "The smallest angle you could possibly rotate in-game, given your sensitivity configuration.", $hIncr)
   Local $hCounts     = GUICtrlGetHandle($sCounts)
                       _GUIToolTip_AddTool($hToolTip, 0, "A full rotation with your sensitivity configuration requires this many mouse counts to complete.", $hCounts)
   Local $hPartition  = GUICtrlGetHandle($sPartition)
                       _GUIToolTip_AddTool($hToolTip, 0, "Send this many mouse counts at a time to the game when testing. For non-rawinput games, don't let this exceed half of your in-game horizontal resolution (e.g.: if you use 1920x1080, don't use numbers greater than 960).", $hPartition)
   Local $hTickRate   = GUICtrlGetHandle($sTickRate)
                       _GUIToolTip_AddTool($hToolTip, 0, "How many times per second to send mouse movements. Make sure this isn't higher than your framerate, especially for non-rawinput games.", $hTickRate)
   Local $hCycle      = GUICtrlGetHandle($sCycle)
                       _GUIToolTip_AddTool($hToolTip, 0, "How many full revolutions to perform when pressing Alt+Home.", $hCycle)




   ; Initialize Global Variables to UI Inputs. Once initialized, the global variables are individually self-updating wihtin the main loop, no need for a whole refresh function.
   $gResidual  = 0.0
   $gMode      = 1
   $gSens      = _GetNumberFromString(GuiCtrlRead($sSens)) * _GetNumberFromString(GuiCtrlRead($sYaw))
   $gPartition = _GetNumberFromString(GuiCtrlRead($sPartition))
   $gDelay     = int(1000/_GetNumberFromString(GuiCtrlRead($sTickRate)))
   $gCycle     = _GetNumberFromString(GuiCtrlRead($sCycle))


   GUISetState(@SW_SHOW)

   Local $idMsg
   While 1                                  ; Loop until the user exits.
      $idMsg = GUIGetMsg()
      Select
         Case $idMsg == $GUI_EVENT_CLOSE
            Exit

         Case $idMsg == $sSens
            $gSens     = _GetNumberFromString( GuiCtrlRead($sSens) ) * _GetNumberFromString( GuiCtrlRead($sYaw) )
            $gResidual = 0
            GUICtrlSetData(     $sCounts, String( 360/$gSens ) )
           _GUICtrlEdit_SetSel( $sCounts, 0, 0 )
            GUICtrlSetData(     $sIncr  , String(     $gSens ) )
           _GUICtrlEdit_SetSel( $sIncr  , 0, 0 )

         Case $idMsg == $sYaw
            $gResidual = 0
            GUICtrlSetData(     $sSens  , String( $gSens / _GetNumberFromString( GuiCtrlRead($sYaw) ) ) )
           _GUICtrlEdit_SetSel( $sSens  , 0, 0 )
           _GUICtrlEdit_SetSel( $sYaw   , 0, 0 )

;~         ; Uncomment these, and comment out the above two lines if you would rather have increment update instead of sens.
;~ 			GUICtrlSetData($sCounts,String(Round(360/(_GetNumberFromString(GuiCtrlRead($sSens)) * _GetNumberFromString(GuiCtrlRead($sYaw))),3)))
;~ 			GUICtrlSetData($sIncr,String(_GetNumberFromString(GuiCtrlRead($sSens)) * _GetNumberFromString(GuiCtrlRead($sYaw))))
;~ 			_GUICtrlEdit_SetSel($sIncr, 0, 0)
;~ 			_GUICtrlEdit_SetSel($sYaw, 0, 0)

            If     _GetNumberFromString(GuiCtrlRead($sYaw)) == $yawQuake          Then
                   _GUICtrlComboBox_SelectString($sYawPresets, "Quake/Source")
            ElseIf _GetNumberFromString(GuiCtrlRead($sYaw)) == $yawOverwatch      Then
                   _GUICtrlComboBox_SelectString($sYawPresets, "Overwatch")
            ElseIf _GetNumberFromString(GuiCtrlRead($sYaw)) == $yawReflex         Then
                   _GUICtrlComboBox_SelectString($sYawPresets, "Rainbow6/Reflex")
            ElseIf _GetNumberFromString(GuiCtrlRead($sYaw)) == $yawFortniteSlider Then
                   _GUICtrlComboBox_SelectString($sYawPresets, "Fortnite Slider")
            ElseIf _GetNumberFromString(GuiCtrlRead($sYaw)) == $yawFortniteConfig Then
                   _GUICtrlComboBox_SelectString($sYawPresets, "Fortnite Config")
            Else
                   _GUICtrlComboBox_SelectString($sYawPresets, "Custom")
            EndIf

         Case $idMsg == $sYawPresets
            If     GUICtrlRead($sYawPresets) == "Quake/Source"        Then
                   GUICtrlSetData($sYaw, String($yawQuake))
            ElseIf GUICtrlRead($sYawPresets) == "Overwatch"           Then
                   GUICtrlSetData($sYaw, String($yawOverwatch))
            ElseIf GUICtrlRead($sYawPresets) == "Rainbow6/Reflex"     Then
                   GUICtrlSetData($sYaw, String($yawReflex))
            ElseIf GUICtrlRead($sYawPresets) == "Fortnite Config"     Then
                   GUICtrlSetData($sYaw, String($yawFortniteConfig))
            ElseIf GUICtrlRead($sYawPresets) == "Fortnite Slider"     Then
                   GUICtrlSetData($sYaw, String($yawFortniteSlider))
            EndIf

            GUICtrlSetData(     $sSens  , String( $gSens / _GetNumberFromString( GuiCtrlRead($sYaw) ) ) )
           _GUICtrlEdit_SetSel( $sSens  , 0, 0 )
           _GUICtrlEdit_SetSel( $sYaw   , 0, 0 )

;~         ; Uncomment these, and comment out the above two lines if you would rather have increment update instead of sens.
;~ 			GUICtrlSetData($sCounts,String(Round(360/(_GetNumberFromString(GuiCtrlRead($sSens)) * _GetNumberFromString(GuiCtrlRead($sYaw))),3)))
;~ 			GUICtrlSetData($sIncr,String(_GetNumberFromString(GuiCtrlRead($sSens)) * _GetNumberFromString(GuiCtrlRead($sYaw))))
;~ 			_GUICtrlEdit_SetSel($sIncr, 0, 0)
;~ 			_GUICtrlEdit_SetSel($sYaw, 0, 0)

         Case $idMsg == $sPartition
            $gPartition = _GetNumberFromString( GuiCtrlRead($sPartition) )

         Case $idMsg == $sTickRate
            $gDelay     = int( 1000 / _GetNumberFromString( GuiCtrlRead($sTickRate) ) )

         Case $idMsg == $sCycle
            $gCycle     = _GetNumberFromString( GuiCtrlRead($sCycle)     )

         Case $idMsg == $idHelp
            If InputsValid($sSens, $sPartition, $sYaw, $sTickRate, $sCycle) Then
               $time = round($gCycle*$gDelay*(int(360/$gSens/$gPartition)+1)/1000)
               MsgBox(0, "Info",   "1) Select the Preset/game that you are coming from."          & @crlf _
                                 & "2) Input your sensitivity value from your old game."          & @crlf _
                                 & "3) In your new game, adjust its sens until the test matches." & @crlf _
                                                                                                  & @crlf _
                                 & "Press Alt+[ to perform one full revolution."             & @crlf _
                                 & "Press Alt+] to perform " & $gCycle & " full revolutions."  & @crlf _
                                 & "Press Alt+\ to halt."                                       & @crlf _
                                                                                                  & @crlf _
                                 & "Interval: " & $gDelay & " ms (rounded to nearest milisecond)" & @crlf _
                                 & "Estimated Completion Time for " & $gCycle & " cycles: " & $time & " sec")
            Else
               MsgBox(0, "Error", "Inputs must be a number")
            EndIf
      EndSelect

      $gValid = InputsValid($sSens, $sPartition, $sYaw, $sTickRate, $sCycle)

      If $gMode == -1 Then
         $gMode = 1
      EndIf

   WEnd
EndFunc

Func TestMouse($cycle)
   If $gMode > 0 Then
      $gMode = 0

      $partition  = $gPartition ; how many movements to perform in a single go.  Don't let this exceed half of your resolution.
      $delay      = $gDelay     ; delay in milliseconds between movements.  Making this lower than frametime causes dropped inputs for non-rawinput games.
      $turn       = 0.0
      $totalcount = 1

      While $cycle
         $cycle = $cycle - 1

		 $turn          = 360                                               ; one revolution in deg
		 $totalcount    = ( $turn + $gResidual ) / ( $gSens )               ; partitioned by user-defined increments
		 $totalcount    = Round( $totalcount )                              ; round to nearest integer
		 $gResidual     = ( $turn + $gResidual ) - ( $gSens * $totalcount ) ; save the residual angles

         While $totalcount > $partition
            If $gMode < 0 Then
               ExitLoop
            EndIf
            _MouseMovePlus($partition,0)
            $totalcount = $totalcount - $partition
            Sleep($delay)
         WEnd
         If $gMode < 0 Then
            ExitLoop
         EndIf
         _MouseMovePlus($totalcount,0) ; do the leftover
         Sleep($delay)
      WEnd

      If $gMode == 0 Then
         $gMode = 1
      EndIf
   EndIf
EndFunc

Func Halt()
   If $gMode > -1 Then
      $gMode = -1
      $gResidual = 0
   EndIf
EndFunc

Func InputsValid($sSens, $sPartition, $sYaw, $sTickRate, $sCycle)
   return _StringIsNumber(GuiCtrlRead($sSens)) AND _StringIsNumber(GuiCtrlRead($sPartition)) AND _StringIsNumber(GuiCtrlRead($sYaw)) AND _StringIsNumber(GuiCtrlRead($sTickrate)) AND _StringIsNumber(GuiCtrlRead($sCycle))
EndFunc

Func SingleCycle()
   if $gValid Then
	  TestMouse(1)
   Else
	  MsgBox(0, "Error", "Inputs must be a number")
   EndIf
EndFunc

Func AutoCycle()
   if $gValid Then
	  TestMouse($gCycle)
   Else
	  MsgBox(0, "Error", "Inputs must be a number")
   EndIf
EndFunc

Func _MouseMovePlus($X = "", $Y = "")
        Local $MOUSEEVENTF_MOVE = 0x1
    DllCall("user32.dll", "none", "mouse_event", _
            "long",  $MOUSEEVENTF_MOVE, _
            "long",  $X, _
            "long",  $Y, _
            "long",  0, _
        "long",  0)
EndFunc

Func _StringIsNumber($input) ; Checks if an input string is a number.
;   The default StringIsDigit() function doesn't recognize negatives or decimals.
;   "If $input == String(Number($input))" doesn't recognize ".1" since Number(".1") returns 0.1
;   So, here's a regex I pulled from http://www.regular-expressions.info/floatingpoint.html
   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3)
   if UBound($array) > 0 Then
      Return True
   EndIf
   Return False
EndFunc

Func _GetNumberFromString($input) ; uses the above regular expression to pull a proper number
;   $array = StringRegExp($input, '^[-+]?([0-9]*\.[0-9]+|[0-9]+)$', 3) ; this didn't return negatives
   $array = StringRegExp($input, '^([-+])?(\d*\.\d+|\d+)$', 3)
   if UBound($array) > 1 Then
      Return Number($array[0] & $array[1]) ; $array[0] is "" or "-", $array[1] is the number.
   EndIf
   Return "error"
EndFunc