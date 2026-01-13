' SongSelect.brs - Song selection screen (dynamically scaled)
' All positions use percentages of screen dimensions for device-agnostic layout

sub init()
    print "[SongSelect] Initializing..."
    
    ' Initialize screen dimensions
    initScreenDimensions()
    
    ' Calculate layout values
    calculateLayout()
    
    ' Get UI references
    setupReferences()
    
    ' Apply dynamic layout
    setupLayout()
    
    ' State
    m.songs = []
    m.songItems = []
    m.selectedIndex = 0
    m.scrollOffset = 0
    
    ' Styling
    m.selectedBgColor = "0x6c5ce7FF"
    m.unselectedBgColor = "0x2d3436AA"
    m.selectedTextColor = "0xFFFFFFFF"
    m.unselectedTextColor = "0xb2bec3FF"
    
    ' Set focus
    m.top.setFocus(true)
    
    print "[SongSelect] Initialization complete"
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
    
    ' Margins and padding
    m.marginH = int(m.screenWidth * 0.02)        ' ~2% horizontal margin
    m.marginV = int(m.screenHeight * 0.02)       ' ~2% vertical margin
    m.paddingSmall = int(10 * m.scaleFactor)
    m.paddingMed = int(15 * m.scaleFactor)
    m.panelGap = int(20 * m.scaleFactor)
    
    ' Header
    m.headerHeight = int(53 * m.scaleFactor)
    m.headerTitleY = int(17 * m.scaleFactor)
    
    ' Content area (below header)
    m.contentY = m.headerHeight + m.paddingMed
    m.contentHeight = m.screenHeight - m.contentY - int(80 * m.scaleFactor)  ' Leave room for footer
    
    ' Left panel (song list) - ~55% of width
    m.listPanelX = m.marginH
    m.listPanelY = m.contentY
    m.listPanelWidth = int(m.screenWidth * 0.55)
    m.listPanelHeight = m.contentHeight
    
    ' Song list item dimensions
    m.itemHeight = int(47 * m.scaleFactor)
    m.itemWidth = m.listPanelWidth - (m.paddingSmall * 2)
    m.visibleItems = int(m.listPanelHeight / m.itemHeight) - 1
    
    ' Right panel (details) - ~35% of width
    m.detailsPanelX = m.listPanelX + m.listPanelWidth + m.panelGap
    m.detailsPanelY = m.contentY
    m.detailsPanelWidth = int(m.screenWidth * 0.35)
    m.detailsPanelHeight = m.contentHeight
    
    ' Details panel internal layout
    m.detailsPadding = int(20 * m.scaleFactor)
    m.artworkWidth = m.detailsPanelWidth - (m.detailsPadding * 2)
    m.artworkHeight = int(120 * m.scaleFactor)
    
    ' Metadata rows
    m.rowHeight = int(24 * m.scaleFactor)
    m.rowSpacing = int(8 * m.scaleFactor)
    
    ' Play button
    m.playBtnWidth = m.detailsPanelWidth - (m.detailsPadding * 2)
    m.playBtnHeight = int(40 * m.scaleFactor)
    
    ' Footer - centered with details panel
    m.instructionsY = m.screenHeight - int(30 * m.scaleFactor)
    ' Center footer with the details panel
    m.instructionsX = m.detailsPanelX + (m.detailsPanelWidth / 2)
    
    ' No songs message
    m.noSongsY = int(m.screenHeight * 0.4)
end sub

sub setupReferences()
    ' Background
    m.background = m.top.findNode("background")
    
    ' Header
    m.headerGroup = m.top.findNode("headerGroup")
    m.headerBg = m.top.findNode("headerBg")
    m.headerTitle = m.top.findNode("headerTitle")
    
    ' List panel
    m.listPanel = m.top.findNode("listPanel")
    m.listPanelBg = m.top.findNode("listPanelBg")
    m.songListContainer = m.top.findNode("songListContainer")
    m.scrollUpIndicator = m.top.findNode("scrollUpIndicator")
    m.scrollDownIndicator = m.top.findNode("scrollDownIndicator")
    
    ' Details panel
    m.detailsPanel = m.top.findNode("detailsPanel")
    m.detailsPanelBg = m.top.findNode("detailsPanelBg")
    m.artworkGroup = m.top.findNode("artworkGroup")
    m.artworkBg = m.top.findNode("artworkBg")
    m.artworkPlaceholder = m.top.findNode("artworkPlaceholder")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailArtist = m.top.findNode("detailArtist")
    
    ' Metadata rows
    m.difficultyRow = m.top.findNode("difficultyRow")
    m.difficultyLabel = m.top.findNode("difficultyLabel")
    m.difficultyValue = m.top.findNode("difficultyValue")
    
    m.durationRow = m.top.findNode("durationRow")
    m.durationLabel = m.top.findNode("durationLabel")
    m.durationValue = m.top.findNode("durationValue")
    
    m.bestScoreRow = m.top.findNode("bestScoreRow")
    m.bestScoreLabel = m.top.findNode("bestScoreLabel")
    m.bestScoreValue = m.top.findNode("bestScoreValue")
    
    ' Play button
    m.playButton = m.top.findNode("playButton")
    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnLabel = m.top.findNode("playBtnLabel")
    
    ' Footer and messages
    m.instructions = m.top.findNode("instructions")
    m.noSongsLabel = m.top.findNode("noSongsLabel")
end sub

sub setupLayout()
    ' Background - full screen
    m.background.width = m.screenWidth
    m.background.height = m.screenHeight
    
    ' Header
    setupHeader()
    
    ' List panel
    setupListPanel()
    
    ' Details panel
    setupDetailsPanel()
    
    ' Footer - centered with details panel
    m.instructions.translation = [m.detailsPanelX, m.instructionsY]
    m.instructions.width = m.detailsPanelWidth
    m.instructions.horizAlign = "center"
    
    ' No songs message
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
    
    ' Scroll indicators
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
    
    ' Calculate internal positions
    currentY = m.detailsPadding
    
    ' Artwork
    m.artworkGroup.translation = [m.detailsPadding, currentY]
    m.artworkBg.width = m.artworkWidth
    m.artworkBg.height = m.artworkHeight
    m.artworkBg.translation = [0, 0]
    m.artworkPlaceholder.width = m.artworkWidth
    m.artworkPlaceholder.height = m.artworkHeight
    m.artworkPlaceholder.translation = [0, 0]
    
    currentY = currentY + m.artworkHeight + m.paddingMed
    
    ' Song title
    m.detailTitle.width = m.artworkWidth
    m.detailTitle.translation = [m.detailsPadding, currentY]
    currentY = currentY + int(30 * m.scaleFactor)
    
    ' Artist
    m.detailArtist.width = m.artworkWidth
    m.detailArtist.translation = [m.detailsPadding, currentY]
    currentY = currentY + int(30 * m.scaleFactor)
    
    ' Metadata rows
    rowWidth = m.artworkWidth
    
    ' Difficulty row
    setupMetadataRow(m.difficultyRow, m.difficultyLabel, m.difficultyValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.rowSpacing
    
    ' Duration row
    setupMetadataRow(m.durationRow, m.durationLabel, m.durationValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.rowSpacing
    
    ' Best score row
    setupMetadataRow(m.bestScoreRow, m.bestScoreLabel, m.bestScoreValue, currentY, rowWidth)
    currentY = currentY + m.rowHeight + m.paddingMed
    
    ' Play button
    m.playButton.translation = [m.detailsPadding, currentY]
    m.playBtnBg.width = m.playBtnWidth
    m.playBtnBg.height = m.playBtnHeight
    m.playBtnBg.translation = [0, 0]
    m.playBtnLabel.width = m.playBtnWidth
    m.playBtnLabel.height = m.playBtnHeight
    m.playBtnLabel.translation = [0, 0]
end sub

sub setupMetadataRow(rowGroup as object, labelNode as object, valueNode as object, yPos as integer, rowWidth as integer)
    rowGroup.translation = [m.detailsPadding, yPos]
    labelNode.translation = [0, 0]
    valueNode.width = rowWidth
    valueNode.translation = [0, 0]
end sub

' Called when song catalog is set
sub onCatalogLoaded()
    catalog = m.top.songCatalog
    
    if catalog = invalid or catalog.songs = invalid or catalog.songs.count() = 0
        print "[SongSelect] No songs in catalog"
        m.noSongsLabel.visible = true
        return
    end if
    
    m.songs = catalog.songs
    m.noSongsLabel.visible = false
    
    print "[SongSelect] Loaded "; m.songs.count(); " songs"
    
    ' Build song list UI
    buildSongList()
    
    ' Select first song
    m.selectedIndex = 0
    updateSelection()
    updateDetails()
end sub

' Build the visual song list
sub buildSongList()
    ' Clear existing
    m.songListContainer.removeChildrenIndex(m.songListContainer.getChildCount(), 0)
    m.songItems = []
    m.songItemBgs = []      ' Store direct references to backgrounds
    m.songItemTitles = []   ' Store direct references to title labels
    
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
        
        ' Layout: [Number | Title/Artist | Duration | Stars]
        numWidth = int(35 * m.scaleFactor)
        titleStartX = int(40 * m.scaleFactor)
        titleWidth = int(m.itemWidth * 0.40)  ' Limited width to prevent overflow
        durStartX = int(m.itemWidth * 0.70)   ' Duration starts at 70%
        durWidth = int(m.itemWidth * 0.08)    ' Duration gets 8% width
        starsStartX = int(m.itemWidth * 0.79) ' Stars start right after duration
        starsWidth = int(m.itemWidth * 0.19)  ' Stars get remaining space
        
        ' Song number
        numLabel = item.createChild("Label")
        numLabel.translation = [int(10 * m.scaleFactor), int(14 * m.scaleFactor)]
        numLabel.text = (i + 1).toStr()
        numLabel.font = "font:SmallestSystemFont"
        numLabel.color = "0x636e72FF"
        numLabel.width = numWidth
        
        ' Song title - smaller font to fit in box
        titleLabel = item.createChild("Label")
        titleLabel.translation = [titleStartX, int(5 * m.scaleFactor)]
        titleLabel.text = song.title
        titleLabel.font = "font:SmallestBoldSystemFont"
        titleLabel.color = m.unselectedTextColor
        titleLabel.width = titleWidth
        titleLabel.maxLines = 1
        
        ' Artist - smaller font to fit in box
        artistLabel = item.createChild("Label")
        artistLabel.translation = [titleStartX, int(22 * m.scaleFactor)]
        artistLabel.text = song.artist
        artistLabel.font = "font:SmallestSystemFont"
        artistLabel.color = "0x636e72FF"
        artistLabel.width = titleWidth
        artistLabel.maxLines = 1
        
        ' Duration - right-aligned, close to stars
        durLabel = item.createChild("Label")
        durLabel.translation = [durStartX, int(14 * m.scaleFactor)]
        durLabel.text = formatDuration(song.length)
        durLabel.font = "font:SmallestSystemFont"
        durLabel.color = "0xb2bec3FF"
        durLabel.width = durWidth
        durLabel.horizAlign = "right"
        
        ' Difficulty stars - right-aligned to edge
        starsLabel = item.createChild("Label")
        starsLabel.translation = [starsStartX, int(14 * m.scaleFactor)]
        starsLabel.text = getDifficultyStars(song.difficultyRating)
        starsLabel.font = "font:SmallestSystemFont"
        starsLabel.color = "0xfdcb6eFF"
        starsLabel.width = starsWidth
        starsLabel.horizAlign = "right"
        
        ' Store references
        m.songItems.push(item)
        m.songItemBgs.push(bg)
        m.songItemTitles.push(titleLabel)
        
        yPos = yPos + m.itemHeight
    end for
    
    updateScrollIndicators()
end sub

' Get difficulty stars string
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

' Format seconds to M:SS
function formatDuration(seconds as Integer) as String
    mins = int(seconds / 60)
    secs = seconds mod 60
    if secs < 10
        return mins.toStr() + ":0" + secs.toStr()
    else
        return mins.toStr() + ":" + secs.toStr()
    end if
end function

' Update visual selection
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
    
    ' Scroll if needed
    scrollToSelected()
end sub

' Scroll list to show selected item
sub scrollToSelected()
    visibleHeight = m.visibleItems * m.itemHeight
    
    ' Calculate required scroll
    selectedY = m.selectedIndex * m.itemHeight
    currentScroll = -m.songListContainer.translation[1]
    
    if selectedY < currentScroll
        ' Scroll up
        newScroll = selectedY
        m.songListContainer.translation = [m.paddingSmall, -newScroll]
    else if selectedY + m.itemHeight > currentScroll + visibleHeight
        ' Scroll down
        newScroll = selectedY + m.itemHeight - visibleHeight
        m.songListContainer.translation = [m.paddingSmall, -newScroll]
    end if
    
    updateScrollIndicators()
end sub

' Update scroll arrow indicators
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

' Update detail panel
sub updateDetails()
    if m.songs.count() = 0 then return
    
    song = m.songs[m.selectedIndex]
    
    m.detailTitle.text = song.title
    m.detailArtist.text = song.artist
    m.difficultyValue.text = getDifficultyStars(song.difficultyRating) + " " + song.difficulty
    m.durationValue.text = formatDuration(song.length)

    ' Load best score
    bestScore = loadBestScore(song.id)
    if bestScore > 0
        m.bestScoreValue.text = bestScore.toStr()
    else
        m.bestScoreValue.text = "---"
    end if
end sub

' Load best score from registry
function loadBestScore(songId as String) as Integer
    section = CreateObject("roRegistrySection", "highscores")
    scoreStr = section.Read(songId)
    if scoreStr <> ""
        return scoreStr.toInt()
    end if
    return 0
end function

' Move selection up
sub moveUp()
    if m.songs.count() = 0 then return
    
    m.selectedIndex = m.selectedIndex - 1
    if m.selectedIndex < 0
        m.selectedIndex = m.songs.count() - 1
    end if
    
    updateSelection()
    updateDetails()
end sub

' Move selection down
sub moveDown()
    if m.songs.count() = 0 then return
    
    m.selectedIndex = m.selectedIndex + 1
    if m.selectedIndex >= m.songs.count()
        m.selectedIndex = 0
    end if
    
    updateSelection()
    updateDetails()
end sub

' Select current song
sub selectSong()
    if m.songs.count() = 0 then return
    
    song = m.songs[m.selectedIndex]
    print "[SongSelect] Selected: "; song.title
    m.top.selectedSong = song
end sub

' Handle remote input
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
