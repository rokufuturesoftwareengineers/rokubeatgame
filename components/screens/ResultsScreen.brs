' Post-game score breakdown screen
' Uses percentage-based layout to work across different display sizes

sub init()
    initScreenDimensions()
    calculateLayout()
    setupReferences()
    setupLayout()
    
    m.selectedButton = 0
    m.buttonActions = ["retry", "songSelect", "mainMenu"]
    
    m.top.observeField("visible", "onVisibleChange")
end sub

sub initScreenDimensions()
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.screenWidth = displaySize.w
    m.screenHeight = displaySize.h
    
    m.scaleFactor = m.screenHeight / 720.0
end sub

sub calculateLayout()
    ' --- Layout values scaled from 720p ---
    
    m.topBarHeight = int(6 * m.scaleFactor)
    
    m.marginH = int(m.screenWidth * 0.04)
    m.marginV = int(m.screenHeight * 0.04)
    m.paddingSmall = int(10 * m.scaleFactor)
    m.paddingMed = int(15 * m.scaleFactor)
    m.paddingLarge = int(20 * m.scaleFactor)
    
    m.headerY = int(m.screenHeight * 0.04)
    
    m.songInfoX = m.marginH
    m.songInfoY = int(m.screenHeight * 0.12)
    m.artistOffsetY = int(40 * m.scaleFactor)
    
    m.gradeSize = int(120 * m.scaleFactor)
    m.gradeX = int(m.screenWidth * 0.75) - (m.gradeSize / 2)
    m.gradeY = int(m.screenHeight * 0.10)
    
    ' Two equal-width panels with a gap, centered
    m.panelWidth = int(m.screenWidth * 0.42)
    m.panelGap = int(m.screenWidth * 0.04)
    totalPanelsWidth = (m.panelWidth * 2) + m.panelGap
    m.panelMargin = int((m.screenWidth - totalPanelsWidth) / 2)
    
    m.scorePanelX = m.panelMargin
    m.scorePanelY = int(m.screenHeight * 0.28)
    m.scorePanelWidth = m.panelWidth
    m.scorePanelHeight = int(180 * m.scaleFactor)
    
    m.subPanelWidth = int((m.scorePanelWidth - m.paddingMed) / 2)
    m.subPanelHeight = int(70 * m.scaleFactor)
    m.subPanelY = int(m.screenHeight * 0.45)
    
    m.breakdownX = m.panelMargin + m.panelWidth + m.panelGap
    m.breakdownY = int(m.screenHeight * 0.28)
    m.breakdownWidth = m.panelWidth
    m.breakdownHeight = int(200 * m.scaleFactor)
    
    m.hitRowHeight = int(36 * m.scaleFactor)
    m.hitRowWidth = m.breakdownWidth - (m.paddingMed * 2)
    
    m.highScoreY = int(m.screenHeight * 0.68)
    
    m.buttonWidth = int(180 * m.scaleFactor)
    m.buttonHeight = int(50 * m.scaleFactor)
    m.buttonSpacing = int(20 * m.scaleFactor)
    m.buttonsY = int(m.screenHeight * 0.75)
    
    totalButtonsWidth = (m.buttonWidth * 3) + (m.buttonSpacing * 2)
    m.buttonsStartX = int((m.screenWidth - totalButtonsWidth) / 2)
    
    m.instructionsY = int(m.screenHeight * 0.88)
    
    m.statsY = int(m.screenHeight * 0.94)
end sub

sub setupReferences()
    m.background = m.top.findNode("background")
    m.topBar = m.top.findNode("topBar")
    
    m.headerLabel = m.top.findNode("headerLabel")
    
    m.songInfoGroup = m.top.findNode("songInfoGroup")
    m.songTitle = m.top.findNode("songTitle")
    m.songArtist = m.top.findNode("songArtist")
    
    m.gradeGroup = m.top.findNode("gradeGroup")
    m.gradeBg = m.top.findNode("gradeBg")
    m.gradeLabel = m.top.findNode("gradeLabel")
    
    m.scorePanel = m.top.findNode("scorePanel")
    m.scoreBg = m.top.findNode("scoreBg")
    m.scoreHeader = m.top.findNode("scoreHeader")
    m.scoreValue = m.top.findNode("scoreValue")
    
    m.accuracyPanel = m.top.findNode("accuracyPanel")
    m.accuracyBg = m.top.findNode("accuracyBg")
    m.accuracyHeader = m.top.findNode("accuracyHeader")
    m.accuracyValue = m.top.findNode("accuracyValue")
    
    m.comboPanel = m.top.findNode("comboPanel")
    m.comboBg = m.top.findNode("comboBg")
    m.comboHeader = m.top.findNode("comboHeader")
    m.maxComboValue = m.top.findNode("maxComboValue")
    
    m.breakdownPanel = m.top.findNode("breakdownPanel")
    m.breakdownBg = m.top.findNode("breakdownBg")
    m.breakdownHeader = m.top.findNode("breakdownHeader")
    
    m.perfectRow = m.top.findNode("perfectRow")
    m.perfectBg = m.top.findNode("perfectBg")
    m.perfectLabel = m.top.findNode("perfectLabel")
    m.perfectValue = m.top.findNode("perfectValue")
    
    m.goodRow = m.top.findNode("goodRow")
    m.goodBg = m.top.findNode("goodBg")
    m.goodLabel = m.top.findNode("goodLabel")
    m.goodValue = m.top.findNode("goodValue")
    
    m.missRow = m.top.findNode("missRow")
    m.missBg = m.top.findNode("missBg")
    m.missLabel = m.top.findNode("missLabel")
    m.missValue = m.top.findNode("missValue")
    
    m.newHighScoreLabel = m.top.findNode("newHighScoreLabel")
    
    m.buttonsGroup = m.top.findNode("buttonsGroup")
    m.retryButton = m.top.findNode("retryButton")
    m.retryBg = m.top.findNode("retryBg")
    m.retryLabel = m.top.findNode("retryLabel")
    
    m.songSelectButton = m.top.findNode("songSelectButton")
    m.songSelectBg = m.top.findNode("songSelectBg")
    m.songSelectLabel = m.top.findNode("songSelectLabel")
    
    m.mainMenuButton = m.top.findNode("mainMenuButton")
    m.mainMenuBg = m.top.findNode("mainMenuBg")
    m.mainMenuLabel = m.top.findNode("mainMenuLabel")
    
    m.buttons = [m.retryButton, m.songSelectButton, m.mainMenuButton]
    m.buttonBgs = [m.retryBg, m.songSelectBg, m.mainMenuBg]
    m.buttonLabels = [m.retryLabel, m.songSelectLabel, m.mainMenuLabel]
    
    m.instructions = m.top.findNode("instructions")
    m.statsLabel = m.top.findNode("statsLabel")
end sub

sub setupLayout()
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight
    
    m.topBar.width = m.screenWidth
    m.topBar.height = m.topBarHeight
    m.topBar.translation = [0, 0]
    
    m.headerLabel.width = m.screenWidth
    m.headerLabel.translation = [0, m.headerY]
    m.headerLabel.horizAlign = "center"
    
    m.songInfoGroup.translation = [m.songInfoX, m.songInfoY]
    m.songTitle.translation = [0, 0]
    m.songArtist.translation = [0, m.artistOffsetY]
    
    setupGradeDisplay()
    setupScorePanel()
    setupBreakdownPanel()
    
    m.newHighScoreLabel.translation = [m.screenWidth / 2, m.highScoreY]
    m.newHighScoreLabel.width = m.screenWidth
    
    setupButtons()
    
    m.instructions.width = m.screenWidth
    m.instructions.translation = [0, m.instructionsY]
    m.instructions.horizAlign = "center"
    
    m.statsLabel.width = m.screenWidth
    m.statsLabel.translation = [0, m.statsY]
    m.statsLabel.horizAlign = "center"
end sub

sub setupGradeDisplay()
    m.gradeGroup.translation = [m.gradeX, m.gradeY]
    
    m.gradeBg.width = m.gradeSize
    m.gradeBg.height = m.gradeSize
    m.gradeBg.translation = [0, 0]
    
    m.gradeLabel.width = m.gradeSize
    m.gradeLabel.height = m.gradeSize
    m.gradeLabel.translation = [0, 0]
end sub

sub setupScorePanel()
    m.scorePanel.translation = [m.scorePanelX, m.scorePanelY]
    
    m.scoreBg.width = m.scorePanelWidth
    m.scoreBg.height = int(100 * m.scaleFactor)
    m.scoreBg.translation = [0, 0]
    
    m.scoreHeader.translation = [m.paddingMed, m.paddingSmall]
    
    m.scoreValue.translation = [m.paddingMed, int(35 * m.scaleFactor)]
    
    m.accuracyPanel.translation = [0, int(110 * m.scaleFactor)]
    m.accuracyBg.width = m.subPanelWidth
    m.accuracyBg.height = m.subPanelHeight
    m.accuracyBg.translation = [0, 0]
    m.accuracyHeader.translation = [m.paddingSmall, m.paddingSmall]
    m.accuracyValue.translation = [m.paddingSmall, int(30 * m.scaleFactor)]
    
    m.comboPanel.translation = [m.subPanelWidth + m.paddingMed, int(110 * m.scaleFactor)]
    m.comboBg.width = m.subPanelWidth
    m.comboBg.height = m.subPanelHeight
    m.comboBg.translation = [0, 0]
    m.comboHeader.translation = [m.paddingSmall, m.paddingSmall]
    m.maxComboValue.translation = [m.paddingSmall, int(30 * m.scaleFactor)]
end sub

sub setupBreakdownPanel()
    m.breakdownPanel.translation = [m.breakdownX, m.breakdownY]
    
    m.breakdownBg.width = m.breakdownWidth
    m.breakdownBg.height = m.breakdownHeight
    m.breakdownBg.translation = [0, 0]
    
    m.breakdownHeader.translation = [m.paddingMed, m.paddingSmall]
    
    rowStartY = int(45 * m.scaleFactor)
    rowSpacing = m.hitRowHeight + int(8 * m.scaleFactor)
    
    setupHitRow(m.perfectRow, m.perfectBg, m.perfectLabel, m.perfectValue, rowStartY)
    setupHitRow(m.goodRow, m.goodBg, m.goodLabel, m.goodValue, rowStartY + rowSpacing)
    setupHitRow(m.missRow, m.missBg, m.missLabel, m.missValue, rowStartY + (rowSpacing * 2))
end sub

sub setupHitRow(rowGroup as object, bg as object, labelLeft as object, labelRight as object, yPos as integer)
    rowGroup.translation = [m.paddingMed, yPos]
    
    bg.width = m.hitRowWidth
    bg.height = m.hitRowHeight
    bg.translation = [0, 0]
    
    labelLeft.translation = [m.paddingSmall, int((m.hitRowHeight - 20 * m.scaleFactor) / 2)]
    
    labelRight.width = m.hitRowWidth - (m.paddingSmall * 2)
    labelRight.translation = [m.paddingSmall, int((m.hitRowHeight - 20 * m.scaleFactor) / 2)]
end sub

sub setupButtons()
    m.buttonsGroup.translation = [m.buttonsStartX, m.buttonsY]
    
    for i = 0 to 2
        buttonX = i * (m.buttonWidth + m.buttonSpacing)
        m.buttons[i].translation = [buttonX, 0]
        
        m.buttonBgs[i].width = m.buttonWidth
        m.buttonBgs[i].height = m.buttonHeight
        m.buttonBgs[i].translation = [0, 0]
        
        m.buttonLabels[i].width = m.buttonWidth
        m.buttonLabels[i].height = m.buttonHeight
        m.buttonLabels[i].translation = [0, 0]
    end for
    
    updateButtonSelection()
end sub

sub updateButtonSelection()
    selectedColor = "0x6c5ce7FF"
    unselectedColor = "0x2d3436FF"
    selectedTextColor = "0xFFFFFFFF"
    unselectedTextColor = "0xb2bec3FF"
    
    for i = 0 to 2
        if i = m.selectedButton then
            m.buttonBgs[i].color = selectedColor
            m.buttonLabels[i].color = selectedTextColor
        else
            m.buttonBgs[i].color = unselectedColor
            m.buttonLabels[i].color = unselectedTextColor
        end if
    end for
end sub

sub onVisibleChange()
    if m.top.visible then
        m.selectedButton = 0
        updateButtonSelection()
    end if
end sub

sub onResultSet()
    result = m.top.result
    if result = invalid then return
    
    songInfo = m.top.songInfo
    if songInfo <> invalid then
        m.songTitle.text = songInfo.title
        m.songArtist.text = songInfo.artist
    end if
    
    m.scoreValue.text = formatNumber(result.score)
    
    if result.accuracy <> invalid then
        m.accuracyValue.text = formatAccuracy(result.accuracy) + "%"
    end if
    
    if result.maxCombo <> invalid then
        m.maxComboValue.text = result.maxCombo.ToStr() + "x"
    end if
    
    if result.hits <> invalid then
        m.perfectValue.text = getHitCount(result.hits, "perfect").ToStr()
        m.goodValue.text = getHitCount(result.hits, "good").ToStr()
        m.missValue.text = getHitCount(result.hits, "miss").ToStr()
    end if
    
    updateGrade(result)
    
    if result.isNewHighScore = true then
        m.newHighScoreLabel.visible = true
    else
        m.newHighScoreLabel.visible = false
    end if
    
    totalNotes = 0
    if result.hits <> invalid then
        totalNotes = getHitCount(result.hits, "perfect") + getHitCount(result.hits, "good") + getHitCount(result.hits, "miss")
    end if
    m.statsLabel.text = "Total Notes: " + totalNotes.ToStr()
end sub

sub updateGrade(result as object)
    accuracy = 0
    if result.accuracy <> invalid then
        accuracy = result.accuracy
    end if
    
    grade = "D"
    gradeColor = "0xd63031FF"
    
    if accuracy >= 95 then
        grade = "S"
        gradeColor = "0xffeaa7FF"
    else if accuracy >= 90 then
        grade = "A"
        gradeColor = "0x00cec9FF"
    else if accuracy >= 80 then
        grade = "B"
        gradeColor = "0x74b9ffFF"
    else if accuracy >= 70 then
        grade = "C"
        gradeColor = "0xfdcb6eFF"
    end if
    
    m.gradeLabel.text = grade
    m.gradeLabel.color = gradeColor
end sub

function getHitCount(hits as object, hitType as string) as integer
    if hits[hitType] <> invalid then
        return hits[hitType]
    end if
    return 0
end function

function formatNumber(num as dynamic) as string
    if num = invalid then return "0"
    
    numStr = num.ToStr()
    result = ""
    count = 0
    
    for i = numStr.Len() - 1 to 0 step -1
        if count > 0 and count mod 3 = 0 then
            result = "," + result
        end if
        result = numStr.Mid(i, 1) + result
        count = count + 1
    end for
    
    return result
end function

function formatAccuracy(accuracy as dynamic) as string
    if accuracy = invalid then return "0.00"
    return Str(accuracy).Trim()
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    
    if key = "left" then
        m.selectedButton = m.selectedButton - 1
        if m.selectedButton < 0 then m.selectedButton = 2
        updateButtonSelection()
        return true
    else if key = "right" then
        m.selectedButton = m.selectedButton + 1
        if m.selectedButton > 2 then m.selectedButton = 0
        updateButtonSelection()
        return true
    else if key = "OK" then
        m.top.action = m.buttonActions[m.selectedButton]
        return true
    else if key = "back" then
        m.top.action = "songSelect"
        return true
    end if
    
    return false
end function
