' Main menu - play or learn how the game works
' All layout values calculated dynamically for any screen size

sub init()
    print "[StartMenu] Initializing..."

    initScreenDimensions()
    calculateLayout()
    setupReferences()
    setupLayout()

    m.selectedIndex = 0
    m.menuItems = ["play", "help"]
    m.buttons = [m.playBtn, m.helpBtn]
    m.buttonBgs = [m.playBtnBg, m.helpBtnBg]
    m.buttonLabels = [m.playBtnLabel, m.helpBtnLabel]

    startAnimations()
    updateSelection()

    m.top.setFocus(true)
    
    print "[StartMenu] Initialization complete"
end sub

sub initScreenDimensions()
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.screenWidth = displaySize.w
    m.screenHeight = displaySize.h
    
    m.scaleFactor = m.screenHeight / 720.0
end sub

sub calculateLayout()
    ' --- Layout percentages (720p reference) ---
    
    m.centerX = m.screenWidth / 2
    
    m.titleY = int(m.screenHeight * 0.10)
    m.titlePaddingH = int(50 * m.scaleFactor)
    m.titlePaddingV = int(25 * m.scaleFactor)
    
    m.lineY = int(m.screenHeight * 0.22)
    m.lineWidth = int(200 * m.scaleFactor)
    m.lineHeight = int(3 * m.scaleFactor)
    
    m.buttonsY = int(m.screenHeight * 0.30)
    m.buttonWidth = int(320 * m.scaleFactor)
    m.buttonHeight = int(70 * m.scaleFactor)
    m.buttonSpacing = int(20 * m.scaleFactor)
    
    m.keyHintsY = int(m.screenHeight * 0.58)
    m.keyHintsPaddingH = int(40 * m.scaleFactor)
    m.keyHintsPaddingV = int(15 * m.scaleFactor)
    m.keyHintsLineSpacing = int(22 * m.scaleFactor)
    
    m.footerY = int(m.screenHeight * 0.85)
    
    ' Decorative floating notes
    m.noteLBaseX = int(m.screenWidth * 0.08)
    m.noteRBaseX = int(m.screenWidth * 0.88)
    m.noteBaseY = int(m.screenHeight * 0.30)
    m.animAmplitude = int(m.screenHeight * 0.03)
end sub

sub setupReferences()
    m.background = m.top.findNode("background")
    
    m.titleGroup = m.top.findNode("titleGroup")
    m.titleGlow = m.top.findNode("titleGlow")
    m.titleMain = m.top.findNode("titleMain")
    
    m.titleLine = m.top.findNode("titleLine")
    
    m.menuButtonsGroup = m.top.findNode("menuButtonsGroup")
    m.playBtn = m.top.findNode("playBtn")
    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnLabel = m.top.findNode("playBtnLabel")
    m.helpBtn = m.top.findNode("helpBtn")
    m.helpBtnBg = m.top.findNode("helpBtnBg")
    m.helpBtnLabel = m.top.findNode("helpBtnLabel")
    
    m.keyHintsGroup = m.top.findNode("keyHintsGroup")
    m.keyHintsBg = m.top.findNode("keyHintsBg")
    m.controlsLabel = m.top.findNode("controlsLabel")
    m.lanesLabel = m.top.findNode("lanesLabel")
    m.instructionLabel = m.top.findNode("instructionLabel")
    
    m.versionLabel = m.top.findNode("versionLabel")
    
    m.noteL = m.top.findNode("noteL")
    m.noteR = m.top.findNode("noteR")
end sub

sub setupLayout()
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight
    
    setupTitleSection()
    
    setupTitleLine()
    
    setupMenuButtons()
    
    setupKeyHints()
    
    m.versionLabel.width = m.screenWidth
    m.versionLabel.translation = [0, m.footerY]
end sub

sub setupTitleSection()
    ' Rough estimates, gets refined on render
    titleWidth = int(280 * m.scaleFactor)
    titleHeight = int(40 * m.scaleFactor)
    
    glowWidth = titleWidth + (m.titlePaddingH * 2)
    glowHeight = titleHeight + (m.titlePaddingV * 2)
    
    groupX = m.centerX - (glowWidth / 2)
    m.titleGroup.translation = [groupX, m.titleY]
    
    ' Glow background at origin of group
    m.titleGlow.width = glowWidth
    m.titleGlow.height = glowHeight
    m.titleGlow.translation = [0, 0]
    
    m.titleMain.width = glowWidth
    m.titleMain.height = glowHeight
    m.titleMain.translation = [0, 0]
end sub

sub setupTitleLine()
    lineX = m.centerX - (m.lineWidth / 2)
    m.titleLine.width = m.lineWidth
    m.titleLine.height = m.lineHeight
    m.titleLine.translation = [lineX, m.lineY]
end sub

sub setupMenuButtons()
    groupX = m.centerX - (m.buttonWidth / 2)
    m.menuButtonsGroup.translation = [groupX, m.buttonsY]
    
    m.playBtn.translation = [0, 0]
    m.playBtnBg.width = m.buttonWidth
    m.playBtnBg.height = m.buttonHeight
    m.playBtnBg.translation = [0, 0]
    m.playBtnLabel.width = m.buttonWidth
    m.playBtnLabel.height = m.buttonHeight
    m.playBtnLabel.translation = [0, 0]
    
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
    contentWidth = int(480 * m.scaleFactor)
    contentHeight = m.keyHintsLineSpacing * 3
    
    bgWidth = contentWidth + (m.keyHintsPaddingH * 2)
    bgHeight = contentHeight + (m.keyHintsPaddingV * 2)
    
    groupX = m.centerX - (bgWidth / 2)
    m.keyHintsGroup.translation = [groupX, m.keyHintsY]
    
    ' Background at origin of group
    m.keyHintsBg.width = bgWidth
    m.keyHintsBg.height = bgHeight
    m.keyHintsBg.translation = [0, 0]
    
    m.controlsLabel.width = bgWidth
    m.controlsLabel.translation = [0, m.keyHintsPaddingV]
    
    m.lanesLabel.width = bgWidth
    m.lanesLabel.translation = [0, m.keyHintsPaddingV + m.keyHintsLineSpacing]
    
    m.instructionLabel.width = bgWidth
    m.instructionLabel.translation = [0, m.keyHintsPaddingV + (m.keyHintsLineSpacing * 2)]
end sub

' Decorative animations
sub startAnimations()
    m.animTimer = m.top.createChild("Timer")
    m.animTimer.repeat = true
    m.animTimer.duration = 0.05
    m.animTimer.observeField("fire", "onAnimTick")
    m.animTimer.control = "start"
    
    m.animPhase = 0.0
end sub

sub onAnimTick()
    m.animPhase = m.animPhase + 0.08
    
    ' Floating notes bob up and down
    if m.noteL <> invalid
        yOffset = sineWave(m.animPhase) * m.animAmplitude
        m.noteL.translation = [m.noteLBaseX, m.noteBaseY + yOffset]
    end if
    
    if m.noteR <> invalid
        yOffset = sineWave(m.animPhase + 2.0) * m.animAmplitude
        m.noteR.translation = [m.noteRBaseX, m.noteBaseY + yOffset]
    end if
end sub

' Taylor series sine approximation because sin() function does not exist in BrightScript
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

sub updateSelection()
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
        ' TODO: exit confirmation
        handled = false
    end if
    
    return handled
end function
