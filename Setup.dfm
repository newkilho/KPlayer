object FrmSetup: TFrmSetup
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #54872#44221#49444#51221
  ClientHeight = 560
  ClientWidth = 780
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnHide = FormHide
  OnShow = FormShow
  TextHeight = 15
  object PnlMenu: TPanel
    Left = 0
    Top = 0
    Width = 113
    Height = 560
    Align = alLeft
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    DesignSize = (
      113
      560)
    object BtnGeneral: TSpeedButton
      Left = 8
      Top = 8
      Width = 99
      Height = 32
      GroupIndex = 1
      Down = True
      Caption = #51068#48152
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnVideo: TSpeedButton
      Tag = 1
      Left = 8
      Top = 46
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #50689#49345
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnAudio: TSpeedButton
      Tag = 2
      Left = 8
      Top = 84
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #51020#49457
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnSub: TSpeedButton
      Tag = 3
      Left = 8
      Top = 122
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #51088#47561
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnAssoc: TSpeedButton
      Tag = 4
      Left = 8
      Top = 160
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #50672#44208
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnKeys: TSpeedButton
      Tag = 5
      Left = 8
      Top = 198
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #45800#52629#53412
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnMouse: TSpeedButton
      Tag = 6
      Left = 8
      Top = 236
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #47560#50864#49828
      Flat = True
      OnClick = BtnNavClick
    end
    object BtnAbout: TSpeedButton
      Tag = 7
      Left = 8
      Top = 274
      Width = 99
      Height = 32
      GroupIndex = 1
      Caption = #51221#48372
      Flat = True
      OnClick = BtnNavClick
    end
    object LineMenu: TShape
      Left = 112
      Top = 0
      Width = 1
      Height = 560
      Align = alRight
      Brush.Color = 15395562
      Pen.Color = 15395562
    end
    object BtnReset: TButton
      Left = 8
      Top = 518
      Width = 99
      Height = 30
      Anchors = [akLeft, akBottom]
      Caption = #44592#48376#44050' '#48373#50896
      TabOrder = 0
      OnClick = BtnResetClick
    end
  end
  object PnlRight: TPanel
    Left = 113
    Top = 0
    Width = 667
    Height = 560
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object PnlHeader: TPanel
      Left = 0
      Top = 0
      Width = 667
      Height = 56
      Align = alTop
      BevelOuter = bvNone
      ParentColor = True
      TabOrder = 0
      object LblTitle: TLabel
        Left = 24
        Top = 18
        Width = 120
        Height = 25
        AutoSize = False
        Caption = #51068#48152
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object LineHeader: TShape
        Left = 0
        Top = 55
        Width = 667
        Height = 1
        Align = alBottom
        Brush.Color = 15395562
        Pen.Color = 15395562
      end
    end
    object PnlMain: TCardPanel
      Left = 0
      Top = 56
      Width = 667
      Height = 504
      Align = alClient
      ActiveCard = CardGeneral
      BevelOuter = bvNone
      ParentColor = True
      TabOrder = 1
      object CardGeneral: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 0
        ParentColor = True
        TabOrder = 0
        object BoxGeneral: TScrollBox
          Left = 0
          Top = 0
          Width = 667
          Height = 504
          HorzScrollBar.Visible = False
          VertScrollBar.Margin = 24
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            667
            504)
          object LblRepeat: TLabel
            Left = 24
            Top = 21
            Width = 51
            Height = 15
            Caption = #48152#48373' '#47784#46300
            Transparent = True
          end
          object LblRandom: TLabel
            Left = 24
            Top = 85
            Width = 51
            Height = 15
            Caption = #47004#45924' '#51116#49373
            Transparent = True
          end
          object LblSaveList: TLabel
            Left = 24
            Top = 149
            Width = 75
            Height = 15
            Caption = #51116#49373#47785#47197' '#51200#51109
            Transparent = True
          end
          object LblShotDir: TLabel
            Left = 24
            Top = 213
            Width = 75
            Height = 15
            Caption = #49828#53356#47536#49399' '#54260#45908
            Transparent = True
          end
          object LblShotFmt: TLabel
            Left = 24
            Top = 277
            Width = 24
            Height = 15
            Caption = #54805#49885
            Transparent = True
          end
          object LblTopMost: TLabel
            Left = 24
            Top = 341
            Width = 39
            Height = 15
            Caption = #54637#49345' '#50948
            Transparent = True
          end
          object LblWinSize: TLabel
            Left = 24
            Top = 405
            Width = 66
            Height = 15
            Caption = #51116#49373' '#52285' '#53356#44592
            Transparent = True
          end
          object CboRepeat: TComboBox
            Left = 473
            Top = 28
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 0
            OnChange = ControlChange
            Items.Strings = (
              #48152#48373' '#50630#51020
              #51204#52404' '#48152#48373
              #54620' '#44257' '#48152#48373)
          end
          object CboRandom: TComboBox
            Left = 473
            Top = 92
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 1
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object CboSaveList: TComboBox
            Left = 473
            Top = 156
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 2
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object EdtShotDir: TEdit
            Left = 325
            Top = 220
            Width = 250
            Height = 23
            Anchors = [akTop, akRight]
            ReadOnly = True
            TabOrder = 3
          end
          object BtnShotDir: TButton
            Left = 583
            Top = 219
            Width = 60
            Height = 26
            Anchors = [akTop, akRight]
            Caption = #52286#44592
            TabOrder = 4
            OnClick = BtnShotDirClick
          end
          object CboShotFmt: TComboBox
            Left = 473
            Top = 284
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 5
            OnChange = ControlChange
            Items.Strings = (
              'JPG'
              'PNG')
          end
          object CboTopMost: TComboBox
            Left = 473
            Top = 348
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 6
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object CboWinSize: TComboBox
            Left = 473
            Top = 412
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 7
            OnChange = ControlChange
            Items.Strings = (
              #47560#51648#47561' '#53356#44592' '#50976#51648
              #50689#49345' '#53356#44592#50640' '#47582#52644
              #51204#52404' '#54868#47732)
          end
        end
      end
      object CardVideo: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 1
        ParentColor = True
        TabOrder = 1
        object BoxVideo: TScrollBox
          Left = 0
          Top = 0
          Width = 667
          Height = 504
          HorzScrollBar.Visible = False
          VertScrollBar.Margin = 24
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            667
            504)
          object LblHwdec: TLabel
            Left = 24
            Top = 21
            Width = 87
            Height = 15
            Caption = #54616#46300#50920#50612' '#46356#53076#46377
            Transparent = True
          end
          object LblVo: TLabel
            Left = 24
            Top = 85
            Width = 75
            Height = 15
            Caption = #52636#47141' '#46300#46972#51060#48260
            Transparent = True
          end
          object LblGpuApi: TLabel
            Left = 24
            Top = 149
            Width = 57
            Height = 15
            Caption = #44536#47000#54589' API'
            Transparent = True
          end
          object LblVideoSync: TLabel
            Left = 24
            Top = 213
            Width = 63
            Height = 15
            Caption = #54868#47732' '#46041#44592#54868
            Transparent = True
          end
          object LblScale: TLabel
            Left = 24
            Top = 277
            Width = 60
            Height = 15
            Caption = #50629#49828#52992#51068#47084
            Transparent = True
          end
          object LblDeint: TLabel
            Left = 24
            Top = 341
            Width = 87
            Height = 15
            Caption = #51064#53552#47112#51060#49828' '#54644#51228
            Transparent = True
          end
          object CboHwdec: TComboBox
            Left = 473
            Top = 28
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 0
            OnChange = ControlChange
            Items.Strings = (
              #51088#46041'('#50504#51204')'
              #51088#46041
              #49324#50857' '#50504' '#54632)
          end
          object CboVo: TComboBox
            Left = 473
            Top = 92
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 1
            OnChange = ControlChange
            Items.Strings = (
              'gpu'
              'gpu-next')
          end
          object CboGpuApi: TComboBox
            Left = 473
            Top = 156
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 2
            OnChange = ControlChange
            Items.Strings = (
              #51088#46041
              'Direct3D 11'
              'OpenGL'
              'Vulkan')
          end
          object CboVideoSync: TComboBox
            Left = 473
            Top = 220
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 3
            OnChange = ControlChange
            Items.Strings = (
              #46356#49828#54540#47112#51060' '#47532#49368#54540
              #50724#46356#50724' '#44592#51456)
          end
          object CboScale: TComboBox
            Left = 473
            Top = 284
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 4
            OnChange = ControlChange
            Items.Strings = (
              'lanczos'
              'bilinear'
              'spline36'
              'ewa_lanczos')
          end
          object CboDeint: TComboBox
            Left = 473
            Top = 348
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 5
            OnChange = ControlChange
            Items.Strings = (
              #51088#46041
              #54637#49345' '#49324#50857
              #49324#50857' '#50504' '#54632)
          end
        end
      end
      object CardAudio: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 2
        ParentColor = True
        TabOrder = 2
        object BoxAudio: TScrollBox
          Left = 0
          Top = 0
          Width = 667
          Height = 504
          HorzScrollBar.Visible = False
          VertScrollBar.Margin = 24
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            667
            504)
          object LblVolume: TLabel
            Left = 24
            Top = 21
            Width = 51
            Height = 15
            Caption = #44592#48376' '#48380#47464
            Transparent = True
          end
          object LblVolumeValue: TLabel
            Left = 397
            Top = 32
            Width = 48
            Height = 15
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            AutoSize = False
            Caption = '0'
            Transparent = True
          end
          object LblNormalize: TLabel
            Left = 24
            Top = 85
            Width = 90
            Height = 15
            Caption = #51020#47049' '#54217#51456#54868' '#49324#50857
            Transparent = True
          end
          object LblNormLevel: TLabel
            Left = 24
            Top = 152
            Width = 63
            Height = 15
            Caption = #54217#51456#54868' '#44053#46020
            Transparent = True
          end
          object TrkVolume: TTrackBar
            Left = 453
            Top = 26
            Width = 190
            Height = 28
            Anchors = [akTop, akRight]
            Max = 100
            PageSize = 5
            Frequency = 10
            ShowSelRange = False
            TabOrder = 0
            TickStyle = tsNone
            OnChange = TrackChange
          end
          object CboNormalize: TComboBox
            Left = 473
            Top = 93
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 1
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object CboNormLevel: TComboBox
            Left = 473
            Top = 148
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 2
            OnChange = ControlChange
            Items.Strings = (
              #45230#44172
              #48372#53685
              #44053#54616#44172)
          end
        end
      end
      object CardSub: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 3
        ParentColor = True
        TabOrder = 3
        object BoxSub: TScrollBox
          Left = 0
          Top = 0
          Width = 667
          Height = 504
          HorzScrollBar.Visible = False
          VertScrollBar.Margin = 24
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            650
            504)
          object LblSubVisible: TLabel
            Left = 24
            Top = 21
            Width = 78
            Height = 15
            Caption = #51088#47561' '#44592#48376' '#54364#49884
            Transparent = True
          end
          object LblSubSize: TLabel
            Left = 24
            Top = 88
            Width = 51
            Height = 15
            Caption = #51088#47561' '#53356#44592
            Transparent = True
          end
          object LblSubSizeValue: TLabel
            Left = 397
            Top = 88
            Width = 48
            Height = 15
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            AutoSize = False
            Caption = '0'
            Transparent = True
          end
          object LblSubLang: TLabel
            Left = 24
            Top = 133
            Width = 78
            Height = 15
            Caption = #44592#48376' '#51088#47561' '#50616#50612
            Transparent = True
          end
          object LblSubFont: TLabel
            Left = 24
            Top = 185
            Width = 24
            Height = 15
            Caption = #44544#44852
            Transparent = True
          end
          object LblSubBold: TLabel
            Left = 24
            Top = 230
            Width = 24
            Height = 15
            Caption = #44405#44172
            Transparent = True
          end
          object LblSubColor: TLabel
            Left = 24
            Top = 275
            Width = 36
            Height = 15
            Caption = #44544#51088#49353
            Transparent = True
          end
          object LblSubBorder: TLabel
            Left = 24
            Top = 365
            Width = 63
            Height = 15
            Caption = #50808#44285#49440' '#46160#44760
            Transparent = True
          end
          object LblSubBorderValue: TLabel
            Left = 397
            Top = 365
            Width = 48
            Height = 15
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            AutoSize = False
            Caption = '0'
            Transparent = True
          end
          object LblSubBorderColor: TLabel
            Left = 24
            Top = 320
            Width = 51
            Height = 15
            Caption = #50808#44285#49440' '#49353
            Transparent = True
          end
          object LblSubShadow: TLabel
            Left = 24
            Top = 410
            Width = 36
            Height = 15
            Caption = #44536#47548#51088
            Transparent = True
          end
          object LblSubShadowValue: TLabel
            Left = 397
            Top = 410
            Width = 48
            Height = 15
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            AutoSize = False
            Caption = '0'
            Transparent = True
          end
          object LblSubPos: TLabel
            Left = 24
            Top = 455
            Width = 51
            Height = 15
            Caption = #49464#47196' '#50948#52824
            Transparent = True
          end
          object LblSubPosValue: TLabel
            Left = 397
            Top = 455
            Width = 48
            Height = 15
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            AutoSize = False
            Caption = '0'
            Transparent = True
          end
          object LblSubAlign: TLabel
            Left = 24
            Top = 500
            Width = 24
            Height = 15
            Caption = #51221#47148
            Transparent = True
          end
          object LblSubAss: TLabel
            Left = 24
            Top = 545
            Width = 117
            Height = 15
            Caption = #51088#47561' '#54028#51068' '#49828#53440#51068' '#50864#49440
            Transparent = True
          end
          object ShpSubColor: TShape
            Left = 513
            Top = 282
            Width = 60
            Height = 21
            Anchors = [akTop, akRight]
            Pen.Color = clGray
          end
          object ShpSubBorderColor: TShape
            Left = 513
            Top = 327
            Width = 60
            Height = 21
            Anchors = [akTop, akRight]
            Pen.Color = clGray
          end
          object CboSubVisible: TComboBox
            Left = 473
            Top = 29
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 0
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object TrkSubSize: TTrackBar
            Left = 453
            Top = 82
            Width = 190
            Height = 28
            Anchors = [akTop, akRight]
            Max = 100
            Min = 20
            PageSize = 5
            Frequency = 10
            Position = 20
            ShowSelRange = False
            TabOrder = 1
            TickStyle = tsNone
            OnChange = TrackChange
          end
          object EdtSubLang: TEdit
            Left = 393
            Top = 140
            Width = 250
            Height = 23
            Anchors = [akTop, akRight]
            TabOrder = 2
            OnChange = ControlChange
          end
          object CboSubFont: TComboBox
            Left = 393
            Top = 192
            Width = 250
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 3
            OnChange = ControlChange
          end
          object CboSubBold: TComboBox
            Left = 473
            Top = 237
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 4
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
          object BtnSubColor: TButton
            Left = 583
            Top = 281
            Width = 60
            Height = 23
            Anchors = [akTop, akRight]
            Caption = #48320#44221
            TabOrder = 5
            OnClick = BtnSubColorClick
          end
          object TrkSubBorder: TTrackBar
            Left = 453
            Top = 359
            Width = 190
            Height = 28
            Anchors = [akTop, akRight]
            Max = 5
            PageSize = 1
            ShowSelRange = False
            TabOrder = 6
            TickStyle = tsNone
            OnChange = TrackChange
          end
          object BtnSubBorderColor: TButton
            Left = 583
            Top = 326
            Width = 60
            Height = 23
            Anchors = [akTop, akRight]
            Caption = #48320#44221
            TabOrder = 7
            OnClick = BtnSubColorClick
          end
          object TrkSubShadow: TTrackBar
            Left = 453
            Top = 404
            Width = 190
            Height = 28
            Anchors = [akTop, akRight]
            Max = 5
            PageSize = 1
            ShowSelRange = False
            TabOrder = 8
            TickStyle = tsNone
            OnChange = TrackChange
          end
          object TrkSubPos: TTrackBar
            Left = 453
            Top = 449
            Width = 190
            Height = 28
            Anchors = [akTop, akRight]
            Max = 100
            PageSize = 5
            Frequency = 10
            ShowSelRange = False
            TabOrder = 9
            TickStyle = tsNone
            OnChange = TrackChange
          end
          object CboSubAlign: TComboBox
            Left = 473
            Top = 507
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 10
            OnChange = ControlChange
            Items.Strings = (
              #50812#51901
              #44032#50868#45936
              #50724#47480#51901)
          end
          object CboSubAss: TComboBox
            Left = 473
            Top = 552
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 11
            OnChange = ControlChange
            Items.Strings = (
              #49324#50857#50504#54632
              #49324#50857#54632)
          end
        end
      end
      object CardAssoc: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 4
        ParentColor = True
        TabOrder = 4
        DesignSize = (
          667
          504)
        object LblAssocHint: TLabel
          Left = 344
          Top = 100
          Width = 300
          Height = 90
          Anchors = [akTop, akRight]
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Transparent = True
          WordWrap = True
        end
        object TreeAssoc: TVirtualStringTree
          Left = 24
          Top = 12
          Width = 300
          Height = 480
          DefaultNodeHeight = 28
          Header.AutoSizeIndex = 0
          Header.Height = 15
          Header.MainColumn = -1
          Header.Options = []
          Indent = 20
          ScrollBarOptions.ScrollBars = ssVertical
          TabOrder = 0
          OnChecked = TreeAssocChecked
          OnFreeNode = TreeAssocFreeNode
          OnGetText = TreeAssocGetText
          OnPaintText = TreeAssocPaintText
          OnGetImageIndex = TreeAssocGetImageIndex
          Touch.InteractiveGestures = [igPan, igPressAndTap]
          Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
          Columns = <>
        end
        object BtnAssocAll: TButton
          Tag = 1
          Left = 344
          Top = 12
          Width = 145
          Height = 30
          Anchors = [akTop, akRight]
          Caption = #47784#46160' '#49440#53469
          TabOrder = 1
          OnClick = BtnAssocSelectClick
        end
        object BtnAssocNone: TButton
          Tag = 2
          Left = 499
          Top = 12
          Width = 145
          Height = 30
          Anchors = [akTop, akRight]
          Caption = #47784#46160' '#54644#51228
          TabOrder = 2
          OnClick = BtnAssocSelectClick
        end
        object BtnAssocMain: TButton
          Left = 344
          Top = 50
          Width = 145
          Height = 30
          Anchors = [akTop, akRight]
          Caption = #51452#50836' '#54028#51068
          TabOrder = 3
          OnClick = BtnAssocSelectClick
        end
        object MemoAssocLog: TMemo
          Left = 344
          Top = 200
          Width = 300
          Height = 252
          Anchors = [akTop, akRight, akBottom]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 5
          WordWrap = False
        end
        object BtnAssocDefaults: TButton
          Left = 344
          Top = 462
          Width = 300
          Height = 30
          Anchors = [akRight, akBottom]
          Caption = 'Windows '#44592#48376' '#50545' '#49444#51221' '#50676#44592
          TabOrder = 4
          OnClick = BtnAssocDefaultsClick
        end
      end
      object CardKeys: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 5
        ParentColor = True
        TabOrder = 5
        DesignSize = (
          667
          504)
        object LblKeyHint: TLabel
          Left = 444
          Top = 12
          Width = 200
          Height = 60
          Anchors = [akTop, akRight]
          AutoSize = False
          Caption = #47785#47197#50640#49436' '#46041#51089#51012' '#44256#47480' '#46244' '#50500#47000' '#52856#51012' '#45572#47476#44256' '#53412#47484' '#51077#47141#54616#49464#50836'. ESC, TAB '#51008' '#48148#44992' '#49688' '#50630#49845#45768#45796'.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGray
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          Transparent = True
          WordWrap = True
        end
        object LblKeyAction: TLabel
          Left = 444
          Top = 84
          Width = 200
          Height = 15
          Anchors = [akTop, akRight]
          AutoSize = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
        end
        object LvKeys: TListView
          Left = 24
          Top = 12
          Width = 400
          Height = 480
          Anchors = [akLeft, akTop, akBottom]
          Columns = <
            item
              Caption = #46041#51089
              Width = 270
            end
            item
              Caption = #45800#52629#53412
              Width = 105
            end>
          ColumnClick = False
          HideSelection = False
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnSelectItem = LvKeysSelectItem
        end
        object EdtKey: TEdit
          Left = 444
          Top = 105
          Width = 200
          Height = 23
          Anchors = [akTop, akRight]
          ReadOnly = True
          TabOrder = 1
          OnKeyDown = EdtKeyKeyDown
          OnKeyPress = EdtKeyKeyPress
        end
        object BtnKeyClear: TButton
          Left = 444
          Top = 136
          Width = 200
          Height = 30
          Anchors = [akTop, akRight]
          Caption = #51648#50864#44592
          TabOrder = 2
          OnClick = BtnKeyClearClick
        end
        object BtnKeyDefault: TButton
          Left = 444
          Top = 462
          Width = 200
          Height = 30
          Anchors = [akRight, akBottom]
          Caption = #45800#52629#53412' '#44592#48376#44050
          TabOrder = 3
          OnClick = BtnKeyDefaultClick
        end
      end
      object CardMouse: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 6
        ParentColor = True
        TabOrder = 6
        object BoxMouse: TScrollBox
          Left = 0
          Top = 0
          Width = 667
          Height = 504
          HorzScrollBar.Visible = False
          VertScrollBar.Margin = 24
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            667
            504)
          object LblMLClick: TLabel
            Left = 24
            Top = 21
            Width = 108
            Height = 15
            Caption = #50812#51901' '#48260#53948' '#54620' '#48264' '#53364#47533
            Transparent = True
          end
          object LblMDblClick: TLabel
            Left = 24
            Top = 85
            Width = 108
            Height = 15
            Caption = #50812#51901' '#48260#53948' '#46160' '#48264' '#53364#47533
            Transparent = True
          end
          object LblMMClick: TLabel
            Left = 24
            Top = 149
            Width = 90
            Height = 15
            Caption = #44032#50868#45936' '#48260#53948' '#53364#47533
            Transparent = True
          end
          object LblMWheelUp: TLabel
            Left = 24
            Top = 213
            Width = 39
            Height = 15
            Caption = #55072' '#50948#47196
            Transparent = True
          end
          object LblMWheelDown: TLabel
            Left = 24
            Top = 277
            Width = 51
            Height = 15
            Caption = #55072' '#50500#47000#47196
            Transparent = True
          end
          object CboMLClick: TComboBox
            Left = 473
            Top = 28
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 0
            OnChange = ControlChange
          end
          object CboMDblClick: TComboBox
            Left = 473
            Top = 92
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 1
            OnChange = ControlChange
          end
          object CboMMClick: TComboBox
            Left = 473
            Top = 156
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 2
            OnChange = ControlChange
          end
          object CboMWheelUp: TComboBox
            Left = 473
            Top = 220
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 3
            OnChange = ControlChange
          end
          object CboMWheelDown: TComboBox
            Left = 473
            Top = 284
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 4
            OnChange = ControlChange
          end
        end
      end
      object CardAbout: TCard
        Left = 0
        Top = 0
        Width = 667
        Height = 504
        CardIndex = 7
        ParentColor = True
        TabOrder = 7
        DesignSize = (
          667
          504)
        object MemAbout: TMemo
          Left = 24
          Top = 16
          Width = 619
          Height = 472
          Anchors = [akLeft, akTop, akRight, akBottom]
          BorderStyle = bsNone
          Color = clWhite
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
  end
end
