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
  Position = poScreenCenter
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
    Left = 32
    Top = 16
    object BtnAbout: TMenuItem
      Caption = #47564#46304#51060' '#50724#44600#54840
    end
  end
end
