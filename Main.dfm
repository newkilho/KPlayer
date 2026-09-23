object FrmKPlayer: TFrmKPlayer
  Left = 0
  Top = 0
  Caption = 'KPlayer'
  ClientHeight = 273
  ClientWidth = 352
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  PopupMenu = Menu
  Position = poDesigned
  OnCanResize = FormCanResize
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnMouseDown = FormMouseDown
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  TextHeight = 15
  object Menu: TPopupMenu
    AutoHotkeys = maManual
    OnPopup = MenuPopup
    Left = 32
    Top = 16
    object MnuOpenFile: TMenuItem
      Caption = #54028#51068' '#50676#44592
      OnClick = MnuOpenFileClick
    end
    object MnuOpenFolder: TMenuItem
      Caption = #54260#45908' '#50676#44592
      OnClick = MnuOpenFolderClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object MnuScreen: TMenuItem
      Caption = #54868#47732' '#53356#44592
      object MnuOrig50: TMenuItem
        Tag = 50
        Caption = '50%'
        OnClick = MnuOriginalClick
      end
      object MnuOrig100: TMenuItem
        Tag = 100
        Caption = '100%'
        OnClick = MnuOriginalClick
      end
      object MnuOrig150: TMenuItem
        Tag = 150
        Caption = '150%'
        OnClick = MnuOriginalClick
      end
      object MnuOrig200: TMenuItem
        Tag = 200
        Caption = '200%'
        OnClick = MnuOriginalClick
      end
      object MnuFull: TMenuItem
        Caption = #51204#52404' '#54868#47732
        OnClick = MnuFullClick
      end
      object MnuStretch: TMenuItem
        Caption = #44873#52268' '#54868#47732
        OnClick = MnuStretchClick
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object BtnAbout: TMenuItem
      Caption = #47564#46304#51060' '#50724#44600#54840
      OnClick = BtnAboutClick
    end
  end
end
