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
  OnCreate = FormCreate
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
    object BtnAbout: TSpeedButton
      Tag = 5
      Left = 8
      Top = 198
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
          object LblShotDir: TLabel
            Left = 24
            Top = 149
            Width = 51
            Height = 15
            Caption = #51200#51109' '#54260#45908
            Transparent = True
          end
          object LblShotDirDesc: TLabel
            Left = 24
            Top = 167
            Width = 116
            Height = 13
            Caption = #49828#53356#47536#49399#51012' '#51200#51109#54624' '#50948#52824
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            Transparent = True
          end
          object LblShotFmt: TLabel
            Left = 24
            Top = 216
            Width = 24
            Height = 15
            Caption = #54805#49885
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
              #54620' '#44257' '#48152#48373
              #51204#52404' '#48152#48373)
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
              #45124#44592
              #53020#44592)
          end
          object EdtShotDir: TEdit
            Left = 325
            Top = 156
            Width = 250
            Height = 23
            Anchors = [akTop, akRight]
            ReadOnly = True
            TabOrder = 2
          end
          object BtnShotDir: TButton
            Left = 583
            Top = 155
            Width = 60
            Height = 26
            Anchors = [akTop, akRight]
            Caption = #52286#44592
            TabOrder = 3
            OnClick = BtnShotDirClick
          end
          object CboShotFmt: TComboBox
            Left = 473
            Top = 212
            Width = 170
            Height = 23
            Style = csDropDownList
            Anchors = [akTop, akRight]
            TabOrder = 4
            OnChange = ControlChange
            Items.Strings = (
              'JPG'
              'PNG')
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
          object LblHwdecDesc: TLabel
            Left = 24
            Top = 39
            Width = 72
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblVoDesc: TLabel
            Left = 24
            Top = 103
            Width = 179
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857' / gpu-next '#45716' '#49892#54744#51201
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblGpuApiDesc: TLabel
            Left = 24
            Top = 167
            Width = 72
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblVideoSyncDesc: TLabel
            Left = 24
            Top = 231
            Width = 72
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblScaleDesc: TLabel
            Left = 24
            Top = 295
            Width = 72
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblDeintDesc: TLabel
            Left = 24
            Top = 359
            Width = 72
            Height = 13
            Caption = #51116#49884#51089' '#54980' '#51201#50857
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblVolumeDesc: TLabel
            Left = 24
            Top = 39
            Width = 203
            Height = 13
            Caption = #54788#51116' '#48380#47464' / '#45796#51020' '#49892#54665#50640#46020' '#50976#51648' ('#52572#45824' 100)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblNormalizeDesc: TLabel
            Left = 24
            Top = 103
            Width = 205
            Height = 13
            Caption = #44396#44036#48324' '#51020#47049' '#52264#51060#47484' '#51460#51064#45796' (dynaudnorm)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object ChkNormalize: TCheckBox
            Left = 622
            Top = 94
            Width = 21
            Height = 20
            Anchors = [akTop, akRight]
            TabOrder = 1
            OnClick = ControlChange
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
          VertScrollBar.Tracking = True
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          TabOrder = 0
          DesignSize = (
            667
            504)
          object LblSubVisible: TLabel
            Left = 24
            Top = 21
            Width = 78
            Height = 15
            Caption = #51088#47561' '#44592#48376' '#54364#49884
            Transparent = True
          end
          object LblSubVisibleDesc: TLabel
            Left = 24
            Top = 39
            Width = 155
            Height = 13
            Caption = #45124#47732' '#51088#47561' '#48260#53948#51004#47196' '#53020#50556' '#48372#51064#45796
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
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
          object LblSubLangDesc: TLabel
            Left = 24
            Top = 151
            Width = 156
            Height = 13
            Caption = #49788#54364#47196' '#44396#48516' ('#50696': ko,kor,en,eng)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            Transparent = True
          end
          object ChkSubVisible: TCheckBox
            Left = 622
            Top = 30
            Width = 21
            Height = 20
            Anchors = [akTop, akRight]
            TabOrder = 0
            OnClick = ControlChange
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
          Height = 60
          Anchors = [akTop, akRight]
          AutoSize = False
          Caption = 
            #52404#53356#54616#47732' '#44536' '#51593#49884' '#50672#44208#51060' '#48152#50689#46121#45768#45796'. '#45796#47564' '#50952#46020#50864#45716' '#44592#48376' '#50545' '#48320#44221#51012' '#54532#47196#44536#47016#50640' '#54728#50857#54616#51648' '#50506#51004#48064#47196', '#45796#47480' '#54532#47196#44536#47016#51060' ' +
            #51105#44256' '#51080#45716' '#54869#51109#51088'('#54924#49353')'#45716' '#50500#47000' '#48260#53948#51004#47196' '#50952#46020#50864' '#49444#51221#51012' '#50676#50612' '#51649#51217' KPlayer '#47484' '#44264#46972#50556' '#54633#45768#45796'.'
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
          Anchors = [akLeft, akTop, akBottom]
          DefaultNodeHeight = 22
          Header.AutoSizeIndex = 0
          Header.Height = 15
          Header.MainColumn = -1
          Header.Options = []
          Indent = 20
          ParentShowHint = False
          ScrollBarOptions.ScrollBars = ssVertical
          ShowHint = True
          TabOrder = 0
          OnChecked = TreeAssocChecked
          OnFreeNode = TreeAssocFreeNode
          OnGetText = TreeAssocGetText
          OnPaintText = TreeAssocPaintText
          OnGetImageIndex = TreeAssocGetImageIndex
          OnGetHint = TreeAssocGetHint
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
      object CardAbout: TCard
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
