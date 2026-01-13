' StartMenu.brs - Main menu screen (dynamically scaled and centered)
' All positions use percentages of screen dimensions for device-agnostic layout

sub init()
    print "[StartMenu] Initializing..."

    ' Initialize screen dimensions
    initScreenDimensions()
    
    ' Calculate layout values
    calculateLayout()
    
    ' Get UI references
    setupReferences()
    
    ' Apply dynamic layout
    setupLayout()

    ' Menu state
    m.selectedIndex = 0
    m.menuItems = ["play", "help"]
    m.buttons = [m.playBtn, m.helpBtn]
    m.buttonBgs = [m.playBtnBg, m.helpBtnBg]
    m.buttonLabels = [m.playBtnLabel, m.helpBtnLabel]

    ' Start animations
    startAnimations()

    ' Update visual state
    updateSelection()

    ' Set focus
    m.top.setFocus(true)
    
    print "[StartMenu] Initialization complete"
end sub

sub initScreenDimensions()
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.screenWidth = displaySize.w
    m.screenHeight = displaySize.h
    
    ' Scale factor based on 720p reference
    m.scaleFactor = m.screenHeight / 720.0
end sub

sub calculateLayout()
    ' =========================================
    ' LAYOUT PERCENTAGES (based on 720p reference)
    ' =========================================
    
    ' Center X for all centered elements
    m.centerX = m.screenWidth / 2
    
    ' Title section - positioned at ~12% from top
    m.titleY = int(m.screenHeight * 0.10)
    m.titlePaddingH = int(50 * m.scaleFactor)
    m.titlePaddingV = int(25 * m.scaleFactor)
    m.titleSubOffsetY = int(45 * m.scaleFactor)  ' Subtitle below main title
    
    ' Decorative line - below title (lowered to avoid obstructing subtitle)
    m.lineY = int(m.screenHeight * 0.25)
    m.lineWidth = int(200 * m.scaleFactor)
    m.lineHeight = int(3 * m.scaleFactor)
    
    ' Menu buttons - centered vertically around 38%
    m.buttonsY = int(m.screenHeight * 0.30)
    m.buttonWidth = int(320 * m.scaleFactor)
    m.buttonHeight = int(70 * m.scaleFactor)
    m.buttonSpacing = int(20 * m.scaleFactor)
    
    ' Key hints section - at ~60%
    m.keyHintsY = int(m.screenHeight * 0.58)
    m.keyHintsPaddingH = int(40 * m.scaleFactor)
    m.keyHintsPaddingV = int(15 * m.scaleFactor)
    m.keyHintsLineSpacing = int(22 * m.scaleFactor)
    
    ' Footer - at ~85%
    m.footerY = int(m.screenHeight * 0.85)
    
    ' Animated notes positions
    m.noteLBaseX = int(m.screenWidth * 0.08)
    m.noteRBaseX = int(m.screenWidth * 0.88)
    m.noteBaseY = int(m.screenHeight * 0.30)
    m.animAmplitude = int(m.screenHeight * 0.03)
end sub

sub setupReferences()
    ' Background
    m.background = m.top.findNode("background")
    
    ' Title section
    m.titleGroup = m.top.findNode("titleGroup")
    m.titleGlow = m.top.findNode("titleGlow")
    m.titleMain = m.top.findNode("titleMain")
    m.titleSub = m.top.findNode("titleSub")
    
    ' Decorative line
    m.titleLine = m.top.findNode("titleLine")
    
    ' Menu buttons
    m.menuButtonsGroup = m.top.findNode("menuButtonsGroup")
    m.playBtn = m.top.findNode("playBtn")
    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnLabel = m.top.findNode("playBtnLabel")
    m.helpBtn = m.top.findNode("helpBtn")
    m.helpBtnBg = m.top.findNode("helpBtnBg")
    m.helpBtnLabel = m.top.findNode("helpBtnLabel")
    
    ' Key hints
    m.keyHintsGroup = m.top.findNode("keyHintsGroup")
    m.keyHintsBg = m.top.findNode("keyHintsBg")
    m.controlsLabel = m.top.findNode("controlsLabel")
    m.lanesLabel = m.top.findNode("lanesLabel")
    m.instructionLabel = m.top.findNode("instructionLabel")
    
    ' Footer
    m.versionLabel = m.top.findNode("versionLabel")
    
    ' Animated notes
    m.noteL = m.top.findNode("noteL")
    m.noteR = m.top.findNode("noteR")
end sub

sub setupLayout()
    ' Background - full screen
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight
    
    ' Setup title section
    setupTitleSection()
    
    ' Setup decorative line
    setupTitleLine()
    
    ' Setup menu buttons
    setupMenuButtons()
    
    ' Setup key hints
    setupKeyHints()
    
    ' Setup footer
    m.versionLabel.width = m.screenWidth
    m.versionLabel.translation = [0, m.footerY]
end sub

sub setupTitleSection()
    ' Estimate title dimensions (will be refined after render)
    titleWidth = int(280 * m.scaleFactor)   ' Approximate width of "OSU MANIA"
    titleHeight = int(40 * m.scaleFactor)   ' Title height
    subHeight = int(25 * m.scaleFactor)     ' Subtitle height
    totalHeight = titleHeight + m.titleSubOffsetY - titleHeight + subHeight
    
    ' Calculate glow box dimensions
    glowWidth = titleWidth + (m.titlePaddingH * 2)
    glowHeight = m.titleSubOffsetY + subHeight + (m.titlePaddingV * 2)
    
    ' Position the entire title group centered
    groupX = m.centerX - (glowWidth / 2)
    m.titleGroup.translation = [groupX, m.titleY]
    
    ' Glow background at origin of group
    m.titleGlow.width = glowWidth
    m.titleGlow.height = glowHeight
    m.titleGlow.translation = [0, 0]
    
    ' Title main - centered within glow box
    m.titleMain.width = glowWidth
    m.titleMain.translation = [0, m.titlePaddingV]
    
    ' Title sub - below main title, centered
    m.titleSub.width = glowWidth
    m.titleSub.translation = [0, m.titlePaddingV + m.titleSubOffsetY]
end sub

sub setupTitleLine()
    ' Center the decorative line
    lineX = m.centerX - (m.lineWidth / 2)
    m.titleLine.width = m.lineWidth
    m.titleLine.height = m.lineHeight
    m.titleLine.translation = [lineX, m.lineY]
end sub

sub setupMenuButtons()
    ' Center the buttons group
    groupX = m.centerX - (m.buttonWidth / 2)
    m.menuButtonsGroup.translation = [groupX, m.buttonsY]
    
    ' Play button at top of group
    m.playBtn.translation = [0, 0]
    m.playBtnBg.width = m.buttonWidth
    m.playBtnBg.height = m.buttonHeight
    m.playBtnBg.translation = [0, 0]
    m.playBtnLabel.width = m.buttonWidth
    m.playBtnLabel.height = m.buttonHeight
    m.playBtnLabel.translation = [0, 0]
    
    ' Help button below play button
    helpY = m.buttonHeight + m.buttonSpacing
    m.helpBtn.translation = [0, helpY]
    m.helpBtnBg.width = m.buttonWidth
    m.helpBtnBg.height = m.buttonHeight
    m.helpBtnBg.translation = [0, 0]
    m.helpBtnLabel.width = m.buttonWidth
    m.helpBtnLabel.height = m.buttonHeight
    m.helpBtnLabel.translation = [0, 0]
end sub

sub setupKeyHints()
    ' Estimate content dimensions
    contentWidth = int(480 * m.scaleFactor)  ' Width of longest line
    contentHeight = m.keyHintsLineSpacing * 3  ' 3 lines of text
    
    ' Calculate background dimensions
    bgWidth = contentWidth + (m.keyHintsPaddingH * 2)
    bgHeight = contentHeight + (m.keyHintsPaddingV * 2)
    
    ' Position the entire key hints group centered
    groupX = m.centerX - (bgWidth / 2)
    m.keyHintsGroup.translation = [groupX, m.keyHintsY]
    
    ' Background at origin of group
    m.keyHintsBg.width = bgWidth
    m.keyHintsBg.height = bgHeight
    m.keyHintsBg.translation = [0, 0]
    
    ' Controls label - centered within background
    m.controlsLabel.width = bgWidth
    m.controlsLabel.translation = [0, m.keyHintsPaddingV]
    
    ' Lanes label - second line
    m.lanesLabel.width = bgWidth
    m.lanesLabel.translation = [0, m.keyHintsPaddingV + m.keyHintsLineSpacing]
    
    ' Instruction label - third line
    m.instructionLabel.width = bgWidth
    m.instructionLabel.translation = [0, m.keyHintsPaddingV + (m.keyHintsLineSpacing * 2)]
end sub

' Start decorative animations
sub startAnimations()
    m.animTimer = m.top.createChild("Timer")
    m.animTimer.repeat = true
    m.animTimer.duration = 0.05
    m.animTimer.observeField("fire", "onAnimTick")
    m.animTimer.control = "start"
    
    m.animPhase = 0.0
end sub

' Animation tick
sub onAnimTick()
    m.animPhase = m.animPhase + 0.08
    
    ' Floating notes animation
    if m.noteL <> invalid
        yOffset = sineWave(m.animPhase) * m.animAmplitude
        m.noteL.translation = [m.noteLBaseX, m.noteBaseY + yOffset]
    end if
    
    if m.noteR <> invalid
        yOffset = sineWave(m.animPhase + 2.0) * m.animAmplitude
        m.noteR.translation = [m.noteRBaseX, m.noteBaseY + yOffset]
    end if
end sub

' Sine wave approximation
function sineWave(x as Float) as Float
    while x > 3.14159
        x = x - 6.28318
    end while
    while x < -3.14159
        x = x + 6.28318
    end while
    
    x2 = x * x
    return x - (x * x2) / 6.0 + (x * x2 * x2) / 120.0
end function

' Update button visuals based on selection
sub updateSelection()
    ' Colors
    selectedBgColor = "0x6c5ce7FF"
    unselectedBgColor = "0x2d3436FF"
    selectedTextColor = "0xFFFFFFFF"
    unselectedTextColor = "0xb2bec3FF"
    
    for i = 0 to m.buttons.count() - 1
        if i = m.selectedIndex
            m.buttonBgs[i].color = selectedBgColor
            m.buttonLabels[i].color = selectedTextColor
        else
            m.buttonBgs[i].color = unselectedBgColor
            m.buttonLabels[i].color = unselectedTextColor
        end if
    end for
end sub

' Handle key events
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    
    handled = false
    
    if key = "up"
        m.selectedIndex = m.selectedIndex - 1
        if m.selectedIndex < 0 then m.selectedIndex = m.menuItems.count() - 1
        updateSelection()
        handled = true
        
    else if key = "down"
        m.selectedIndex = m.selectedIndex + 1
        if m.selectedIndex >= m.menuItems.count() then m.selectedIndex = 0
        updateSelection()
        handled = true
        
    else if key = "OK"
        m.top.menuAction = m.menuItems[m.selectedIndex]
        handled = true
        
    else if key = "back"
        ' Could handle exit confirmation here
        handled = false
    end if
    
    return handled
end function
