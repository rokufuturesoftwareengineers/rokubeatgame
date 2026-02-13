' Song library browser - pick a track to play
' Layout scales based on screen resolution

sub init()
    print "[SongSelect] Initializing..."
    
    initScreenDimensions()
    calculateLayout()
    setupReferences()
    setupLayout()
    
    m.songs = []
    m.songItems = []
    m.songItemBgs = []
    m.songItemTitles = []
    m.selectedIndex = 0
    m.scrollOffset = 0
    
    ' Styling
    m.selectedBgColor = "0x6c5ce7FF"
    m.unselectedBgColor = "0x2d3436AA"
    m.selectedTextColor = "0xFFFFFFFF"
    m.unselectedTextColor = "0xb2bec3FF"
    
    ' Observe catalog changes from within BrightScript (more reliable than XML onChange)
    m.top.observeField("songCatalog", "onCatalogLoaded")
    
    m.top.setFocus(true)
    
    ' Check if catalog was already set before observer was registered
    if m.top.songCatalog <> invalid
        print "[SongSelect] Catalog already set, loading songs..."
        loadSongsFromCatalog()
    end if
    
    print "[SongSelect] Initialization complete"
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
    
    m.marginH = int(m.screenWidth * 0.02)
    m.marginV = int(m.screenHeight * 0.02)       ' ~2% vertical margin
    m.paddingSmall = int(10 * m.scaleFactor)
    m.paddingMed = int(15 * m.scaleFactor)
    m.panelGap = int(20 * m.scaleFactor)
    
    m.headerHeight = int(53 * m.scaleFactor)
    m.headerTitleY = int(17 * m.scaleFactor)
    
    m.contentY = m.headerHeight + m.paddingMed
    m.contentHeight = m.screenHeight - m.contentY - int(80 * m.scaleFactor)
    
    ' Song list panel - ~55% of screen width
    m.listPanelX = m.marginH
    m.listPanelY = m.contentY
    m.listPanelWidth = int(m.screenWidth * 0.55)
    m.listPanelHeight = m.contentHeight
    
    m.itemHeight = int(47 * m.scaleFactor)
    m.itemWidth = m.listPanelWidth - (m.paddingSmall * 2)
    m.visibleItems = int(m.listPanelHeight / m.itemHeight) - 1
    
    ' Details panel - ~35% of screen width
    m.detailsPanelX = m.listPanelX + m.listPanelWidth + m.panelGap
    m.detailsPanelY = m.contentY
    m.detailsPanelWidth = int(m.screenWidth * 0.35)
    m.detailsPanelHeight = m.contentHeight
    
    m.detailsPadding = int(20 * m.scaleFactor)
    m.artworkWidth = m.detailsPanelWidth - (m.detailsPadding * 2)
    m.artworkHeight = int(120 * m.scaleFactor)
    
    m.rowHeight = int(24 * m.scaleFactor)
    m.rowSpacing = int(8 * m.scaleFactor)
    
    m.playBtnWidth = m.detailsPanelWidth - (m.detailsPadding * 2)
    m.playBtnHeight = int(40 * m.scaleFactor)
    
    m.instructionsY = m.screenHeight - int(30 * m.scaleFactor)
    m.instructionsX = m.detailsPanelX + (m.detailsPanelWidth / 2)
    
    m.noSongsY = int(m.screenHeight * 0.4)
end sub

sub setupReferences()
    m.background = m.top.findNode("background")
    
    m.headerGroup = m.top.findNode("headerGroup")
    m.headerBg = m.top.findNode("headerBg")
    m.headerTitle = m.top.findNode("headerTitle")
    
    m.listPanel = m.top.findNode("listPanel")
    m.listPanelBg = m.top.findNode("listPanelBg")
    m.songListContainer = m.top.findNode("songListContainer")
    m.scrollUpIndicator = m.top.findNode("scrollUpIndicator")
    m.scrollDownIndicator = m.top.findNode("scrollDownIndicator")
    
    m.detailsPanel = m.top.findNode("detailsPanel")
    m.detailsPanelBg = m.top.findNode("detailsPanelBg")
    m.artworkGroup = m.top.findNode("artworkGroup")
    m.artworkBg = m.top.findNode("artworkBg")
    m.artworkPlaceholder = m.top.findNode("artworkPlaceholder")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailArtist = m.top.findNode("detailArtist")
    
    m.difficultyRow = m.top.findNode("difficultyRow")
    m.difficultyLabel = m.top.findNode("difficultyLabel")
    m.difficultyValue = m.top.findNode("difficultyValue")
    
    m.durationRow = m.top.findNode("durationRow")
    m.durationLabel = m.top.findNode("durationLabel")
    m.durationValue = m.top.findNode("durationValue")
    
    m.bestScoreRow = m.top.findNode("bestScoreRow")
    m.bestScoreLabel = m.top.findNode("bestScoreLabel")
    m.bestScoreValue = m.top.findNode("bestScoreValue")
    
    m.playButton = m.top.findNode("playButton")
    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnLabel = m.top.findNode("playBtnLabel")
    
    m.instructions = m.top.findNode("instructions")
    m.noSongsLabel = m.top.findNode("noSongsLabel")
    
    ' QR code section references
    m.qrSection = m.top.findNode("qrSection")
    m.qrLabel = m.top.findNode("qrLabel")
    m.qrImage = m.top.findNode("qrImage")
end sub

sub setupLayout()
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight
    
    setupHeader()
    setupListPanel()
    setupDetailsPanel()
    
    m.instructions.translation = [m.detailsPanelX, m.instructionsY]
    m.instructions.width = m.detailsPanelWidth
    m.instructions.horizAlign = "center"
    
    m.noSongsLabel.translation = [m.screenWidth / 2, m.noSongsY]
    m.noSongsLabel.width = m.screenWidth
end sub

sub setupHeader()
    m.headerGroup.translation = [0, 0]
    
    m.headerBg.width = m.screenWidth
    m.headerBg.height = m.headerHeight
    m.headerBg.translation = [0, 0]
    
    m.headerTitle.width = m.screenWidth
    m.headerTitle.translation = [0, m.headerTitleY]
end sub

sub setupListPanel()
    m.listPanel.translation = [m.listPanelX, m.listPanelY]
    
    m.listPanelBg.width = m.listPanelWidth
    m.listPanelBg.height = m.listPanelHeight
    m.listPanelBg.translation = [0, 0]
    
    m.songListContainer.translation = [m.paddingSmall, m.paddingSmall]
    
    m.scrollUpIndicator.width = m.listPanelWidth
    m.scrollUpIndicator.translation = [0, -int(5 * m.scaleFactor)]
    
    m.scrollDownIndicator.width = m.listPanelWidth
    m.scrollDownIndicator.translation = [0, m.listPanelHeight + int(3 * m.scaleFactor)]
end sub

sub setupDetailsPanel()
    m.detailsPanel.translation = [m.detailsPanelX, m.detailsPanelY]
    
    m.detailsPanelBg.width = m.detailsPanelWidth
    m.detailsPanelBg.height = m.detailsPanelHeight
    m.detailsPanelBg.translation = [0, 0]
    
    currentY = m.detailsPadding
    
    m.artworkGroup.translation = [m.detailsPadding, currentY]
    m.artworkBg.width = m.artworkWidth
    m.artworkBg.height = m.artworkHeight
    m.artworkBg.translation = [0, 0]
    m.artworkPlaceholder.width = m.artworkWidth
    m.artworkPlaceholder.height = m.artworkHeight
    m.artworkPlaceholder.translation = [0, 0]
    
    currentY = currentY + m.artworkHeight + m.paddingMed
    
    m.detailTitle.width = m.artworkWidth
    m.detailTitle.translation = [m.detailsPadding, currentY]
    currentY = currentY + int(30 * m.scaleFactor)
    
    m.detailArtist.width = m.artworkWidth
    m.detailArtist.translation = [m.detailsPadding, currentY]
    currentY = currentY + int(30 * m.scaleFactor)
    
    rowWidth = m.artworkWidth
    
    setupMetadataRow(m.difficultyRow, m.difficultyLabel, m.difficultyValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.rowSpacing
    
    setupMetadataRow(m.durationRow, m.durationLabel, m.durationValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.rowSpacing
    
    setupMetadataRow(m.bestScoreRow, m.bestScoreLabel, m.bestScoreValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.paddingMed
    
    m.playButton.translation = [m.detailsPadding, currentY]
    m.playBtnBg.width = m.playBtnWidth
    m.playBtnBg.height = m.playBtnHeight
    m.playBtnBg.translation = [0, 0]
    m.playBtnLabel.width = m.playBtnWidth
    m.playBtnLabel.height = m.playBtnHeight
    m.playBtnLabel.translation = [0, 0]
    
    ' QR code section below play button
    currentY = currentY + m.playBtnHeight + m.paddingMed
    qrSize = int(100 * m.scaleFactor)
    qrCenterX = int((m.detailsPanelWidth - qrSize) / 2)

    ' Label at top of QR section
    labelHeight = int(18 * m.scaleFactor)
    m.qrSection.translation = [0, currentY]
    m.qrLabel.width = m.detailsPanelWidth
    m.qrLabel.translation = [0, 0]

    ' Center QR image between label bottom and panel bottom
    spaceBelow = m.detailsPanelHeight - currentY - labelHeight
    qrOffsetY = labelHeight + int((spaceBelow - qrSize) / 2)
    m.qrImage.width = qrSize
    m.qrImage.height = qrSize
    m.qrImage.translation = [qrCenterX, qrOffsetY]
end sub

sub setupMetadataRow(rowGroup as object, labelNode as object, valueNode as object, yPos as integer, rowWidth as integer)
    rowGroup.translation = [m.detailsPadding, yPos]
    labelNode.translation = [0, 0]
    valueNode.width = rowWidth
    valueNode.translation = [0, 0]
end sub

sub onCatalogLoaded(event = invalid as dynamic)
    print "[SongSelect] onCatalogLoaded triggered"
    loadSongsFromCatalog()
end sub

sub loadSongsFromCatalog()
    catalog = m.top.songCatalog
    
    if catalog = invalid or catalog.songs = invalid or catalog.songs.count() = 0
        print "[SongSelect] No songs in catalog"
        m.noSongsLabel.visible = true
        return
    end if
    
    m.songs = catalog.songs
    m.noSongsLabel.visible = false
    
    print "[SongSelect] Loaded "; m.songs.count(); " songs"
    
    buildSongList()
    
    m.selectedIndex = 0
    updateSelection()
    updateDetails()
end sub

sub buildSongList()
    ' Clear existing song items
    while m.songListContainer.getChildCount() > 0
        m.songListContainer.removeChildIndex(0)
    end while
    m.songItems = []
    m.songItemBgs = []
    m.songItemTitles = []
    
    yPos = 0
    
    for i = 0 to m.songs.count() - 1
        song = m.songs[i]
        
        ' Create item group
        item = m.songListContainer.createChild("Group")
        item.translation = [0, yPos]
        
        ' Background
        bg = item.createChild("Rectangle")
        bg.width = m.itemWidth
        bg.height = m.itemHeight - int(3 * m.scaleFactor)
        bg.color = m.unselectedBgColor
        
        ' Row layout: [#] [Title/Artist] [Duration] [Stars]
        numWidth = int(35 * m.scaleFactor)
        titleStartX = int(40 * m.scaleFactor)
        titleWidth = int(m.itemWidth * 0.40)
        durStartX = int(m.itemWidth * 0.70)
        durWidth = int(m.itemWidth * 0.08)
        starsStartX = int(m.itemWidth * 0.79)
        starsWidth = int(m.itemWidth * 0.19)
        
        numLabel = item.createChild("Label")
        numLabel.translation = [int(10 * m.scaleFactor), int(14 * m.scaleFactor)]
        numLabel.text = (i + 1).toStr()
        numLabel.font = "font:SmallestSystemFont"
        numLabel.color = "0x636e72FF"
        numLabel.width = numWidth
        
        titleLabel = item.createChild("Label")
        titleLabel.translation = [titleStartX, int(5 * m.scaleFactor)]
        titleLabel.text = song.title
        titleLabel.font = "font:SmallestBoldSystemFont"
        titleLabel.color = m.unselectedTextColor
        titleLabel.width = titleWidth
        titleLabel.maxLines = 1
        
        artistLabel = item.createChild("Label")
        artistLabel.translation = [titleStartX, int(22 * m.scaleFactor)]
        artistLabel.text = song.artist
        artistLabel.font = "font:SmallestSystemFont"
        artistLabel.color = "0x636e72FF"
        artistLabel.width = titleWidth
        artistLabel.maxLines = 1
        
        durLabel = item.createChild("Label")
        durLabel.translation = [durStartX, int(14 * m.scaleFactor)]
        durLabel.text = formatDuration(song.length)
        durLabel.font = "font:SmallestSystemFont"
        durLabel.color = "0xb2bec3FF"
        durLabel.width = durWidth
        durLabel.horizAlign = "right"
        
        starsLabel = item.createChild("Label")
        starsLabel.translation = [starsStartX, int(14 * m.scaleFactor)]
        starsLabel.text = getDifficultyStars(song.difficultyRating)
        starsLabel.font = "font:SmallestSystemFont"
        starsLabel.color = "0xfdcb6eFF"
        starsLabel.width = starsWidth
        starsLabel.horizAlign = "right"
        
        m.songItems.push(item)
        m.songItemBgs.push(bg)
        m.songItemTitles.push(titleLabel)
        
        yPos = yPos + m.itemHeight
    end for
    
    updateScrollIndicators()
end sub

function getDifficultyStars(rating as Integer) as String
    stars = ""
    maxStars = 7
    for i = 1 to maxStars
        if i <= rating
            stars = stars + "★"
        else
            stars = stars + "☆"
        end if
    end for
    return stars
end function

function formatDuration(seconds as Integer) as String
    mins = int(seconds / 60)
    secs = seconds mod 60
    if secs < 10
        return mins.toStr() + ":0" + secs.toStr()
    else
        return mins.toStr() + ":" + secs.toStr()
    end if
end function

sub updateSelection()
    for i = 0 to m.songItemBgs.count() - 1
        bg = m.songItemBgs[i]
        titleLabel = m.songItemTitles[i]
        
        if i = m.selectedIndex
            bg.color = m.selectedBgColor
            titleLabel.color = m.selectedTextColor
        else
            bg.color = m.unselectedBgColor
            titleLabel.color = m.unselectedTextColor
        end if
    end for
    
    scrollToSelected()
end sub

sub scrollToSelected()
    visibleHeight = m.visibleItems * m.itemHeight
    
    selectedY = m.selectedIndex * m.itemHeight
    currentScroll = -m.songListContainer.translation[1]
    
    if selectedY < currentScroll
        newScroll = selectedY
        m.songListContainer.translation = [m.paddingSmall, -newScroll]
    else if selectedY + m.itemHeight > currentScroll + visibleHeight
        newScroll = selectedY + m.itemHeight - visibleHeight
        m.songListContainer.translation = [m.paddingSmall, -newScroll]
    end if
    
    updateScrollIndicators()
end sub

sub updateScrollIndicators()
    if m.songs.count() <= m.visibleItems
        m.scrollUpIndicator.visible = false
        m.scrollDownIndicator.visible = false
        return
    end if
    
    currentScroll = -m.songListContainer.translation[1]
    maxScroll = (m.songs.count() - m.visibleItems) * m.itemHeight
    
    m.scrollUpIndicator.visible = (currentScroll > 0)
    m.scrollDownIndicator.visible = (currentScroll < maxScroll)
end sub

sub updateDetails()
    if m.songs.count() = 0 then return
    
    song = m.songs[m.selectedIndex]
    
    m.detailTitle.text = song.title
    m.detailArtist.text = song.artist
    m.difficultyValue.text = getDifficultyStars(song.difficultyRating) + " " + song.difficulty
    m.durationValue.text = formatDuration(song.length)

    bestScore = loadBestScore(song.id)
    if bestScore > 0
        m.bestScoreValue.text = bestScore.toStr()
    else
        m.bestScoreValue.text = "---"
    end if
end sub

function loadBestScore(songId as String) as Integer
    section = CreateObject("roRegistrySection", "highscores")
    scoreStr = section.Read(songId)
    if scoreStr <> ""
        return scoreStr.toInt()
    end if
    return 0
end function

sub moveUp()
    if m.songs.count() = 0 then return
    
    m.selectedIndex = m.selectedIndex - 1
    if m.selectedIndex < 0
        m.selectedIndex = m.songs.count() - 1
    end if
    
    updateSelection()
    updateDetails()
end sub

sub moveDown()
    if m.songs.count() = 0 then return
    
    m.selectedIndex = m.selectedIndex + 1
    if m.selectedIndex >= m.songs.count()
        m.selectedIndex = 0
    end if
    
    updateSelection()
    updateDetails()
end sub

sub selectSong()
    if m.songs.count() = 0 then return
    
    song = m.songs[m.selectedIndex]
    print "[SongSelect] Selected: "; song.title
    m.top.selectedSong = song
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    
    handled = false
    
    if key = "up"
        moveUp()
        handled = true
    else if key = "down"
        moveDown()
        handled = true
    else if key = "OK"
        selectSong()
        handled = true
    else if key = "back"
        m.top.action = "back"
        handled = true
    end if
    
    return handled
end function
