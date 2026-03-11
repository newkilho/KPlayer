object FrmList: TFrmList
  Left = 0
  Top = 0
  Caption = #51116#49373#47785#47197
  ClientHeight = 321
  ClientWidth = 198
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  TextHeight = 15
  object ListData: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 198
    Height = 280
    Align = alClient
    DefaultNodeHeight = 19
    Header.AutoSizeIndex = 0
    Header.Height = 15
    Header.MainColumn = -1
    PopupMenu = PopMenu
    ScrollBarOptions.ScrollBars = ssNone
    TabOrder = 0
    OnFreeNode = ListDataFreeNode
    OnGetText = ListDataGetText
    OnPaintText = ListDataPaintText
    OnMeasureItem = ListDataMeasureItem
    OnMouseDown = ListDataMouseDown
    OnMouseMove = ListDataMouseMove
    OnMouseUp = ListDataMouseUp
    OnNodeDblClick = ListDataNodeDblClick
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object Panel1: TPanel
    Left = 0
    Top = 280
    Width = 198
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object BtnRepeat: TSVGIconImage
      Tag = 1
      Left = 10
      Top = 12
      Width = 16
      Height = 16
      AutoSize = False
      ImageList = ListIcon
      ImageIndex = 0
      ImageName = 'repeat'
      FixedColor = clBlack
      OnMouseDown = BtnRepeatMouseDown
      OnMouseEnter = BtnRepeatMouseEnter
      OnMouseLeave = BtnRepeatMouseLeave
      OnMouseUp = BtnRepeatMouseUp
    end
    object BtnRandom: TSVGIconImage
      Tag = 2
      Left = 32
      Top = 12
      Width = 16
      Height = 16
      AutoSize = False
      ImageList = ListIcon
      ImageIndex = 2
      ImageName = 'random'
      FixedColor = clBlack
      OnMouseDown = BtnRepeatMouseDown
      OnMouseEnter = BtnRepeatMouseEnter
      OnMouseLeave = BtnRepeatMouseLeave
      OnMouseUp = BtnRepeatMouseUp
    end
    object BtnAdd: TSVGIconImage
      Tag = 3
      Left = 148
      Top = 12
      Width = 16
      Height = 16
      AutoSize = False
      ImageList = ListIcon
      ImageIndex = 3
      ImageName = 'plus'
      FixedColor = clBlack
      OnMouseDown = BtnRepeatMouseDown
      OnMouseEnter = BtnRepeatMouseEnter
      OnMouseLeave = BtnRepeatMouseLeave
      OnMouseUp = BtnRepeatMouseUp
    end
    object BtnDel: TSVGIconImage
      Tag = 4
      Left = 170
      Top = 12
      Width = 16
      Height = 16
      AutoSize = False
      ImageList = ListIcon
      ImageIndex = 4
      ImageName = 'minus'
      FixedColor = clBlack
      OnMouseDown = BtnRepeatMouseDown
      OnMouseEnter = BtnRepeatMouseEnter
      OnMouseLeave = BtnRepeatMouseLeave
      OnMouseUp = BtnRepeatMouseUp
    end
  end
  object ListIcon: TSVGIconImageList
    SVGIconItems = <
      item
        IconName = 'repeat'
        SVGText = 
          '<?xml version="1.0" encoding="utf-8"?>'#10#13'<!-- Uploaded to: SVG Re' +
          'po, www.svgrepo.com, Generator: SVG Repo Mixer Tools -->'#10'<svg wi' +
          'dth="800px" height="800px" viewBox="0 0 24 24" xmlns="http://www' +
          '.w3.org/2000/svg">'#10'    <g>'#10'        <path fill="none" d="M0 0h24v' +
          '24H0z"/>'#10'        <path d="M8 20v1.932a.5.5 0 0 1-.82.385l-4.12-3' +
          '.433A.5.5 0 0 1 3.382 18H18a2 2 0 0 0 2-2V8h2v8a4 4 0 0 1-4 4H8z' +
          'm8-16V2.068a.5.5 0 0 1 .82-.385l4.12 3.433a.5.5 0 0 1-.321.884H6' +
          'a2 2 0 0 0-2 2v8H2V8a4 4 0 0 1 4-4h10z"/>'#10'    </g>'#10'</svg>'
      end
      item
        IconName = 'repeat-one'
        SVGText = 
          '<?xml version="1.0" encoding="utf-8"?>'#10#13'<!-- Uploaded to: SVG Re' +
          'po, www.svgrepo.com, Generator: SVG Repo Mixer Tools -->'#10'<svg wi' +
          'dth="800px" height="800px" viewBox="0 0 24 24" xmlns="http://www' +
          '.w3.org/2000/svg">'#10'    <g>'#10'        <path fill="none" d="M0 0h24v' +
          '24H0z"/>'#10'        <path d="M8 20v1.932a.5.5 0 0 1-.82.385l-4.12-3' +
          '.433A.5.5 0 0 1 3.382 18H18a2 2 0 0 0 2-2V8h2v8a4 4 0 0 1-4 4H8z' +
          'm8-17.932a.5.5 0 0 1 .82-.385l4.12 3.433a.5.5 0 0 1-.321.884H6a2' +
          ' 2 0 0 0-2 2v8H2V8a4 4 0 0 1 4-4h10V2.068zM11 8h2v8h-2v-6H9V9l2-' +
          '1z"/>'#10'    </g>'#10'</svg>'
      end
      item
        IconName = 'random'
        SVGText = 
          '<?xml version="1.0" encoding="utf-8"?><!-- Uploaded to: SVG Repo' +
          ', www.svgrepo.com, Generator: SVG Repo Mixer Tools -->'#10'<svg fill' +
          '="#000000" width="800px" height="800px" viewBox="0 0 256 256" id' +
          '="Flat" xmlns="http://www.w3.org/2000/svg">'#10'  <path d="M237.6572' +
          '3,178.34277a8.00122,8.00122,0,0,1,0,11.31446l-24,24A8.00066,8.00' +
          '066,0,0,1,200,208V191.98584a72.13911,72.13911,0,0,1-57.65332-30.' +
          '13721L100.63379,103.4502A56.11029,56.11029,0,0,0,55.06445,80H32a' +
          '8,8,0,0,1,0-16H55.06445a72.14126,72.14126,0,0,1,58.58887,30.1513' +
          '7l41.71289,58.39843A56.0996,56.0996,0,0,0,200,175.97168V160a8.00' +
          '065,8.00065,0,0,1,13.65723-5.65723Zm-94.64356-71.36132a7.99621,7' +
          '.99621,0,0,0,11.15918-1.86036l1.19336-1.67089A56.0996,56.0996,0,' +
          '0,1,200,80.02832V96a8.00053,8.00053,0,0,0,13.65723,5.65723l24-24' +
          'a8.00122,8.00122,0,0,0,0-11.31446l-24-24A8.00065,8.00065,0,0,0,2' +
          '00,48V64.01416a72.13911,72.13911,0,0,0-57.65332,30.13721l-1.1933' +
          '6,1.6709A7.9986,7.9986,0,0,0,143.01367,106.98145Zm-30.02734,42.0' +
          '371a7.99642,7.99642,0,0,0-11.15918,1.86036l-1.19336,1.67089A56.1' +
          '1029,56.11029,0,0,1,55.06445,176H32a8,8,0,0,0,0,16H55.06445a72.1' +
          '4126,72.14126,0,0,0,58.58887-30.15137l1.19336-1.6709A7.9986,7.99' +
          '86,0,0,0,112.98633,149.01855Z"/>'#10'</svg>'
      end
      item
        IconName = 'plus'
        SVGText = 
          '<?xml version="1.0" encoding="utf-8"?><!-- Uploaded to: SVG Repo' +
          ', www.svgrepo.com, Generator: SVG Repo Mixer Tools -->'#13#10'<svg wid' +
          'th="800px" height="800px" viewBox="0 0 24 24" fill="none" xmlns=' +
          '"http://www.w3.org/2000/svg">'#13#10'<path d="M6 12H18M12 6V18" stroke' +
          '="#000000" stroke-width="2" stroke-linecap="round" stroke-linejo' +
          'in="round"/>'#13#10'</svg>'
      end
      item
        IconName = 'minus'
        SVGText = 
          '<?xml version="1.0" encoding="utf-8"?><!-- Uploaded to: SVG Repo' +
          ', www.svgrepo.com, Generator: SVG Repo Mixer Tools -->'#13#10'<svg wid' +
          'th="800px" height="800px" viewBox="0 0 24 24" fill="none" xmlns=' +
          '"http://www.w3.org/2000/svg">'#13#10'<path d="M6 12L18 12" stroke="#00' +
          '0000" stroke-width="2" stroke-linecap="round" stroke-linejoin="r' +
          'ound"/>'#13#10'</svg>'
      end>
    Scaled = True
    Left = 16
    Top = 72
  end
  object PopAdd: TPopupMenu
    AutoHotkeys = maManual
    Left = 16
    Top = 8
    object BtnAddPopup: TMenuItem
      Caption = #54028#51068
      OnClick = BtnAddPopupClick
    end
    object BtnAddPopupFolder: TMenuItem
      Caption = #54260#45908
      OnClick = BtnAddPopupFolderClick
    end
  end
  object PopDel: TPopupMenu
    AutoHotkeys = maManual
    Left = 64
    Top = 8
    object BtnDelPopup: TMenuItem
      Caption = #49440#53469#46108' '#54028#51068
      OnClick = BtnDelPopupClick
    end
    object BtnDelPopupUnselected: TMenuItem
      Caption = #49440#53469' '#50504' '#46108' '#54028#51068
      OnClick = BtnDelPopupUnselectedClick
    end
    object BtnDelPopupAll: TMenuItem
      Caption = #51204#48512
      OnClick = BtnDelPopupAllClick
    end
    object BtnDelPopupMissing: TMenuItem
      Caption = #51316#51116#54616#51648' '#50506#45716' '#54028#51068
      OnClick = BtnDelPopupMissingClick
    end
  end
  object PopMenu: TPopupMenu
    AutoHotkeys = maManual
    Left = 112
    Top = 8
    object BtnDelContext: TMenuItem
      Caption = #49325#51228
      OnClick = BtnDelContextClick
    end
  end
end
