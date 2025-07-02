#region enums
enum PowerToysConfigureEnsure {
    Absent
    Present
}

enum AwakeMode {
    PASSIVE = 1
    INDEFINITE
    TIMED
    EXPIRABLE
}

enum ColorPickerActivationAction {
    OpenEditor = 1
    OpenColorPicker
}

enum ColorPickerClickAction {
    PickColorThenEditor = 1
    PickColorAndClose
    Close
}

enum HostsAdditionalLinesPosition {
    Top = 1
    Bottom
}

enum HostsEncoding {
    Utf8 = 1
    Utf8Bom
}

enum PowerAccentActivationKey {
    LeftRightArrow = 1
    Space
    Both
}

enum Theme {
    System = 1
    Light
    Dark
    HighContrastOne
    HighContrastTwo
    HighContrastBlack
    HighContrastWhite
}

enum StartupPosition {
    Cursor = 1
    PrimaryMonitor
    Focus
}

enum SortByProperty {
    LastLaunched = 1
    Created
    Name
}
#endregion enums

#region DscResources
class AdvancedPaste {
    [DscProperty()] [Nullable[bool]]
    $IsAdvancedAIEnabled = $null

    [DscProperty()] [Nullable[bool]]
    $ShowCustomPreview = $null

    [DscProperty()] [Nullable[bool]]
    $CloseAfterLosingFocus = $null

    [DscProperty()] [string]
    $AdvancedPasteUIShortcut = $null

    [DscProperty()] [string]
    $PasteAsPlainTextShortcut = $null

    [DscProperty()] [string]
    $PasteAsMarkdownShortcut = $null

    [DscProperty()] [string]
    $PasteAsJsonShortcut = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.IsAdvancedAIEnabled -ne $null) {
            $Changes.Value += "set AdvancedPaste.IsAdvancedAIEnabled `"$($this.IsAdvancedAIEnabled)`""
        }

        if ($this.ShowCustomPreview -ne $null) {
            $Changes.Value += "set AdvancedPaste.ShowCustomPreview `"$($this.ShowCustomPreview)`""
        }

        if ($this.CloseAfterLosingFocus -ne $null) {
            $Changes.Value += "set AdvancedPaste.CloseAfterLosingFocus `"$($this.CloseAfterLosingFocus)`""
        }

        if ($this.AdvancedPasteUIShortcut -notlike '') {
            $Changes.Value += "set AdvancedPaste.AdvancedPasteUIShortcut `"$($this.AdvancedPasteUIShortcut)`""
        }

        if ($this.PasteAsPlainTextShortcut -notlike '') {
            $Changes.Value += "set AdvancedPaste.PasteAsPlainTextShortcut `"$($this.PasteAsPlainTextShortcut)`""
        }

        if ($this.PasteAsMarkdownShortcut -notlike '') {
            $Changes.Value += "set AdvancedPaste.PasteAsMarkdownShortcut `"$($this.PasteAsMarkdownShortcut)`""
        }

        if ($this.PasteAsJsonShortcut -notlike '') {
            $Changes.Value += "set AdvancedPaste.PasteAsJsonShortcut `"$($this.PasteAsJsonShortcut)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.AdvancedPaste `"$($this.Enabled)`""
        }


    }
}
class AlwaysOnTop {
    [DscProperty()] [string]
    $Hotkey = $null

    [DscProperty()] [string]
    $FrameEnabled = $null

    [DscProperty()] [Nullable[int]]
    $FrameThickness = $null

    [DscProperty()] [string]
    $FrameColor = $null

    [DscProperty()] [Nullable[int]]
    $FrameOpacity = $null

    [DscProperty()] [string]
    $FrameAccentColor = $null

    [DscProperty()] [string]
    $SoundEnabled = $null

    [DscProperty()] [string]
    $DoNotActivateOnGameMode = $null

    [DscProperty()] [string]
    $ExcludedApps = $null

    [DscProperty()] [string]
    $RoundCornersEnabled = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.Hotkey -notlike '') {
            $Changes.Value += "set AlwaysOnTop.Hotkey `"$($this.Hotkey)`""
        }

        if ($this.FrameEnabled -notlike '') {
            $Changes.Value += "set AlwaysOnTop.FrameEnabled `"$($this.FrameEnabled)`""
        }

        if ($this.FrameThickness -ne $null) {
            $Changes.Value += "set AlwaysOnTop.FrameThickness `"$($this.FrameThickness)`""
        }

        if ($this.FrameColor -notlike '') {
            $Changes.Value += "set AlwaysOnTop.FrameColor `"$($this.FrameColor)`""
        }

        if ($this.FrameOpacity -ne $null) {
            $Changes.Value += "set AlwaysOnTop.FrameOpacity `"$($this.FrameOpacity)`""
        }

        if ($this.FrameAccentColor -notlike '') {
            $Changes.Value += "set AlwaysOnTop.FrameAccentColor `"$($this.FrameAccentColor)`""
        }

        if ($this.SoundEnabled -notlike '') {
            $Changes.Value += "set AlwaysOnTop.SoundEnabled `"$($this.SoundEnabled)`""
        }

        if ($this.DoNotActivateOnGameMode -notlike '') {
            $Changes.Value += "set AlwaysOnTop.DoNotActivateOnGameMode `"$($this.DoNotActivateOnGameMode)`""
        }

        if ($this.ExcludedApps -notlike '') {
            $Changes.Value += "set AlwaysOnTop.ExcludedApps `"$($this.ExcludedApps)`""
        }

        if ($this.RoundCornersEnabled -notlike '') {
            $Changes.Value += "set AlwaysOnTop.RoundCornersEnabled `"$($this.RoundCornersEnabled)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.AlwaysOnTop `"$($this.Enabled)`""
        }


    }
}
class Awake {
    [DscProperty()] [Nullable[bool]]
    $KeepDisplayOn = $null

    [DscProperty()] [AwakeMode]
    $Mode 

    [DscProperty()] [Nullable[int]]
    $IntervalHours = $null

    [DscProperty()] [Nullable[int]]
    $IntervalMinutes = $null

    [DscProperty()] [string]
    $ExpirationDateTime = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.KeepDisplayOn -ne $null) {
            $Changes.Value += "set Awake.KeepDisplayOn `"$($this.KeepDisplayOn)`""
        }

        if ($this.Mode -ne 0) {
            $Changes.Value += "set Awake.Mode `"$($this.Mode)`""
        }

        if ($this.IntervalHours -ne $null) {
            $Changes.Value += "set Awake.IntervalHours `"$($this.IntervalHours)`""
        }

        if ($this.IntervalMinutes -ne $null) {
            $Changes.Value += "set Awake.IntervalMinutes `"$($this.IntervalMinutes)`""
        }

        if ($this.ExpirationDateTime -notlike '') {
            $Changes.Value += "set Awake.ExpirationDateTime `"$($this.ExpirationDateTime)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.Awake `"$($this.Enabled)`""
        }


    }
}
class ColorPicker {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $CopiedColorRepresentation = $null

    [DscProperty()] [ColorPickerActivationAction]
    $ActivationAction 

    [DscProperty()] [ColorPickerClickAction]
    $PrimaryClickAction 

    [DscProperty()] [ColorPickerClickAction]
    $MiddleClickAction 

    [DscProperty()] [ColorPickerClickAction]
    $SecondaryClickAction 

    [DscProperty()] [Nullable[bool]]
    $ShowColorName = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set ColorPicker.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.CopiedColorRepresentation -notlike '') {
            $Changes.Value += "set ColorPicker.CopiedColorRepresentation `"$($this.CopiedColorRepresentation)`""
        }

        if ($this.ActivationAction -ne 0) {
            $Changes.Value += "set ColorPicker.ActivationAction `"$($this.ActivationAction)`""
        }

        if ($this.PrimaryClickAction -ne 0) {
            $Changes.Value += "set ColorPicker.PrimaryClickAction `"$($this.PrimaryClickAction)`""
        }

        if ($this.MiddleClickAction -ne 0) {
            $Changes.Value += "set ColorPicker.MiddleClickAction `"$($this.MiddleClickAction)`""
        }

        if ($this.SecondaryClickAction -ne 0) {
            $Changes.Value += "set ColorPicker.SecondaryClickAction `"$($this.SecondaryClickAction)`""
        }

        if ($this.ShowColorName -ne $null) {
            $Changes.Value += "set ColorPicker.ShowColorName `"$($this.ShowColorName)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.ColorPicker `"$($this.Enabled)`""
        }


    }
}
class CropAndLock {
    [DscProperty()] [string]
    $ReparentHotkey = $null

    [DscProperty()] [string]
    $ThumbnailHotkey = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ReparentHotkey -notlike '') {
            $Changes.Value += "set CropAndLock.ReparentHotkey `"$($this.ReparentHotkey)`""
        }

        if ($this.ThumbnailHotkey -notlike '') {
            $Changes.Value += "set CropAndLock.ThumbnailHotkey `"$($this.ThumbnailHotkey)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.CropAndLock `"$($this.Enabled)`""
        }


    }
}
class EnvironmentVariables {
    [DscProperty()] [Nullable[bool]]
    $LaunchAdministrator = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.LaunchAdministrator -ne $null) {
            $Changes.Value += "set EnvironmentVariables.LaunchAdministrator `"$($this.LaunchAdministrator)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.EnvironmentVariables `"$($this.Enabled)`""
        }


    }
}
class FancyZones {
    [DscProperty()] [string]
    $FancyzonesShiftDrag = $null

    [DscProperty()] [string]
    $FancyzonesMouseSwitch = $null

    [DscProperty()] [string]
    $FancyzonesMouseMiddleClickSpanningMultipleZones = $null

    [DscProperty()] [string]
    $FancyzonesOverrideSnapHotkeys = $null

    [DscProperty()] [string]
    $FancyzonesMoveWindowsAcrossMonitors = $null

    [DscProperty()] [string]
    $FancyzonesMoveWindowsBasedOnPosition = $null

    [DscProperty()] [Nullable[int]]
    $FancyzonesOverlappingZonesAlgorithm = $null

    [DscProperty()] [string]
    $FancyzonesDisplayOrWorkAreaChangeMoveWindows = $null

    [DscProperty()] [string]
    $FancyzonesZoneSetChangeMoveWindows = $null

    [DscProperty()] [string]
    $FancyzonesAppLastZoneMoveWindows = $null

    [DscProperty()] [string]
    $FancyzonesOpenWindowOnActiveMonitor = $null

    [DscProperty()] [string]
    $FancyzonesRestoreSize = $null

    [DscProperty()] [string]
    $FancyzonesQuickLayoutSwitch = $null

    [DscProperty()] [string]
    $FancyzonesFlashZonesOnQuickSwitch = $null

    [DscProperty()] [string]
    $UseCursorposEditorStartupscreen = $null

    [DscProperty()] [string]
    $FancyzonesShowOnAllMonitors = $null

    [DscProperty()] [string]
    $FancyzonesSpanZonesAcrossMonitors = $null

    [DscProperty()] [string]
    $FancyzonesMakeDraggedWindowTransparent = $null

    [DscProperty()] [string]
    $FancyzonesAllowChildWindowSnap = $null

    [DscProperty()] [string]
    $FancyzonesDisableRoundCornersOnSnap = $null

    [DscProperty()] [string]
    $FancyzonesZoneHighlightColor = $null

    [DscProperty()] [Nullable[int]]
    $FancyzonesHighlightOpacity = $null

    [DscProperty()] [string]
    $FancyzonesEditorHotkey = $null

    [DscProperty()] [string]
    $FancyzonesWindowSwitching = $null

    [DscProperty()] [string]
    $FancyzonesNextTabHotkey = $null

    [DscProperty()] [string]
    $FancyzonesPrevTabHotkey = $null

    [DscProperty()] [string]
    $FancyzonesExcludedApps = $null

    [DscProperty()] [string]
    $FancyzonesBorderColor = $null

    [DscProperty()] [string]
    $FancyzonesInActiveColor = $null

    [DscProperty()] [string]
    $FancyzonesNumberColor = $null

    [DscProperty()] [string]
    $FancyzonesSystemTheme = $null

    [DscProperty()] [string]
    $FancyzonesShowZoneNumber = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.FancyzonesShiftDrag -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesShiftDrag `"$($this.FancyzonesShiftDrag)`""
        }

        if ($this.FancyzonesMouseSwitch -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesMouseSwitch `"$($this.FancyzonesMouseSwitch)`""
        }

        if ($this.FancyzonesMouseMiddleClickSpanningMultipleZones -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesMouseMiddleClickSpanningMultipleZones `"$($this.FancyzonesMouseMiddleClickSpanningMultipleZones)`""
        }

        if ($this.FancyzonesOverrideSnapHotkeys -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesOverrideSnapHotkeys `"$($this.FancyzonesOverrideSnapHotkeys)`""
        }

        if ($this.FancyzonesMoveWindowsAcrossMonitors -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesMoveWindowsAcrossMonitors `"$($this.FancyzonesMoveWindowsAcrossMonitors)`""
        }

        if ($this.FancyzonesMoveWindowsBasedOnPosition -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesMoveWindowsBasedOnPosition `"$($this.FancyzonesMoveWindowsBasedOnPosition)`""
        }

        if ($this.FancyzonesOverlappingZonesAlgorithm -ne $null) {
            $Changes.Value += "set FancyZones.FancyzonesOverlappingZonesAlgorithm `"$($this.FancyzonesOverlappingZonesAlgorithm)`""
        }

        if ($this.FancyzonesDisplayOrWorkAreaChangeMoveWindows -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesDisplayOrWorkAreaChangeMoveWindows `"$($this.FancyzonesDisplayOrWorkAreaChangeMoveWindows)`""
        }

        if ($this.FancyzonesZoneSetChangeMoveWindows -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesZoneSetChangeMoveWindows `"$($this.FancyzonesZoneSetChangeMoveWindows)`""
        }

        if ($this.FancyzonesAppLastZoneMoveWindows -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesAppLastZoneMoveWindows `"$($this.FancyzonesAppLastZoneMoveWindows)`""
        }

        if ($this.FancyzonesOpenWindowOnActiveMonitor -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesOpenWindowOnActiveMonitor `"$($this.FancyzonesOpenWindowOnActiveMonitor)`""
        }

        if ($this.FancyzonesRestoreSize -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesRestoreSize `"$($this.FancyzonesRestoreSize)`""
        }

        if ($this.FancyzonesQuickLayoutSwitch -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesQuickLayoutSwitch `"$($this.FancyzonesQuickLayoutSwitch)`""
        }

        if ($this.FancyzonesFlashZonesOnQuickSwitch -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesFlashZonesOnQuickSwitch `"$($this.FancyzonesFlashZonesOnQuickSwitch)`""
        }

        if ($this.UseCursorposEditorStartupscreen -notlike '') {
            $Changes.Value += "set FancyZones.UseCursorposEditorStartupscreen `"$($this.UseCursorposEditorStartupscreen)`""
        }

        if ($this.FancyzonesShowOnAllMonitors -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesShowOnAllMonitors `"$($this.FancyzonesShowOnAllMonitors)`""
        }

        if ($this.FancyzonesSpanZonesAcrossMonitors -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesSpanZonesAcrossMonitors `"$($this.FancyzonesSpanZonesAcrossMonitors)`""
        }

        if ($this.FancyzonesMakeDraggedWindowTransparent -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesMakeDraggedWindowTransparent `"$($this.FancyzonesMakeDraggedWindowTransparent)`""
        }

        if ($this.FancyzonesAllowChildWindowSnap -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesAllowChildWindowSnap `"$($this.FancyzonesAllowChildWindowSnap)`""
        }

        if ($this.FancyzonesDisableRoundCornersOnSnap -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesDisableRoundCornersOnSnap `"$($this.FancyzonesDisableRoundCornersOnSnap)`""
        }

        if ($this.FancyzonesZoneHighlightColor -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesZoneHighlightColor `"$($this.FancyzonesZoneHighlightColor)`""
        }

        if ($this.FancyzonesHighlightOpacity -ne $null) {
            $Changes.Value += "set FancyZones.FancyzonesHighlightOpacity `"$($this.FancyzonesHighlightOpacity)`""
        }

        if ($this.FancyzonesEditorHotkey -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesEditorHotkey `"$($this.FancyzonesEditorHotkey)`""
        }

        if ($this.FancyzonesWindowSwitching -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesWindowSwitching `"$($this.FancyzonesWindowSwitching)`""
        }

        if ($this.FancyzonesNextTabHotkey -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesNextTabHotkey `"$($this.FancyzonesNextTabHotkey)`""
        }

        if ($this.FancyzonesPrevTabHotkey -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesPrevTabHotkey `"$($this.FancyzonesPrevTabHotkey)`""
        }

        if ($this.FancyzonesExcludedApps -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesExcludedApps `"$($this.FancyzonesExcludedApps)`""
        }

        if ($this.FancyzonesBorderColor -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesBorderColor `"$($this.FancyzonesBorderColor)`""
        }

        if ($this.FancyzonesInActiveColor -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesInActiveColor `"$($this.FancyzonesInActiveColor)`""
        }

        if ($this.FancyzonesNumberColor -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesNumberColor `"$($this.FancyzonesNumberColor)`""
        }

        if ($this.FancyzonesSystemTheme -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesSystemTheme `"$($this.FancyzonesSystemTheme)`""
        }

        if ($this.FancyzonesShowZoneNumber -notlike '') {
            $Changes.Value += "set FancyZones.FancyzonesShowZoneNumber `"$($this.FancyzonesShowZoneNumber)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.FancyZones `"$($this.Enabled)`""
        }


    }
}
class FileLocksmith {
    [DscProperty()] [string]
    $ExtendedContextMenuOnly = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ExtendedContextMenuOnly -notlike '') {
            $Changes.Value += "set FileLocksmith.ExtendedContextMenuOnly `"$($this.ExtendedContextMenuOnly)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.FileLocksmith `"$($this.Enabled)`""
        }


    }
}
class FindMyMouse {
    [DscProperty()] [Nullable[int]]
    $ActivationMethod = $null

    [DscProperty()] [string]
    $IncludeWinKey = $null

    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $DoNotActivateOnGameMode = $null

    [DscProperty()] [string]
    $BackgroundColor = $null

    [DscProperty()] [string]
    $SpotlightColor = $null

    [DscProperty()] [Nullable[int]]
    $OverlayOpacity = $null

    [DscProperty()] [Nullable[int]]
    $SpotlightRadius = $null

    [DscProperty()] [Nullable[int]]
    $AnimationDurationMs = $null

    [DscProperty()] [Nullable[int]]
    $SpotlightInitialZoom = $null

    [DscProperty()] [string]
    $ExcludedApps = $null

    [DscProperty()] [Nullable[int]]
    $ShakingMinimumDistance = $null

    [DscProperty()] [Nullable[int]]
    $ShakingIntervalMs = $null

    [DscProperty()] [Nullable[int]]
    $ShakingFactor = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationMethod -ne $null) {
            $Changes.Value += "set FindMyMouse.ActivationMethod `"$($this.ActivationMethod)`""
        }

        if ($this.IncludeWinKey -notlike '') {
            $Changes.Value += "set FindMyMouse.IncludeWinKey `"$($this.IncludeWinKey)`""
        }

        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set FindMyMouse.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.DoNotActivateOnGameMode -notlike '') {
            $Changes.Value += "set FindMyMouse.DoNotActivateOnGameMode `"$($this.DoNotActivateOnGameMode)`""
        }

        if ($this.BackgroundColor -notlike '') {
            $Changes.Value += "set FindMyMouse.BackgroundColor `"$($this.BackgroundColor)`""
        }

        if ($this.SpotlightColor -notlike '') {
            $Changes.Value += "set FindMyMouse.SpotlightColor `"$($this.SpotlightColor)`""
        }

        if ($this.OverlayOpacity -ne $null) {
            $Changes.Value += "set FindMyMouse.OverlayOpacity `"$($this.OverlayOpacity)`""
        }

        if ($this.SpotlightRadius -ne $null) {
            $Changes.Value += "set FindMyMouse.SpotlightRadius `"$($this.SpotlightRadius)`""
        }

        if ($this.AnimationDurationMs -ne $null) {
            $Changes.Value += "set FindMyMouse.AnimationDurationMs `"$($this.AnimationDurationMs)`""
        }

        if ($this.SpotlightInitialZoom -ne $null) {
            $Changes.Value += "set FindMyMouse.SpotlightInitialZoom `"$($this.SpotlightInitialZoom)`""
        }

        if ($this.ExcludedApps -notlike '') {
            $Changes.Value += "set FindMyMouse.ExcludedApps `"$($this.ExcludedApps)`""
        }

        if ($this.ShakingMinimumDistance -ne $null) {
            $Changes.Value += "set FindMyMouse.ShakingMinimumDistance `"$($this.ShakingMinimumDistance)`""
        }

        if ($this.ShakingIntervalMs -ne $null) {
            $Changes.Value += "set FindMyMouse.ShakingIntervalMs `"$($this.ShakingIntervalMs)`""
        }

        if ($this.ShakingFactor -ne $null) {
            $Changes.Value += "set FindMyMouse.ShakingFactor `"$($this.ShakingFactor)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.FindMyMouse `"$($this.Enabled)`""
        }


    }
}
class Hosts {
    [DscProperty()] [Nullable[bool]]
    $ShowStartupWarning = $null

    [DscProperty()] [Nullable[bool]]
    $LaunchAdministrator = $null

    [DscProperty()] [Nullable[bool]]
    $LoopbackDuplicates = $null

    [DscProperty()] [HostsAdditionalLinesPosition]
    $AdditionalLinesPosition 

    [DscProperty()] [HostsEncoding]
    $Encoding 

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ShowStartupWarning -ne $null) {
            $Changes.Value += "set Hosts.ShowStartupWarning `"$($this.ShowStartupWarning)`""
        }

        if ($this.LaunchAdministrator -ne $null) {
            $Changes.Value += "set Hosts.LaunchAdministrator `"$($this.LaunchAdministrator)`""
        }

        if ($this.LoopbackDuplicates -ne $null) {
            $Changes.Value += "set Hosts.LoopbackDuplicates `"$($this.LoopbackDuplicates)`""
        }

        if ($this.AdditionalLinesPosition -ne 0) {
            $Changes.Value += "set Hosts.AdditionalLinesPosition `"$($this.AdditionalLinesPosition)`""
        }

        if ($this.Encoding -ne 0) {
            $Changes.Value += "set Hosts.Encoding `"$($this.Encoding)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.Hosts `"$($this.Enabled)`""
        }


    }
}
class ImageResizer {
    [DscProperty()] [Nullable[int]]
    $ImageresizerSelectedSizeIndex = $null

    [DscProperty()] [string]
    $ImageresizerShrinkOnly = $null

    [DscProperty()] [string]
    $ImageresizerReplace = $null

    [DscProperty()] [string]
    $ImageresizerIgnoreOrientation = $null

    [DscProperty()] [Nullable[int]]
    $ImageresizerJpegQualityLevel = $null

    [DscProperty()] [Nullable[int]]
    $ImageresizerPngInterlaceOption = $null

    [DscProperty()] [Nullable[int]]
    $ImageresizerTiffCompressOption = $null

    [DscProperty()] [string]
    $ImageresizerFileName = $null

    [DscProperty()] [string]
    $ImageresizerKeepDateModified = $null

    [DscProperty()] [string]
    $ImageresizerFallbackEncoder = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null

    [DscProperty()] [Hashtable[]]
    $ImageresizerSizes = @()

    ApplyChanges([ref]$Changes) {
        if ($this.ImageresizerSelectedSizeIndex -ne $null) {
            $Changes.Value += "set ImageResizer.ImageresizerSelectedSizeIndex `"$($this.ImageresizerSelectedSizeIndex)`""
        }

        if ($this.ImageresizerShrinkOnly -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerShrinkOnly `"$($this.ImageresizerShrinkOnly)`""
        }

        if ($this.ImageresizerReplace -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerReplace `"$($this.ImageresizerReplace)`""
        }

        if ($this.ImageresizerIgnoreOrientation -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerIgnoreOrientation `"$($this.ImageresizerIgnoreOrientation)`""
        }

        if ($this.ImageresizerJpegQualityLevel -ne $null) {
            $Changes.Value += "set ImageResizer.ImageresizerJpegQualityLevel `"$($this.ImageresizerJpegQualityLevel)`""
        }

        if ($this.ImageresizerPngInterlaceOption -ne $null) {
            $Changes.Value += "set ImageResizer.ImageresizerPngInterlaceOption `"$($this.ImageresizerPngInterlaceOption)`""
        }

        if ($this.ImageresizerTiffCompressOption -ne $null) {
            $Changes.Value += "set ImageResizer.ImageresizerTiffCompressOption `"$($this.ImageresizerTiffCompressOption)`""
        }

        if ($this.ImageresizerFileName -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerFileName `"$($this.ImageresizerFileName)`""
        }

        if ($this.ImageresizerKeepDateModified -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerKeepDateModified `"$($this.ImageresizerKeepDateModified)`""
        }

        if ($this.ImageresizerFallbackEncoder -notlike '') {
            $Changes.Value += "set ImageResizer.ImageresizerFallbackEncoder `"$($this.ImageresizerFallbackEncoder)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.ImageResizer `"$($this.Enabled)`""
        }

        if ($this.ImageresizerSizes.Count -gt 0) {
            $AdditionalPropertiesTmpPath = [System.IO.Path]::GetTempFileName()
            $this.ImageresizerSizes | ConvertTo-Json | Set-Content -Path $AdditionalPropertiesTmpPath
            $Changes.Value += "setAdditional ImageResizer `"$AdditionalPropertiesTmpPath`""
        }
    }
}
class KeyboardManager {
    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.KeyboardManager `"$($this.Enabled)`""
        }


    }
}
class MeasureTool {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [Nullable[bool]]
    $ContinuousCapture = $null

    [DscProperty()] [Nullable[bool]]
    $DrawFeetOnCross = $null

    [DscProperty()] [Nullable[bool]]
    $PerColorChannelEdgeDetection = $null

    [DscProperty()] [Nullable[int]]
    $UnitsOfMeasure = $null

    [DscProperty()] [Nullable[int]]
    $PixelTolerance = $null

    [DscProperty()] [string]
    $MeasureCrossColor = $null

    [DscProperty()] [Nullable[int]]
    $DefaultMeasureStyle = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set MeasureTool.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.ContinuousCapture -ne $null) {
            $Changes.Value += "set MeasureTool.ContinuousCapture `"$($this.ContinuousCapture)`""
        }

        if ($this.DrawFeetOnCross -ne $null) {
            $Changes.Value += "set MeasureTool.DrawFeetOnCross `"$($this.DrawFeetOnCross)`""
        }

        if ($this.PerColorChannelEdgeDetection -ne $null) {
            $Changes.Value += "set MeasureTool.PerColorChannelEdgeDetection `"$($this.PerColorChannelEdgeDetection)`""
        }

        if ($this.UnitsOfMeasure -ne $null) {
            $Changes.Value += "set MeasureTool.UnitsOfMeasure `"$($this.UnitsOfMeasure)`""
        }

        if ($this.PixelTolerance -ne $null) {
            $Changes.Value += "set MeasureTool.PixelTolerance `"$($this.PixelTolerance)`""
        }

        if ($this.MeasureCrossColor -notlike '') {
            $Changes.Value += "set MeasureTool.MeasureCrossColor `"$($this.MeasureCrossColor)`""
        }

        if ($this.DefaultMeasureStyle -ne $null) {
            $Changes.Value += "set MeasureTool.DefaultMeasureStyle `"$($this.DefaultMeasureStyle)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.MeasureTool `"$($this.Enabled)`""
        }


    }
}
class MouseHighlighter {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $LeftButtonClickColor = $null

    [DscProperty()] [string]
    $RightButtonClickColor = $null

    [DscProperty()] [string]
    $AlwaysColor = $null

    [DscProperty()] [Nullable[int]]
    $HighlightRadius = $null

    [DscProperty()] [Nullable[int]]
    $HighlightFadeDelayMs = $null

    [DscProperty()] [Nullable[int]]
    $HighlightFadeDurationMs = $null

    [DscProperty()] [string]
    $AutoActivate = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set MouseHighlighter.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.LeftButtonClickColor -notlike '') {
            $Changes.Value += "set MouseHighlighter.LeftButtonClickColor `"$($this.LeftButtonClickColor)`""
        }

        if ($this.RightButtonClickColor -notlike '') {
            $Changes.Value += "set MouseHighlighter.RightButtonClickColor `"$($this.RightButtonClickColor)`""
        }

        if ($this.AlwaysColor -notlike '') {
            $Changes.Value += "set MouseHighlighter.AlwaysColor `"$($this.AlwaysColor)`""
        }

        if ($this.HighlightRadius -ne $null) {
            $Changes.Value += "set MouseHighlighter.HighlightRadius `"$($this.HighlightRadius)`""
        }

        if ($this.HighlightFadeDelayMs -ne $null) {
            $Changes.Value += "set MouseHighlighter.HighlightFadeDelayMs `"$($this.HighlightFadeDelayMs)`""
        }

        if ($this.HighlightFadeDurationMs -ne $null) {
            $Changes.Value += "set MouseHighlighter.HighlightFadeDurationMs `"$($this.HighlightFadeDurationMs)`""
        }

        if ($this.AutoActivate -notlike '') {
            $Changes.Value += "set MouseHighlighter.AutoActivate `"$($this.AutoActivate)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.MouseHighlighter `"$($this.Enabled)`""
        }


    }
}
class MouseJump {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $ThumbnailSize = $null

    [DscProperty()] [string]
    $PreviewType = $null

    [DscProperty()] [string]
    $BackgroundColor1 = $null

    [DscProperty()] [string]
    $BackgroundColor2 = $null

    [DscProperty()] [Nullable[int]]
    $BorderThickness = $null

    [DscProperty()] [string]
    $BorderColor = $null

    [DscProperty()] [Nullable[int]]
    $Border3dDepth = $null

    [DscProperty()] [Nullable[int]]
    $BorderPadding = $null

    [DscProperty()] [Nullable[int]]
    $BezelThickness = $null

    [DscProperty()] [string]
    $BezelColor = $null

    [DscProperty()] [Nullable[int]]
    $Bezel3dDepth = $null

    [DscProperty()] [Nullable[int]]
    $ScreenMargin = $null

    [DscProperty()] [string]
    $ScreenColor1 = $null

    [DscProperty()] [string]
    $ScreenColor2 = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set MouseJump.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.ThumbnailSize -notlike '') {
            $Changes.Value += "set MouseJump.ThumbnailSize `"$($this.ThumbnailSize)`""
        }

        if ($this.PreviewType -notlike '') {
            $Changes.Value += "set MouseJump.PreviewType `"$($this.PreviewType)`""
        }

        if ($this.BackgroundColor1 -notlike '') {
            $Changes.Value += "set MouseJump.BackgroundColor1 `"$($this.BackgroundColor1)`""
        }

        if ($this.BackgroundColor2 -notlike '') {
            $Changes.Value += "set MouseJump.BackgroundColor2 `"$($this.BackgroundColor2)`""
        }

        if ($this.BorderThickness -ne $null) {
            $Changes.Value += "set MouseJump.BorderThickness `"$($this.BorderThickness)`""
        }

        if ($this.BorderColor -notlike '') {
            $Changes.Value += "set MouseJump.BorderColor `"$($this.BorderColor)`""
        }

        if ($this.Border3dDepth -ne $null) {
            $Changes.Value += "set MouseJump.Border3dDepth `"$($this.Border3dDepth)`""
        }

        if ($this.BorderPadding -ne $null) {
            $Changes.Value += "set MouseJump.BorderPadding `"$($this.BorderPadding)`""
        }

        if ($this.BezelThickness -ne $null) {
            $Changes.Value += "set MouseJump.BezelThickness `"$($this.BezelThickness)`""
        }

        if ($this.BezelColor -notlike '') {
            $Changes.Value += "set MouseJump.BezelColor `"$($this.BezelColor)`""
        }

        if ($this.Bezel3dDepth -ne $null) {
            $Changes.Value += "set MouseJump.Bezel3dDepth `"$($this.Bezel3dDepth)`""
        }

        if ($this.ScreenMargin -ne $null) {
            $Changes.Value += "set MouseJump.ScreenMargin `"$($this.ScreenMargin)`""
        }

        if ($this.ScreenColor1 -notlike '') {
            $Changes.Value += "set MouseJump.ScreenColor1 `"$($this.ScreenColor1)`""
        }

        if ($this.ScreenColor2 -notlike '') {
            $Changes.Value += "set MouseJump.ScreenColor2 `"$($this.ScreenColor2)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.MouseJump `"$($this.Enabled)`""
        }


    }
}
class MousePointerCrosshairs {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $CrosshairsColor = $null

    [DscProperty()] [Nullable[int]]
    $CrosshairsOpacity = $null

    [DscProperty()] [Nullable[int]]
    $CrosshairsRadius = $null

    [DscProperty()] [Nullable[int]]
    $CrosshairsThickness = $null

    [DscProperty()] [string]
    $CrosshairsBorderColor = $null

    [DscProperty()] [Nullable[int]]
    $CrosshairsBorderSize = $null

    [DscProperty()] [string]
    $CrosshairsAutoHide = $null

    [DscProperty()] [string]
    $CrosshairsIsFixedLengthEnabled = $null

    [DscProperty()] [Nullable[int]]
    $CrosshairsFixedLength = $null

    [DscProperty()] [string]
    $AutoActivate = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.CrosshairsColor -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsColor `"$($this.CrosshairsColor)`""
        }

        if ($this.CrosshairsOpacity -ne $null) {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsOpacity `"$($this.CrosshairsOpacity)`""
        }

        if ($this.CrosshairsRadius -ne $null) {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsRadius `"$($this.CrosshairsRadius)`""
        }

        if ($this.CrosshairsThickness -ne $null) {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsThickness `"$($this.CrosshairsThickness)`""
        }

        if ($this.CrosshairsBorderColor -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsBorderColor `"$($this.CrosshairsBorderColor)`""
        }

        if ($this.CrosshairsBorderSize -ne $null) {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsBorderSize `"$($this.CrosshairsBorderSize)`""
        }

        if ($this.CrosshairsAutoHide -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsAutoHide `"$($this.CrosshairsAutoHide)`""
        }

        if ($this.CrosshairsIsFixedLengthEnabled -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsIsFixedLengthEnabled `"$($this.CrosshairsIsFixedLengthEnabled)`""
        }

        if ($this.CrosshairsFixedLength -ne $null) {
            $Changes.Value += "set MousePointerCrosshairs.CrosshairsFixedLength `"$($this.CrosshairsFixedLength)`""
        }

        if ($this.AutoActivate -notlike '') {
            $Changes.Value += "set MousePointerCrosshairs.AutoActivate `"$($this.AutoActivate)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.MousePointerCrosshairs `"$($this.Enabled)`""
        }


    }
}
class MouseWithoutBorders {
    [DscProperty()] [Nullable[bool]]
    $ShowOriginalUI = $null

    [DscProperty()] [Nullable[bool]]
    $WrapMouse = $null

    [DscProperty()] [Nullable[bool]]
    $ShareClipboard = $null

    [DscProperty()] [Nullable[bool]]
    $TransferFile = $null

    [DscProperty()] [Nullable[bool]]
    $HideMouseAtScreenEdge = $null

    [DscProperty()] [Nullable[bool]]
    $DrawMouseCursor = $null

    [DscProperty()] [Nullable[bool]]
    $ValidateRemoteMachineIP = $null

    [DscProperty()] [Nullable[bool]]
    $SameSubnetOnly = $null

    [DscProperty()] [Nullable[bool]]
    $BlockScreenSaverOnOtherMachines = $null

    [DscProperty()] [Nullable[bool]]
    $MoveMouseRelatively = $null

    [DscProperty()] [Nullable[bool]]
    $BlockMouseAtScreenCorners = $null

    [DscProperty()] [Nullable[bool]]
    $ShowClipboardAndNetworkStatusMessages = $null

    [DscProperty()] [Nullable[int]]
    $EasyMouse = $null

    [DscProperty()] [Nullable[int]]
    $HotKeySwitchMachine = $null

    [DscProperty()] [string]
    $ToggleEasyMouseShortcut = $null

    [DscProperty()] [string]
    $LockMachineShortcut = $null

    [DscProperty()] [string]
    $ReconnectShortcut = $null

    [DscProperty()] [string]
    $Switch2AllPCShortcut = $null

    [DscProperty()] [Nullable[bool]]
    $DrawMouseEx = $null

    [DscProperty()] [string]
    $Name2IP = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ShowOriginalUI -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.ShowOriginalUI `"$($this.ShowOriginalUI)`""
        }

        if ($this.WrapMouse -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.WrapMouse `"$($this.WrapMouse)`""
        }

        if ($this.ShareClipboard -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.ShareClipboard `"$($this.ShareClipboard)`""
        }

        if ($this.TransferFile -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.TransferFile `"$($this.TransferFile)`""
        }

        if ($this.HideMouseAtScreenEdge -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.HideMouseAtScreenEdge `"$($this.HideMouseAtScreenEdge)`""
        }

        if ($this.DrawMouseCursor -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.DrawMouseCursor `"$($this.DrawMouseCursor)`""
        }

        if ($this.ValidateRemoteMachineIP -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.ValidateRemoteMachineIP `"$($this.ValidateRemoteMachineIP)`""
        }

        if ($this.SameSubnetOnly -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.SameSubnetOnly `"$($this.SameSubnetOnly)`""
        }

        if ($this.BlockScreenSaverOnOtherMachines -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.BlockScreenSaverOnOtherMachines `"$($this.BlockScreenSaverOnOtherMachines)`""
        }

        if ($this.MoveMouseRelatively -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.MoveMouseRelatively `"$($this.MoveMouseRelatively)`""
        }

        if ($this.BlockMouseAtScreenCorners -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.BlockMouseAtScreenCorners `"$($this.BlockMouseAtScreenCorners)`""
        }

        if ($this.ShowClipboardAndNetworkStatusMessages -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.ShowClipboardAndNetworkStatusMessages `"$($this.ShowClipboardAndNetworkStatusMessages)`""
        }

        if ($this.EasyMouse -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.EasyMouse `"$($this.EasyMouse)`""
        }

        if ($this.HotKeySwitchMachine -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.HotKeySwitchMachine `"$($this.HotKeySwitchMachine)`""
        }

        if ($this.ToggleEasyMouseShortcut -notlike '') {
            $Changes.Value += "set MouseWithoutBorders.ToggleEasyMouseShortcut `"$($this.ToggleEasyMouseShortcut)`""
        }

        if ($this.LockMachineShortcut -notlike '') {
            $Changes.Value += "set MouseWithoutBorders.LockMachineShortcut `"$($this.LockMachineShortcut)`""
        }

        if ($this.ReconnectShortcut -notlike '') {
            $Changes.Value += "set MouseWithoutBorders.ReconnectShortcut `"$($this.ReconnectShortcut)`""
        }

        if ($this.Switch2AllPCShortcut -notlike '') {
            $Changes.Value += "set MouseWithoutBorders.Switch2AllPCShortcut `"$($this.Switch2AllPCShortcut)`""
        }

        if ($this.DrawMouseEx -ne $null) {
            $Changes.Value += "set MouseWithoutBorders.DrawMouseEx `"$($this.DrawMouseEx)`""
        }

        if ($this.Name2IP -notlike '') {
            $Changes.Value += "set MouseWithoutBorders.Name2IP `"$($this.Name2IP)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.MouseWithoutBorders `"$($this.Enabled)`""
        }


    }
}
class NewPlus {
    [DscProperty()] [string]
    $HideFileExtension = $null

    [DscProperty()] [string]
    $HideStartingDigits = $null

    [DscProperty()] [string]
    $TemplateLocation = $null

    [DscProperty()] [string]
    $ReplaceVariables = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.HideFileExtension -notlike '') {
            $Changes.Value += "set NewPlus.HideFileExtension `"$($this.HideFileExtension)`""
        }

        if ($this.HideStartingDigits -notlike '') {
            $Changes.Value += "set NewPlus.HideStartingDigits `"$($this.HideStartingDigits)`""
        }

        if ($this.TemplateLocation -notlike '') {
            $Changes.Value += "set NewPlus.TemplateLocation `"$($this.TemplateLocation)`""
        }

        if ($this.ReplaceVariables -notlike '') {
            $Changes.Value += "set NewPlus.ReplaceVariables `"$($this.ReplaceVariables)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.NewPlus `"$($this.Enabled)`""
        }


    }
}
class Peek {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $AlwaysRunNotElevated = $null

    [DscProperty()] [string]
    $CloseAfterLosingFocus = $null

    [DscProperty()] [string]
    $ConfirmFileDelete = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set Peek.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.AlwaysRunNotElevated -notlike '') {
            $Changes.Value += "set Peek.AlwaysRunNotElevated `"$($this.AlwaysRunNotElevated)`""
        }

        if ($this.CloseAfterLosingFocus -notlike '') {
            $Changes.Value += "set Peek.CloseAfterLosingFocus `"$($this.CloseAfterLosingFocus)`""
        }

        if ($this.ConfirmFileDelete -notlike '') {
            $Changes.Value += "set Peek.ConfirmFileDelete `"$($this.ConfirmFileDelete)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.Peek `"$($this.Enabled)`""
        }


    }
}
class PowerAccent {
    [DscProperty()] [PowerAccentActivationKey]
    $ActivationKey 

    [DscProperty()] [Nullable[bool]]
    $DoNotActivateOnGameMode = $null

    [DscProperty()] [string]
    $ToolbarPosition = $null

    [DscProperty()] [Nullable[int]]
    $InputTime = $null

    [DscProperty()] [string]
    $SelectedLang = $null

    [DscProperty()] [string]
    $ExcludedApps = $null

    [DscProperty()] [Nullable[bool]]
    $ShowUnicodeDescription = $null

    [DscProperty()] [Nullable[bool]]
    $SortByUsageFrequency = $null

    [DscProperty()] [Nullable[bool]]
    $StartSelectionFromTheLeft = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationKey -ne 0) {
            $Changes.Value += "set PowerAccent.ActivationKey `"$($this.ActivationKey)`""
        }

        if ($this.DoNotActivateOnGameMode -ne $null) {
            $Changes.Value += "set PowerAccent.DoNotActivateOnGameMode `"$($this.DoNotActivateOnGameMode)`""
        }

        if ($this.ToolbarPosition -notlike '') {
            $Changes.Value += "set PowerAccent.ToolbarPosition `"$($this.ToolbarPosition)`""
        }

        if ($this.InputTime -ne $null) {
            $Changes.Value += "set PowerAccent.InputTime `"$($this.InputTime)`""
        }

        if ($this.SelectedLang -notlike '') {
            $Changes.Value += "set PowerAccent.SelectedLang `"$($this.SelectedLang)`""
        }

        if ($this.ExcludedApps -notlike '') {
            $Changes.Value += "set PowerAccent.ExcludedApps `"$($this.ExcludedApps)`""
        }

        if ($this.ShowUnicodeDescription -ne $null) {
            $Changes.Value += "set PowerAccent.ShowUnicodeDescription `"$($this.ShowUnicodeDescription)`""
        }

        if ($this.SortByUsageFrequency -ne $null) {
            $Changes.Value += "set PowerAccent.SortByUsageFrequency `"$($this.SortByUsageFrequency)`""
        }

        if ($this.StartSelectionFromTheLeft -ne $null) {
            $Changes.Value += "set PowerAccent.StartSelectionFromTheLeft `"$($this.StartSelectionFromTheLeft)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.PowerAccent `"$($this.Enabled)`""
        }


    }
}
class PowerLauncher {
    [DscProperty()] [Nullable[int]]
    $MaximumNumberOfResults = $null

    [DscProperty()] [string]
    $OpenPowerLauncher = $null

    [DscProperty()] [Nullable[bool]]
    $IgnoreHotkeysInFullscreen = $null

    [DscProperty()] [Nullable[bool]]
    $ClearInputOnLaunch = $null

    [DscProperty()] [Nullable[bool]]
    $TabSelectsContextButtons = $null

    [DscProperty()] [Theme]
    $Theme 

    [DscProperty()] [Nullable[int]]
    $TitleFontSize = $null

    [DscProperty()] [StartupPosition]
    $Position 

    [DscProperty()] [Nullable[bool]]
    $UseCentralizedKeyboardHook = $null

    [DscProperty()] [Nullable[bool]]
    $SearchQueryResultsWithDelay = $null

    [DscProperty()] [Nullable[int]]
    $SearchInputDelay = $null

    [DscProperty()] [Nullable[int]]
    $SearchInputDelayFast = $null

    [DscProperty()] [Nullable[int]]
    $SearchClickedItemWeight = $null

    [DscProperty()] [Nullable[bool]]
    $SearchQueryTuningEnabled = $null

    [DscProperty()] [Nullable[bool]]
    $SearchWaitForSlowResults = $null

    [DscProperty()] [Nullable[bool]]
    $UsePinyin = $null

    [DscProperty()] [Nullable[bool]]
    $GenerateThumbnailsFromFiles = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null

    [DscProperty()] [Hashtable[]]
    $Plugins = @()

    ApplyChanges([ref]$Changes) {
        if ($this.MaximumNumberOfResults -ne $null) {
            $Changes.Value += "set PowerLauncher.MaximumNumberOfResults `"$($this.MaximumNumberOfResults)`""
        }

        if ($this.OpenPowerLauncher -notlike '') {
            $Changes.Value += "set PowerLauncher.OpenPowerLauncher `"$($this.OpenPowerLauncher)`""
        }

        if ($this.IgnoreHotkeysInFullscreen -ne $null) {
            $Changes.Value += "set PowerLauncher.IgnoreHotkeysInFullscreen `"$($this.IgnoreHotkeysInFullscreen)`""
        }

        if ($this.ClearInputOnLaunch -ne $null) {
            $Changes.Value += "set PowerLauncher.ClearInputOnLaunch `"$($this.ClearInputOnLaunch)`""
        }

        if ($this.TabSelectsContextButtons -ne $null) {
            $Changes.Value += "set PowerLauncher.TabSelectsContextButtons `"$($this.TabSelectsContextButtons)`""
        }

        if ($this.Theme -ne 0) {
            $Changes.Value += "set PowerLauncher.Theme `"$($this.Theme)`""
        }

        if ($this.TitleFontSize -ne $null) {
            $Changes.Value += "set PowerLauncher.TitleFontSize `"$($this.TitleFontSize)`""
        }

        if ($this.Position -ne 0) {
            $Changes.Value += "set PowerLauncher.Position `"$($this.Position)`""
        }

        if ($this.UseCentralizedKeyboardHook -ne $null) {
            $Changes.Value += "set PowerLauncher.UseCentralizedKeyboardHook `"$($this.UseCentralizedKeyboardHook)`""
        }

        if ($this.SearchQueryResultsWithDelay -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchQueryResultsWithDelay `"$($this.SearchQueryResultsWithDelay)`""
        }

        if ($this.SearchInputDelay -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchInputDelay `"$($this.SearchInputDelay)`""
        }

        if ($this.SearchInputDelayFast -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchInputDelayFast `"$($this.SearchInputDelayFast)`""
        }

        if ($this.SearchClickedItemWeight -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchClickedItemWeight `"$($this.SearchClickedItemWeight)`""
        }

        if ($this.SearchQueryTuningEnabled -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchQueryTuningEnabled `"$($this.SearchQueryTuningEnabled)`""
        }

        if ($this.SearchWaitForSlowResults -ne $null) {
            $Changes.Value += "set PowerLauncher.SearchWaitForSlowResults `"$($this.SearchWaitForSlowResults)`""
        }

        if ($this.UsePinyin -ne $null) {
            $Changes.Value += "set PowerLauncher.UsePinyin `"$($this.UsePinyin)`""
        }

        if ($this.GenerateThumbnailsFromFiles -ne $null) {
            $Changes.Value += "set PowerLauncher.GenerateThumbnailsFromFiles `"$($this.GenerateThumbnailsFromFiles)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.PowerLauncher `"$($this.Enabled)`""
        }

        if ($this.Plugins.Count -gt 0) {
            $AdditionalPropertiesTmpPath = [System.IO.Path]::GetTempFileName()
            $this.Plugins | ConvertTo-Json | Set-Content -Path $AdditionalPropertiesTmpPath
            $Changes.Value += "setAdditional PowerLauncher `"$AdditionalPropertiesTmpPath`""
        }
    }
}
class PowerOcr {
    [DscProperty()] [string]
    $ActivationShortcut = $null

    [DscProperty()] [string]
    $PreferredLanguage = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ActivationShortcut -notlike '') {
            $Changes.Value += "set PowerOcr.ActivationShortcut `"$($this.ActivationShortcut)`""
        }

        if ($this.PreferredLanguage -notlike '') {
            $Changes.Value += "set PowerOcr.PreferredLanguage `"$($this.PreferredLanguage)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.PowerOcr `"$($this.Enabled)`""
        }


    }
}
class PowerPreview {
    [DscProperty()] [Nullable[bool]]
    $EnableSvgPreview = $null

    [DscProperty()] [Nullable[int]]
    $SvgBackgroundColorMode = $null

    [DscProperty()] [string]
    $SvgBackgroundSolidColor = $null

    [DscProperty()] [Nullable[int]]
    $SvgBackgroundCheckeredShade = $null

    [DscProperty()] [Nullable[bool]]
    $EnableSvgThumbnail = $null

    [DscProperty()] [Nullable[bool]]
    $EnableMdPreview = $null

    [DscProperty()] [Nullable[bool]]
    $EnableMonacoPreview = $null

    [DscProperty()] [Nullable[bool]]
    $EnableMonacoPreviewWordWrap = $null

    [DscProperty()] [Nullable[bool]]
    $MonacoPreviewTryFormat = $null

    [DscProperty()] [Nullable[int]]
    $MonacoPreviewMaxFileSize = $null

    [DscProperty()] [Nullable[int]]
    $MonacoPreviewFontSize = $null

    [DscProperty()] [Nullable[bool]]
    $MonacoPreviewStickyScroll = $null

    [DscProperty()] [Nullable[bool]]
    $MonacoPreviewMinimap = $null

    [DscProperty()] [Nullable[bool]]
    $EnablePdfPreview = $null

    [DscProperty()] [Nullable[bool]]
    $EnablePdfThumbnail = $null

    [DscProperty()] [Nullable[bool]]
    $EnableGcodePreview = $null

    [DscProperty()] [Nullable[bool]]
    $EnableGcodeThumbnail = $null

    [DscProperty()] [Nullable[bool]]
    $EnableStlThumbnail = $null

    [DscProperty()] [string]
    $StlThumbnailColor = $null

    [DscProperty()] [Nullable[bool]]
    $EnableQoiPreview = $null

    [DscProperty()] [Nullable[bool]]
    $EnableQoiThumbnail = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.EnableSvgPreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnableSvgPreview `"$($this.EnableSvgPreview)`""
        }

        if ($this.SvgBackgroundColorMode -ne $null) {
            $Changes.Value += "set PowerPreview.SvgBackgroundColorMode `"$($this.SvgBackgroundColorMode)`""
        }

        if ($this.SvgBackgroundSolidColor -notlike '') {
            $Changes.Value += "set PowerPreview.SvgBackgroundSolidColor `"$($this.SvgBackgroundSolidColor)`""
        }

        if ($this.SvgBackgroundCheckeredShade -ne $null) {
            $Changes.Value += "set PowerPreview.SvgBackgroundCheckeredShade `"$($this.SvgBackgroundCheckeredShade)`""
        }

        if ($this.EnableSvgThumbnail -ne $null) {
            $Changes.Value += "set PowerPreview.EnableSvgThumbnail `"$($this.EnableSvgThumbnail)`""
        }

        if ($this.EnableMdPreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnableMdPreview `"$($this.EnableMdPreview)`""
        }

        if ($this.EnableMonacoPreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnableMonacoPreview `"$($this.EnableMonacoPreview)`""
        }

        if ($this.EnableMonacoPreviewWordWrap -ne $null) {
            $Changes.Value += "set PowerPreview.EnableMonacoPreviewWordWrap `"$($this.EnableMonacoPreviewWordWrap)`""
        }

        if ($this.MonacoPreviewTryFormat -ne $null) {
            $Changes.Value += "set PowerPreview.MonacoPreviewTryFormat `"$($this.MonacoPreviewTryFormat)`""
        }

        if ($this.MonacoPreviewMaxFileSize -ne $null) {
            $Changes.Value += "set PowerPreview.MonacoPreviewMaxFileSize `"$($this.MonacoPreviewMaxFileSize)`""
        }

        if ($this.MonacoPreviewFontSize -ne $null) {
            $Changes.Value += "set PowerPreview.MonacoPreviewFontSize `"$($this.MonacoPreviewFontSize)`""
        }

        if ($this.MonacoPreviewStickyScroll -ne $null) {
            $Changes.Value += "set PowerPreview.MonacoPreviewStickyScroll `"$($this.MonacoPreviewStickyScroll)`""
        }

        if ($this.MonacoPreviewMinimap -ne $null) {
            $Changes.Value += "set PowerPreview.MonacoPreviewMinimap `"$($this.MonacoPreviewMinimap)`""
        }

        if ($this.EnablePdfPreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnablePdfPreview `"$($this.EnablePdfPreview)`""
        }

        if ($this.EnablePdfThumbnail -ne $null) {
            $Changes.Value += "set PowerPreview.EnablePdfThumbnail `"$($this.EnablePdfThumbnail)`""
        }

        if ($this.EnableGcodePreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnableGcodePreview `"$($this.EnableGcodePreview)`""
        }

        if ($this.EnableGcodeThumbnail -ne $null) {
            $Changes.Value += "set PowerPreview.EnableGcodeThumbnail `"$($this.EnableGcodeThumbnail)`""
        }

        if ($this.EnableStlThumbnail -ne $null) {
            $Changes.Value += "set PowerPreview.EnableStlThumbnail `"$($this.EnableStlThumbnail)`""
        }

        if ($this.StlThumbnailColor -notlike '') {
            $Changes.Value += "set PowerPreview.StlThumbnailColor `"$($this.StlThumbnailColor)`""
        }

        if ($this.EnableQoiPreview -ne $null) {
            $Changes.Value += "set PowerPreview.EnableQoiPreview `"$($this.EnableQoiPreview)`""
        }

        if ($this.EnableQoiThumbnail -ne $null) {
            $Changes.Value += "set PowerPreview.EnableQoiThumbnail `"$($this.EnableQoiThumbnail)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.PowerPreview `"$($this.Enabled)`""
        }


    }
}
class PowerRename {
    [DscProperty()] [string]
    $MRUEnabled = $null

    [DscProperty()] [Nullable[int]]
    $MaxMRUSize = $null

    [DscProperty()] [string]
    $ExtendedContextMenuOnly = $null

    [DscProperty()] [string]
    $UseBoostLib = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.MRUEnabled -notlike '') {
            $Changes.Value += "set PowerRename.MRUEnabled `"$($this.MRUEnabled)`""
        }

        if ($this.MaxMRUSize -ne $null) {
            $Changes.Value += "set PowerRename.MaxMRUSize `"$($this.MaxMRUSize)`""
        }

        if ($this.ExtendedContextMenuOnly -notlike '') {
            $Changes.Value += "set PowerRename.ExtendedContextMenuOnly `"$($this.ExtendedContextMenuOnly)`""
        }

        if ($this.UseBoostLib -notlike '') {
            $Changes.Value += "set PowerRename.UseBoostLib `"$($this.UseBoostLib)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.PowerRename `"$($this.Enabled)`""
        }


    }
}
class RegistryPreview {
    [DscProperty()] [Nullable[bool]]
    $DefaultRegApp = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.DefaultRegApp -ne $null) {
            $Changes.Value += "set RegistryPreview.DefaultRegApp `"$($this.DefaultRegApp)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.RegistryPreview `"$($this.Enabled)`""
        }


    }
}
class ShortcutGuide {
    [DscProperty()] [string]
    $OpenShortcutGuide = $null

    [DscProperty()] [Nullable[int]]
    $OverlayOpacity = $null

    [DscProperty()] [string]
    $UseLegacyPressWinKeyBehavior = $null

    [DscProperty()] [Nullable[int]]
    $PressTimeForGlobalWindowsShortcuts = $null

    [DscProperty()] [Nullable[int]]
    $PressTimeForTaskbarIconShortcuts = $null

    [DscProperty()] [string]
    $Theme = $null

    [DscProperty()] [string]
    $DisabledApps = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.OpenShortcutGuide -notlike '') {
            $Changes.Value += "set ShortcutGuide.OpenShortcutGuide `"$($this.OpenShortcutGuide)`""
        }

        if ($this.OverlayOpacity -ne $null) {
            $Changes.Value += "set ShortcutGuide.OverlayOpacity `"$($this.OverlayOpacity)`""
        }

        if ($this.UseLegacyPressWinKeyBehavior -notlike '') {
            $Changes.Value += "set ShortcutGuide.UseLegacyPressWinKeyBehavior `"$($this.UseLegacyPressWinKeyBehavior)`""
        }

        if ($this.PressTimeForGlobalWindowsShortcuts -ne $null) {
            $Changes.Value += "set ShortcutGuide.PressTimeForGlobalWindowsShortcuts `"$($this.PressTimeForGlobalWindowsShortcuts)`""
        }

        if ($this.PressTimeForTaskbarIconShortcuts -ne $null) {
            $Changes.Value += "set ShortcutGuide.PressTimeForTaskbarIconShortcuts `"$($this.PressTimeForTaskbarIconShortcuts)`""
        }

        if ($this.Theme -notlike '') {
            $Changes.Value += "set ShortcutGuide.Theme `"$($this.Theme)`""
        }

        if ($this.DisabledApps -notlike '') {
            $Changes.Value += "set ShortcutGuide.DisabledApps `"$($this.DisabledApps)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.ShortcutGuide `"$($this.Enabled)`""
        }


    }
}
class Workspaces {
    [DscProperty()] [string]
    $Hotkey = $null

    [DscProperty()] [SortByProperty]
    $SortBy 

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.Hotkey -notlike '') {
            $Changes.Value += "set Workspaces.Hotkey `"$($this.Hotkey)`""
        }

        if ($this.SortBy -ne 0) {
            $Changes.Value += "set Workspaces.SortBy `"$($this.SortBy)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.Workspaces `"$($this.Enabled)`""
        }


    }
}
class ZoomIt {
    [DscProperty()] [string]
    $ToggleKey = $null

    [DscProperty()] [string]
    $LiveZoomToggleKey = $null

    [DscProperty()] [string]
    $DrawToggleKey = $null

    [DscProperty()] [string]
    $RecordToggleKey = $null

    [DscProperty()] [string]
    $SnipToggleKey = $null

    [DscProperty()] [string]
    $BreakTimerKey = $null

    [DscProperty()] [string]
    $Font = $null

    [DscProperty()] [string]
    $DemoTypeToggleKey = $null

    [DscProperty()] [string]
    $DemoTypeFile = $null

    [DscProperty()] [Nullable[int]]
    $DemoTypeSpeedSlider = $null

    [DscProperty()] [string]
    $DemoTypeUserDrivenMode = $null

    [DscProperty()] [Nullable[int]]
    $BreakTimeout = $null

    [DscProperty()] [Nullable[int]]
    $BreakOpacity = $null

    [DscProperty()] [string]
    $BreakPlaySoundFile = $null

    [DscProperty()] [string]
    $BreakSoundFile = $null

    [DscProperty()] [string]
    $BreakShowBackgroundFile = $null

    [DscProperty()] [string]
    $BreakBackgroundStretch = $null

    [DscProperty()] [string]
    $BreakBackgroundFile = $null

    [DscProperty()] [Nullable[int]]
    $BreakTimerPosition = $null

    [DscProperty()] [string]
    $BreakShowDesktop = $null

    [DscProperty()] [string]
    $ShowExpiredTime = $null

    [DscProperty()] [string]
    $ShowTrayIcon = $null

    [DscProperty()] [string]
    $AnimnateZoom = $null

    [DscProperty()] [Nullable[int]]
    $ZoominSliderLevel = $null

    [DscProperty()] [Nullable[int]]
    $RecordScaling = $null

    [DscProperty()] [string]
    $CaptureAudio = $null

    [DscProperty()] [string]
    $MicrophoneDeviceId = $null

    [DscProperty(Key)] [Nullable[bool]]
    $Enabled = $null
    ApplyChanges([ref]$Changes) {
        if ($this.ToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.ToggleKey `"$($this.ToggleKey)`""
        }

        if ($this.LiveZoomToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.LiveZoomToggleKey `"$($this.LiveZoomToggleKey)`""
        }

        if ($this.DrawToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.DrawToggleKey `"$($this.DrawToggleKey)`""
        }

        if ($this.RecordToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.RecordToggleKey `"$($this.RecordToggleKey)`""
        }

        if ($this.SnipToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.SnipToggleKey `"$($this.SnipToggleKey)`""
        }

        if ($this.BreakTimerKey -notlike '') {
            $Changes.Value += "set ZoomIt.BreakTimerKey `"$($this.BreakTimerKey)`""
        }

        if ($this.Font -notlike '') {
            $Changes.Value += "set ZoomIt.Font `"$($this.Font)`""
        }

        if ($this.DemoTypeToggleKey -notlike '') {
            $Changes.Value += "set ZoomIt.DemoTypeToggleKey `"$($this.DemoTypeToggleKey)`""
        }

        if ($this.DemoTypeFile -notlike '') {
            $Changes.Value += "set ZoomIt.DemoTypeFile `"$($this.DemoTypeFile)`""
        }

        if ($this.DemoTypeSpeedSlider -ne $null) {
            $Changes.Value += "set ZoomIt.DemoTypeSpeedSlider `"$($this.DemoTypeSpeedSlider)`""
        }

        if ($this.DemoTypeUserDrivenMode -notlike '') {
            $Changes.Value += "set ZoomIt.DemoTypeUserDrivenMode `"$($this.DemoTypeUserDrivenMode)`""
        }

        if ($this.BreakTimeout -ne $null) {
            $Changes.Value += "set ZoomIt.BreakTimeout `"$($this.BreakTimeout)`""
        }

        if ($this.BreakOpacity -ne $null) {
            $Changes.Value += "set ZoomIt.BreakOpacity `"$($this.BreakOpacity)`""
        }

        if ($this.BreakPlaySoundFile -notlike '') {
            $Changes.Value += "set ZoomIt.BreakPlaySoundFile `"$($this.BreakPlaySoundFile)`""
        }

        if ($this.BreakSoundFile -notlike '') {
            $Changes.Value += "set ZoomIt.BreakSoundFile `"$($this.BreakSoundFile)`""
        }

        if ($this.BreakShowBackgroundFile -notlike '') {
            $Changes.Value += "set ZoomIt.BreakShowBackgroundFile `"$($this.BreakShowBackgroundFile)`""
        }

        if ($this.BreakBackgroundStretch -notlike '') {
            $Changes.Value += "set ZoomIt.BreakBackgroundStretch `"$($this.BreakBackgroundStretch)`""
        }

        if ($this.BreakBackgroundFile -notlike '') {
            $Changes.Value += "set ZoomIt.BreakBackgroundFile `"$($this.BreakBackgroundFile)`""
        }

        if ($this.BreakTimerPosition -ne $null) {
            $Changes.Value += "set ZoomIt.BreakTimerPosition `"$($this.BreakTimerPosition)`""
        }

        if ($this.BreakShowDesktop -notlike '') {
            $Changes.Value += "set ZoomIt.BreakShowDesktop `"$($this.BreakShowDesktop)`""
        }

        if ($this.ShowExpiredTime -notlike '') {
            $Changes.Value += "set ZoomIt.ShowExpiredTime `"$($this.ShowExpiredTime)`""
        }

        if ($this.ShowTrayIcon -notlike '') {
            $Changes.Value += "set ZoomIt.ShowTrayIcon `"$($this.ShowTrayIcon)`""
        }

        if ($this.AnimnateZoom -notlike '') {
            $Changes.Value += "set ZoomIt.AnimnateZoom `"$($this.AnimnateZoom)`""
        }

        if ($this.ZoominSliderLevel -ne $null) {
            $Changes.Value += "set ZoomIt.ZoominSliderLevel `"$($this.ZoominSliderLevel)`""
        }

        if ($this.RecordScaling -ne $null) {
            $Changes.Value += "set ZoomIt.RecordScaling `"$($this.RecordScaling)`""
        }

        if ($this.CaptureAudio -notlike '') {
            $Changes.Value += "set ZoomIt.CaptureAudio `"$($this.CaptureAudio)`""
        }

        if ($this.MicrophoneDeviceId -notlike '') {
            $Changes.Value += "set ZoomIt.MicrophoneDeviceId `"$($this.MicrophoneDeviceId)`""
        }

        if ($this.Enabled -ne $null) {
            $Changes.Value += "set General.Enabled.ZoomIt `"$($this.Enabled)`""
        }


    }
}
class GeneralSettings {
    [DscProperty()] [Nullable[bool]]
    $Startup = $null

    [DscProperty()] [Nullable[bool]]
    $ShowSysTrayIcon = $null

    [DscProperty()] [Nullable[bool]]
    $EnableWarningsElevatedApps = $null

    [DscProperty()] [string]
    $Theme = $null

    [DscProperty()] [Nullable[bool]]
    $ShowNewUpdatesToastNotification = $null

    [DscProperty()] [Nullable[bool]]
    $AutoDownloadUpdates = $null

    [DscProperty()] [Nullable[bool]]
    $ShowWhatsNewAfterUpdates = $null

    [DscProperty()] [Nullable[bool]]
    $EnableExperimentation = $null

    ApplyChanges([ref]$Changes) {
        if ($this.Startup -ne $null) {
            $Changes.Value += "set GeneralSettings.Startup `"$($this.Startup)`""
        }

        if ($this.ShowSysTrayIcon -ne $null) {
            $Changes.Value += "set GeneralSettings.ShowSysTrayIcon `"$($this.ShowSysTrayIcon)`""
        }

        if ($this.EnableWarningsElevatedApps -ne $null) {
            $Changes.Value += "set GeneralSettings.EnableWarningsElevatedApps `"$($this.EnableWarningsElevatedApps)`""
        }

        if ($this.Theme -notlike '') {
            $Changes.Value += "set GeneralSettings.Theme `"$($this.Theme)`""
        }

        if ($this.ShowNewUpdatesToastNotification -ne $null) {
            $Changes.Value += "set GeneralSettings.ShowNewUpdatesToastNotification `"$($this.ShowNewUpdatesToastNotification)`""
        }

        if ($this.AutoDownloadUpdates -ne $null) {
            $Changes.Value += "set GeneralSettings.AutoDownloadUpdates `"$($this.AutoDownloadUpdates)`""
        }

        if ($this.ShowWhatsNewAfterUpdates -ne $null) {
            $Changes.Value += "set GeneralSettings.ShowWhatsNewAfterUpdates `"$($this.ShowWhatsNewAfterUpdates)`""
        }

        if ($this.EnableExperimentation -ne $null) {
            $Changes.Value += "set GeneralSettings.EnableExperimentation `"$($this.EnableExperimentation)`""
        }




    }
}

[DscResource()]
class PowerToysConfigure {
    [DscProperty(Key)] [PowerToysConfigureEnsure]
    $Ensure = [PowerToysConfigureEnsure]::Present

    [bool] $Debug = $false

    [DscProperty()]
    [AdvancedPaste]$AdvancedPaste = [AdvancedPaste]::new()

    [DscProperty()]
    [AlwaysOnTop]$AlwaysOnTop = [AlwaysOnTop]::new()

    [DscProperty()]
    [Awake]$Awake = [Awake]::new()

    [DscProperty()]
    [ColorPicker]$ColorPicker = [ColorPicker]::new()

    [DscProperty()]
    [CropAndLock]$CropAndLock = [CropAndLock]::new()

    [DscProperty()]
    [EnvironmentVariables]$EnvironmentVariables = [EnvironmentVariables]::new()

    [DscProperty()]
    [FancyZones]$FancyZones = [FancyZones]::new()

    [DscProperty()]
    [FileLocksmith]$FileLocksmith = [FileLocksmith]::new()

    [DscProperty()]
    [FindMyMouse]$FindMyMouse = [FindMyMouse]::new()

    [DscProperty()]
    [Hosts]$Hosts = [Hosts]::new()

    [DscProperty()]
    [ImageResizer]$ImageResizer = [ImageResizer]::new()

    [DscProperty()]
    [KeyboardManager]$KeyboardManager = [KeyboardManager]::new()

    [DscProperty()]
    [MeasureTool]$MeasureTool = [MeasureTool]::new()

    [DscProperty()]
    [MouseHighlighter]$MouseHighlighter = [MouseHighlighter]::new()

    [DscProperty()]
    [MouseJump]$MouseJump = [MouseJump]::new()

    [DscProperty()]
    [MousePointerCrosshairs]$MousePointerCrosshairs = [MousePointerCrosshairs]::new()

    [DscProperty()]
    [MouseWithoutBorders]$MouseWithoutBorders = [MouseWithoutBorders]::new()

    [DscProperty()]
    [NewPlus]$NewPlus = [NewPlus]::new()

    [DscProperty()]
    [Peek]$Peek = [Peek]::new()

    [DscProperty()]
    [PowerAccent]$PowerAccent = [PowerAccent]::new()

    [DscProperty()]
    [PowerLauncher]$PowerLauncher = [PowerLauncher]::new()

    [DscProperty()]
    [PowerOcr]$PowerOcr = [PowerOcr]::new()

    [DscProperty()]
    [PowerPreview]$PowerPreview = [PowerPreview]::new()

    [DscProperty()]
    [PowerRename]$PowerRename = [PowerRename]::new()

    [DscProperty()]
    [RegistryPreview]$RegistryPreview = [RegistryPreview]::new()

    [DscProperty()]
    [ShortcutGuide]$ShortcutGuide = [ShortcutGuide]::new()

    [DscProperty()]
    [Workspaces]$Workspaces = [Workspaces]::new()

    [DscProperty()]
    [ZoomIt]$ZoomIt = [ZoomIt]::new()

    [DscProperty()]
    [GeneralSettings]$GeneralSettings = [GeneralSettings]::new()


    [string] GetPowerToysSettingsPath() {
        $installation = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq "PowerToys (Preview)" -and $_.DisplayVersion -eq "0.92.0" }

        if (-not $installation)
        {
            $installation = Get-ChildItem HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq "PowerToys (Preview)" -and $_.DisplayVersion -eq "0.92.0" }
        }

        if ($installation) {
            $SettingsExePath = Join-Path (Join-Path $installation.InstallLocation WinUI3Apps) PowerToys.Settings.exe
            $SettingsExePath = "`"$SettingsExePath`""
        } else {
            throw "PowerToys installation wasn't found."
        }

        return $SettingsExePath
    }

    [PowerToysConfigure] Get() {
        $CurrentState = [PowerToysConfigure]::new()
        $SettingsExePath = $this.GetPowerToysSettingsPath()
        $SettingsTmpFilePath = [System.IO.Path]::GetTempFileName()

        $SettingsToRequest = @{}
        foreach ($module in $CurrentState.PSObject.Properties) {
            $moduleName = $module.Name
            # Skip utility properties
            if ($moduleName -eq "Ensure" -or $moduleName -eq "Debug") {
                continue
            }

            $moduleProperties = $module.Value
            $propertiesArray = @() 
            foreach ($property in $moduleProperties.PSObject.Properties) {
                $propertyName = $property.Name
                # Skip Enabled properties - they should be requested from GeneralSettings
                if ($propertyName -eq "Enabled") {
                    continue
                }

                $propertiesArray += $propertyName
            }

            $SettingsToRequest[$moduleName] = $propertiesArray
        }

        $settingsJson = $SettingsToRequest | ConvertTo-Json
        $settingsJson | Set-Content -Path $SettingsTmpFilePath

        Start-Process -FilePath $SettingsExePath -Wait -Args "get `"$SettingsTmpFilePath`""
        $SettingsValues = Get-Content -Path $SettingsTmpFilePath -Raw

        if ($this.Debug -eq $true) {
            $TempFilePath = Join-Path -Path $env:TEMP -ChildPath "PowerToys.DSC.TestConfigure.txt"
            Set-Content -Path "$TempFilePath" -Value ("Requested:`r`n" + $settingsJson + "`r`n" + "Got:`r`n" + $SettingsValues + "`r`n" + (Get-Date -Format "o")) -Force
        }

        $SettingsValues = $SettingsValues | ConvertFrom-Json
        foreach ($module in $SettingsValues.PSObject.Properties) {
            $moduleName = $module.Name
            $obtainedModuleSettings = $module.Value
            $moduleRef = $CurrentState.$moduleName
            foreach ($property in $obtainedModuleSettings.PSObject.Properties) {
                $propertyName = $property.Name
                $moduleRef.$propertyName = $property.Value
            }
        }

        Remove-Item -Path $SettingsTmpFilePath

        return $CurrentState
    }

    [bool] Test() {
        # NB: we must always assume that the configuration isn't applied, because changing some settings produce external side-effects
        return $false 
    }

    [void] Set() {
        $SettingsExePath = $this.GetPowerToysSettingsPath()
        $ChangesToApply = @()

        $this.AdvancedPaste.ApplyChanges([ref]$ChangesToApply)
        $this.AlwaysOnTop.ApplyChanges([ref]$ChangesToApply)
        $this.Awake.ApplyChanges([ref]$ChangesToApply)
        $this.ColorPicker.ApplyChanges([ref]$ChangesToApply)
        $this.CropAndLock.ApplyChanges([ref]$ChangesToApply)
        $this.EnvironmentVariables.ApplyChanges([ref]$ChangesToApply)
        $this.FancyZones.ApplyChanges([ref]$ChangesToApply)
        $this.FileLocksmith.ApplyChanges([ref]$ChangesToApply)
        $this.FindMyMouse.ApplyChanges([ref]$ChangesToApply)
        $this.Hosts.ApplyChanges([ref]$ChangesToApply)
        $this.ImageResizer.ApplyChanges([ref]$ChangesToApply)
        $this.KeyboardManager.ApplyChanges([ref]$ChangesToApply)
        $this.MeasureTool.ApplyChanges([ref]$ChangesToApply)
        $this.MouseHighlighter.ApplyChanges([ref]$ChangesToApply)
        $this.MouseJump.ApplyChanges([ref]$ChangesToApply)
        $this.MousePointerCrosshairs.ApplyChanges([ref]$ChangesToApply)
        $this.MouseWithoutBorders.ApplyChanges([ref]$ChangesToApply)
        $this.NewPlus.ApplyChanges([ref]$ChangesToApply)
        $this.Peek.ApplyChanges([ref]$ChangesToApply)
        $this.PowerAccent.ApplyChanges([ref]$ChangesToApply)
        $this.PowerLauncher.ApplyChanges([ref]$ChangesToApply)
        $this.PowerOcr.ApplyChanges([ref]$ChangesToApply)
        $this.PowerPreview.ApplyChanges([ref]$ChangesToApply)
        $this.PowerRename.ApplyChanges([ref]$ChangesToApply)
        $this.RegistryPreview.ApplyChanges([ref]$ChangesToApply)
        $this.ShortcutGuide.ApplyChanges([ref]$ChangesToApply)
        $this.Workspaces.ApplyChanges([ref]$ChangesToApply)
        $this.ZoomIt.ApplyChanges([ref]$ChangesToApply)
        $this.GeneralSettings.ApplyChanges([ref]$ChangesToApply)
    
        if ($this.Debug -eq $true) {
            $tmp_info = $ChangesToApply
            # $tmp_info = $this | ConvertTo-Json -Depth 10

            $TempFilePath = Join-Path -Path $env:TEMP -ChildPath "PowerToys.DSC.TestConfigure.txt"
            Set-Content -Path "$TempFilePath" -Value ($tmp_info + "`r`n" + (Get-Date -Format "o")) -Force
        } 

        # Stop any running PowerToys instances
        Stop-Process -Name "PowerToys.Settings" -Force -PassThru | Wait-Process
        $PowerToysProcessStopped = Stop-Process -Name "PowerToys" -Force -PassThru
        $PowerToysProcessStopped | Wait-Process

        foreach ($change in $ChangesToApply) {
            Start-Process -FilePath $SettingsExePath -Wait -Args "$change"
        }

        # If the PowerToys process was stopped, restart it.
        if ($PowerToysProcessStopped -ne $null) {
            Start-Process -FilePath $SettingsExePath
        }
    }
}
#endregion DscResources
# SIG # Begin signature block
# MIIoVQYJKoZIhvcNAQcCoIIoRjCCKEICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAE0Z9Qc+WtgOoO
# ZIuxMOPmxwWapvXUezqcZNY4bn5NMqCCDYUwggYDMIID66ADAgECAhMzAAAEA73V
# lV0POxitAAAAAAQDMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjQwOTEyMjAxMTEzWhcNMjUwOTExMjAxMTEzWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCfdGddwIOnbRYUyg03O3iz19XXZPmuhEmW/5uyEN+8mgxl+HJGeLGBR8YButGV
# LVK38RxcVcPYyFGQXcKcxgih4w4y4zJi3GvawLYHlsNExQwz+v0jgY/aejBS2EJY
# oUhLVE+UzRihV8ooxoftsmKLb2xb7BoFS6UAo3Zz4afnOdqI7FGoi7g4vx/0MIdi
# kwTn5N56TdIv3mwfkZCFmrsKpN0zR8HD8WYsvH3xKkG7u/xdqmhPPqMmnI2jOFw/
# /n2aL8W7i1Pasja8PnRXH/QaVH0M1nanL+LI9TsMb/enWfXOW65Gne5cqMN9Uofv
# ENtdwwEmJ3bZrcI9u4LZAkujAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU6m4qAkpz4641iK2irF8eWsSBcBkw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzUwMjkyNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AFFo/6E4LX51IqFuoKvUsi80QytGI5ASQ9zsPpBa0z78hutiJd6w154JkcIx/f7r
# EBK4NhD4DIFNfRiVdI7EacEs7OAS6QHF7Nt+eFRNOTtgHb9PExRy4EI/jnMwzQJV
# NokTxu2WgHr/fBsWs6G9AcIgvHjWNN3qRSrhsgEdqHc0bRDUf8UILAdEZOMBvKLC
# rmf+kJPEvPldgK7hFO/L9kmcVe67BnKejDKO73Sa56AJOhM7CkeATrJFxO9GLXos
# oKvrwBvynxAg18W+pagTAkJefzneuWSmniTurPCUE2JnvW7DalvONDOtG01sIVAB
# +ahO2wcUPa2Zm9AiDVBWTMz9XUoKMcvngi2oqbsDLhbK+pYrRUgRpNt0y1sxZsXO
# raGRF8lM2cWvtEkV5UL+TQM1ppv5unDHkW8JS+QnfPbB8dZVRyRmMQ4aY/tx5x5+
# sX6semJ//FbiclSMxSI+zINu1jYerdUwuCi+P6p7SmQmClhDM+6Q+btE2FtpsU0W
# +r6RdYFf/P+nK6j2otl9Nvr3tWLu+WXmz8MGM+18ynJ+lYbSmFWcAj7SYziAfT0s
# IwlQRFkyC71tsIZUhBHtxPliGUu362lIO0Lpe0DOrg8lspnEWOkHnCT5JEnWCbzu
# iVt8RX1IV07uIveNZuOBWLVCzWJjEGa+HhaEtavjy6i7MIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCGiYwghoiAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAQDvdWVXQ87GK0AAAAA
# BAMwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHQB
# m4ospc7iOPiLDvZiJtGMn8Ug7HQKmuczC4cfKlodMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAQiHb9ysUozbzO+Wwdqvyv/VUd9DSYQ/9Qydv
# F8n2RAUw6X5YAhRqBsbXj1Z4V0GKHbJuGHR6rP+DhSZNv0ClHX3IiU6ohv+TauiR
# 9GqxaJVeAh0E4fnOq3c8YeoY5PwXP2c/kAtcV/tH9aA0Sw776b16lTAsWWp/lmpu
# tzxcv21HxGDtuR+NJeByV5kfJqZu1J66gdCxKxlpxakz3AIe47sqW99dTVxOg6f4
# C68GhFogfUhCulEowNFy29wZAVn9NZoD749JetbT7S5FbK0o84DHzakTY2G0F4ie
# q8vyMAJi3JoJ65F4QZT44RTIEZ9D7DTihiIyKIK+hyWWgjbmPqGCF7AwghesBgor
# BgEEAYI3AwMBMYIXnDCCF5gGCSqGSIb3DQEHAqCCF4kwgheFAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFaBgsqhkiG9w0BCRABBKCCAUkEggFFMIIBQQIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCB+12patdIlpNPm7KNbI12DhKZS0dJzzSHx
# 2R7t7I3zwwIGaFLLQST+GBMyMDI1MDcwMTE0MDcxOS4wODdaMASAAgH0oIHZpIHW
# MIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsT
# Hm5TaGllbGQgVFNTIEVTTjoyQTFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEf4wggcoMIIFEKADAgECAhMzAAAB+R9n
# jXWrpPGxAAEAAAH5MA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMB4XDTI0MDcyNTE4MzEwOVoXDTI1MTAyMjE4MzEwOVowgdMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jv
# c29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEnMCUGA1UECxMeblNoaWVs
# ZCBUU1MgRVNOOjJBMUEtMDVFMC1EOTQ3MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# tD1MH3yAHWHNVslC+CBTj/Mpd55LDPtQrhN7WeqFhReC9xKXSjobW1ZHzHU8V2BO
# JUiYg7fDJ2AxGVGyovUtgGZg2+GauFKk3ZjjsLSsqehYIsUQrgX+r/VATaW8/ONW
# y6lOyGZwZpxfV2EX4qAh6mb2hadAuvdbRl1QK1tfBlR3fdeCBQG+ybz9JFZ45LN2
# ps8Nc1xr41N8Qi3KVJLYX0ibEbAkksR4bbszCzvY+vdSrjWyKAjR6YgYhaBaDxE2
# KDJ2sQRFFF/egCxKgogdF3VIJoCE/Wuy9MuEgypea1Hei7lFGvdLQZH5Jo2QR5uN
# 8hiMc8Z47RRJuIWCOeyIJ1YnRiiibpUZ72+wpv8LTov0yH6C5HR/D8+AT4vqtP57
# ITXsD9DPOob8tjtsefPcQJebUNiqyfyTL5j5/J+2d+GPCcXEYoeWZ+nrsZSfrd5D
# HM4ovCmD3lifgYnzjOry4ghQT/cvmdHwFr6yJGphW/HG8GQd+cB4w7wGpOhHVJby
# 44kGVK8MzY9s32Dy1THnJg8p7y1sEGz/A1y84Zt6gIsITYaccHhBKp4cOVNrfoRV
# Ux2G/0Tr7Dk3fpCU8u+5olqPPwKgZs57jl+lOrRVsX1AYEmAnyCyGrqRAzpGXyk1
# HvNIBpSNNuTBQk7FBvu+Ypi6A7S2V2Tj6lzYWVBvuGECAwEAAaOCAUkwggFFMB0G
# A1UdDgQWBBSJ7aO6nJXJI9eijzS5QkR2RlngADAfBgNVHSMEGDAWgBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENB
# JTIwMjAxMCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRp
# bWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBYGA1Ud
# JQEB/wQMMAoGCCsGAQUFBwMIMA4GA1UdDwEB/wQEAwIHgDANBgkqhkiG9w0BAQsF
# AAOCAgEAZiAJgFbkf7jfhx/mmZlnGZrpae+HGpxWxs8I79vUb8GQou50M1ns7iwG
# 2CcdoXaq7VgpVkNf1uvIhrGYpKCBXQ+SaJ2O0BvwuJR7UsgTaKN0j/yf3fpHD0kt
# H+EkEuGXs9DBLyt71iutVkwow9iQmSk4oIK8S8ArNGpSOzeuu9TdJjBjsasmuJ+2
# q5TjmrgEKyPe3TApAio8cdw/b1cBAmjtI7tpNYV5PyRI3K1NhuDgfEj5kynGF/ui
# zP1NuHSxF/V1ks/2tCEoriicM4k1PJTTA0TCjNbkpmBcsAMlxTzBnWsqnBCt9d+U
# d9Va3Iw9Bs4ccrkgBjLtg3vYGYar615ofYtU+dup+LuU0d2wBDEG1nhSWHaO+u2y
# 6Si3AaNINt/pOMKU6l4AW0uDWUH39OHH3EqFHtTssZXaDOjtyRgbqMGmkf8KI3qI
# VBZJ2XQpnhEuRbh+AgpmRn/a410Dk7VtPg2uC422WLC8H8IVk/FeoiSS4vFodhnc
# FetJ0ZK36wxAa3FiPgBebRWyVtZ763qDDzxDb0mB6HL9HEfTbN+4oHCkZa1HKl8B
# 0s8RiFBMf/W7+O7EPZ+wMH8wdkjZ7SbsddtdRgRARqR8IFPWurQ+sn7ftEifaojz
# uCEahSAcq86yjwQeTPN9YG9b34RTurnkpD+wPGTB1WccMpsLlM0wggdxMIIFWaAD
# AgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIy
# MjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5
# vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64
# NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhu
# je3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl
# 3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPg
# yY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I
# 5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2
# ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/
# TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy
# 16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y
# 1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6H
# XtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMB
# AAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQW
# BBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30B
# ATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3Bz
# L0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYB
# BAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMB
# Af8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBL
# oEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
# BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNS
# b29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1Vffwq
# reEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27
# DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pv
# vinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9Ak
# vUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWK
# NsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2
# kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+
# c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep
# 8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+Dvk
# txW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1Zyvg
# DbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/
# 2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIDWTCCAkECAQEwggEBoYHZpIHW
# MIHTMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQL
# EyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJzAlBgNVBAsT
# Hm5TaGllbGQgVFNTIEVTTjoyQTFBLTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAqs5WjWO7zVAK
# mIcdwhqgZvyp6UaggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQsFAAIFAOwNw5wwIhgPMjAyNTA3MDEwMjE3MDBaGA8yMDI1
# MDcwMjAyMTcwMFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA7A3DnAIBADAKAgEA
# AgIPEwIB/zAHAgEAAgISHjAKAgUA7A8VHAIBADA2BgorBgEEAYRZCgQCMSgwJjAM
# BgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEB
# CwUAA4IBAQAwTB4mIb9NPK8rN0vB0ZNb3GMS6FuVJAhLzenb+G12jixb0F3VB1ds
# qz9TrjzwRB9GjEiE6EkcyQ9gVRl4YzuNkNc7F1cJocpeIWKdGzEPT4IpG9oaeMEU
# ulh2VUennTsya9ZGlS9uKYG+xibHyi5re6rBO53u3WPZT3o+PpxS2kifamqdMhT9
# KWUvJA3v3XdSEbRetcG8SFDx4gJTGp4pmq8RF/BFpo5zIRanosogf+vItW4XkDQB
# O3ur9NYO6vkgCmuz9bGgQdolSQBHZldSw0R7DjVJcWqT1zPGG0ad1tJl186j2uxK
# htP9ZE4QMJ94zce1TLFubpwUbVtrPTydMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAH5H2eNdauk8bEAAQAAAfkwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQgYLFPam7X1/mMGnMesh3qzMLCIzf8LQHvuzfEwnJ36UEwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCA5I4zIHvCN+2T66RUOLCZrUEVdoKlKl8Ve
# CO5SbGLYEDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAAB+R9njXWrpPGxAAEAAAH5MCIEIH/Af+BtzUgyEwt0FCAojrUBl6X7p+6zx74o
# vySlI2dKMA0GCSqGSIb3DQEBCwUABIICADjy7ldO98zhV7HzCnr+Nk7+0j6Jag1X
# GDStS+mWuTiTkxZY4J45d6JtfIodi3oAUqtriW+EFFJnYmb8H96NrE6DvKEuQyUQ
# dVR2Oax0/kXJeklRqnSg9dZ58UgSCXqEH3F/sU3NrWha3SqCLLXEod89QRN58yaD
# 0Spqm3afbUHYqKegxfC0mI8btpdBqz7O2w0KFb4v13XgTxYjecwJaGoTpN1BJEcU
# CItNMc43JXm6ITc78Er8f49lpsE0nXE3YV8Xtsr1oblkunTvcsfTPOUrPQWfyjNI
# JS1vrwueBlSNemYSmFfJhc/F3/e+lM0e5k/uuaADmqHW3nT8CZGH669oa06QMmsf
# VsqKnHWBGdwrBnpgkXlAgYGlzqCgy8a4qKQHYpohNjXZ/gxHMj+9FklI5l+gKw1B
# 0AeINSqGATTOfp7InT96d7RP3VZoe7FQlKAe3V/m2osdknSK3L/nvViASFF2WKU3
# bp56hb5l1mWwxWtiObdxAuK9S59ul4nMHjrGskvUx8/inccJjxXqbxGdutZ/mvJX
# 3uSHuu0AjfpE8zxFDv2K6sFkFXXhghmheSpmVedPciFUovIByj5hpSfJPD9KglfJ
# 0/u2Anpa9BxrC21HcJva3bQt7dWzbLcGm3glSaKXtwqc67VdzoLrhMCQBWhPCKCP
# vHNZAeC6NDme
# SIG # End signature block
