sub init()
    initScreenDimensions()
    calculateLayout()
    setupReferences()
    setupLayout()
    setupGeometricBg()

    m.songs = []
    m.songItems = []
    m.songItemBgs = []
    m.songItemTitles = []
    m.songItemAccents = []
    m.selectedIndex = 0
    m.scrollOffset = 0

    m.accentPink = "0xFF1493FF"
    m.accentPinkDark = "0xCC1177FF"
    m.accentOrange = "0xFF6B35FF"
    m.cardBg = "0x1a1a1aEE"
    m.cardBgSelected = "0x2a2a2aFF"
    m.infoBg = "0x333333FF"
    m.selectedTextColor = "0xFFFFFFFF"
    m.unselectedTextColor = "0xDDDDDDFF"
    m.starColorActive = "0xFFAA00FF"
    m.starColorInactive = "0x555555FF"

    m.top.observeField("songCatalog", "onCatalogLoaded")
    m.top.setFocus(true)

    if m.top.songCatalog <> invalid
        loadSongsFromCatalog()
    end if
end sub

sub initScreenDimensions()
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    m.screenWidth = displaySize.w
    m.screenHeight = displaySize.h
    m.scaleFactor = m.screenHeight / 720.0
end sub

sub calculateLayout()
    m.headerHeight = int(48 * m.scaleFactor)
    m.headerAccentH = int(3 * m.scaleFactor)
    if m.headerAccentH < 2 then m.headerAccentH = 2

    m.listPanelX = 0
    m.listPanelY = m.headerHeight + m.headerAccentH
    m.listPanelWidth = int(m.screenWidth * 0.53)
    m.listPanelHeight = m.screenHeight - m.listPanelY - int(32 * m.scaleFactor)

    m.thumbSize = int(90 * m.scaleFactor)
    m.titleBarH = int(30 * m.scaleFactor)
    m.pinkBarH = int(28 * m.scaleFactor)
    m.starsBarH = int(28 * m.scaleFactor)
    m.metaBarH = int(22 * m.scaleFactor)
    m.cardHeight = m.titleBarH + m.pinkBarH + m.starsBarH + m.metaBarH
    m.cardGap = int(4 * m.scaleFactor)
    m.cardPadX = int(8 * m.scaleFactor)
    m.cardWidth = m.listPanelWidth - (m.cardPadX * 2)
    m.visibleItems = int(m.listPanelHeight / (m.cardHeight + m.cardGap))

    m.detailsPanelX = m.listPanelWidth
    m.detailsPanelY = m.headerHeight + m.headerAccentH
    m.detailsPanelWidth = m.screenWidth - m.listPanelWidth
    m.detailsPanelHeight = m.screenHeight - m.detailsPanelY - int(32 * m.scaleFactor)
    m.detailsPad = int(20 * m.scaleFactor)

    m.instructionsY = m.screenHeight - int(26 * m.scaleFactor)
    m.noSongsY = int(m.screenHeight * 0.4)
end sub

sub setupReferences()
    m.bgBase = m.top.findNode("bgBase")

    m.geoPolys = []
    for i = 1 to 8
        m.geoPolys.push(m.top.findNode("geoPoly" + i.toStr()))
    end for

    m.headerGroup = m.top.findNode("headerGroup")
    m.headerBg = m.top.findNode("headerBg")
    m.headerAccent = m.top.findNode("headerAccent")
    m.headerTitle = m.top.findNode("headerTitle")

    m.listPanel = m.top.findNode("listPanel")
    m.songListContainer = m.top.findNode("songListContainer")
    m.scrollUpIndicator = m.top.findNode("scrollUpIndicator")
    m.scrollDownIndicator = m.top.findNode("scrollDownIndicator")

    m.detailsPanel = m.top.findNode("detailsPanel")
    m.detailsPanelBg = m.top.findNode("detailsPanelBg")
    m.detailsPanelBorderLeft = m.top.findNode("detailsPanelBorderLeft")
    m.artworkGroup = m.top.findNode("artworkGroup")
    m.artworkBg = m.top.findNode("artworkBg")
    m.artworkPlaceholder = m.top.findNode("artworkPlaceholder")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailArtist = m.top.findNode("detailArtist")

    m.diffBadge = m.top.findNode("diffBadge")
    m.diffBadgeBg = m.top.findNode("diffBadgeBg")
    m.diffBadgeBorder = m.top.findNode("diffBadgeBorder")
    m.diffBadgeLabel = m.top.findNode("diffBadgeLabel")
    m.diffBadgeValue = m.top.findNode("diffBadgeValue")

    m.bestScoreRow = m.top.findNode("bestScoreRow")
    m.bestScoreBg = m.top.findNode("bestScoreBg")
    m.bestScoreLabel = m.top.findNode("bestScoreLabel")
    m.bestScoreValue = m.top.findNode("bestScoreValue")

    m.durationRow = m.top.findNode("durationRow")
    m.durationBg = m.top.findNode("durationBg")
    m.durationLabel = m.top.findNode("durationLabel")
    m.durationValue = m.top.findNode("durationValue")

    m.difficultyRow = m.top.findNode("difficultyRow")
    m.difficultyLabel = m.top.findNode("difficultyLabel")
    m.difficultyValue = m.top.findNode("difficultyValue")

    m.playButton = m.top.findNode("playButton")
    m.playBtnBg = m.top.findNode("playBtnBg")
    m.playBtnHighlight = m.top.findNode("playBtnHighlight")
    m.playBtnLabel = m.top.findNode("playBtnLabel")

    m.instructions = m.top.findNode("instructions")
    m.noSongsLabel = m.top.findNode("noSongsLabel")

    m.qrSection = m.top.findNode("qrSection")
    m.qrLabel = m.top.findNode("qrLabel")
    m.qrImage = m.top.findNode("qrImage")
end sub

sub setupLayout()
    m.bgBase.width = m.screenWidth
    m.bgBase.height = m.screenHeight

    setupHeader()
    setupListPanel()
    setupDetailsPanel()

    m.instructions.translation = [int(m.screenWidth / 2), m.instructionsY]
    m.instructions.width = m.screenWidth
    m.instructions.horizAlign = "center"

    m.noSongsLabel.translation = [int(m.screenWidth / 2), m.noSongsY]
    m.noSongsLabel.width = m.screenWidth
end sub

sub setupHeader()
    m.headerGroup.translation = [0, 0]

    m.headerBg.width = m.screenWidth
    m.headerBg.height = m.headerHeight
    m.headerBg.translation = [0, 0]

    m.headerAccent.width = m.screenWidth
    m.headerAccent.height = m.headerAccentH
    m.headerAccent.translation = [0, m.headerHeight]

    titlePad = int(20 * m.scaleFactor)
    m.headerTitle.width = m.screenWidth - titlePad * 2
    m.headerTitle.translation = [titlePad, int(12 * m.scaleFactor)]
end sub

sub setupListPanel()
    m.listPanel.translation = [m.listPanelX, m.listPanelY]
    m.songListContainer.translation = [m.cardPadX, int(6 * m.scaleFactor)]
    m.songListContainer.clippingRect = [0, 0, m.cardWidth, m.listPanelHeight - int(12 * m.scaleFactor)]

    m.scrollUpIndicator.width = m.listPanelWidth
    m.scrollUpIndicator.translation = [0, -int(2 * m.scaleFactor)]

    m.scrollDownIndicator.width = m.listPanelWidth
    m.scrollDownIndicator.translation = [0, m.listPanelHeight + int(2 * m.scaleFactor)]
end sub

sub setupDetailsPanel()
    m.detailsPanel.translation = [m.detailsPanelX, m.detailsPanelY]

    m.detailsPanelBg.width = m.detailsPanelWidth
    m.detailsPanelBg.height = m.detailsPanelHeight
    m.detailsPanelBg.translation = [0, 0]

    borderW = int(3 * m.scaleFactor)
    if borderW < 2 then borderW = 2
    m.detailsPanelBorderLeft.width = borderW
    m.detailsPanelBorderLeft.height = m.detailsPanelHeight
    m.detailsPanelBorderLeft.translation = [0, 0]

    currentY = m.detailsPad
    artW = m.detailsPanelWidth - m.detailsPad * 2
    artH = int(180 * m.scaleFactor)

    m.artworkGroup.translation = [m.detailsPad, currentY]
    m.artworkBg.width = artW
    m.artworkBg.height = artH
    m.artworkPlaceholder.width = artW
    m.artworkPlaceholder.height = artH
    m.artworkPlaceholder.translation = [0, 0]

    currentY = currentY + artH + int(12 * m.scaleFactor)

    m.detailTitle.translation = [m.detailsPad, currentY]
    m.detailTitle.width = artW
    m.detailTitle.maxLines = 2
    currentY = currentY + int(38 * m.scaleFactor)

    m.detailArtist.translation = [m.detailsPad, currentY]
    m.detailArtist.width = artW
    currentY = currentY + int(24 * m.scaleFactor)

    badgeW = int(160 * m.scaleFactor)
    badgeH = int(70 * m.scaleFactor)
    badgeX = int((m.detailsPanelWidth - badgeW) / 2)
    m.diffBadge.translation = [badgeX, currentY]

    m.diffBadgeBg.width = badgeW
    m.diffBadgeBg.height = badgeH

    bdrThick = int(2 * m.scaleFactor)
    if bdrThick < 2 then bdrThick = 2
    m.diffBadgeBorder.width = badgeW
    m.diffBadgeBorder.height = bdrThick
    m.diffBadgeBorder.translation = [0, badgeH - bdrThick]

    m.diffBadgeLabel.width = badgeW
    m.diffBadgeLabel.height = int(24 * m.scaleFactor)
    m.diffBadgeLabel.translation = [0, int(6 * m.scaleFactor)]

    m.diffBadgeValue.width = badgeW
    m.diffBadgeValue.height = int(40 * m.scaleFactor)
    m.diffBadgeValue.translation = [0, int(26 * m.scaleFactor)]

    currentY = currentY + badgeH + int(10 * m.scaleFactor)

    infoW = artW
    infoH = int(48 * m.scaleFactor)
    halfW = int((infoW - int(8 * m.scaleFactor)) / 2)

    m.bestScoreRow.translation = [m.detailsPad, currentY]
    m.bestScoreBg.width = halfW
    m.bestScoreBg.height = infoH
    m.bestScoreLabel.width = halfW
    m.bestScoreLabel.translation = [0, int(4 * m.scaleFactor)]
    m.bestScoreValue.width = halfW
    m.bestScoreValue.translation = [0, int(20 * m.scaleFactor)]

    m.durationRow.translation = [m.detailsPad + halfW + int(8 * m.scaleFactor), currentY]
    m.durationBg.width = halfW
    m.durationBg.height = infoH
    m.durationLabel.width = halfW
    m.durationLabel.translation = [0, int(4 * m.scaleFactor)]
    m.durationValue.width = halfW
    m.durationValue.translation = [0, int(20 * m.scaleFactor)]

    currentY = currentY + infoH + int(8 * m.scaleFactor)

    m.difficultyRow.translation = [m.detailsPad, currentY]
    m.difficultyRow.visible = false

    currentY = currentY + int(4 * m.scaleFactor)

    playW = artW
    playH = int(48 * m.scaleFactor)
    m.playButton.translation = [m.detailsPad, currentY]
    m.playBtnBg.width = playW
    m.playBtnBg.height = playH
    m.playBtnHighlight.width = playW
    m.playBtnHighlight.height = int(playH / 2)
    m.playBtnHighlight.translation = [0, 0]
    m.playBtnLabel.width = playW
    m.playBtnLabel.height = playH
    m.playBtnLabel.translation = [0, 0]

    currentY = currentY + playH + int(12 * m.scaleFactor)
    qrSize = int(80 * m.scaleFactor)
    qrCenterX = int((m.detailsPanelWidth - qrSize) / 2)

    m.qrSection.translation = [0, currentY]
    m.qrLabel.width = m.detailsPanelWidth
    m.qrLabel.translation = [0, 0]

    labelH = int(16 * m.scaleFactor)
    spaceBelow = m.detailsPanelHeight - currentY - labelH
    qrOffsetY = labelH + int((spaceBelow - qrSize) / 2)
    if qrOffsetY < labelH then qrOffsetY = labelH
    m.qrImage.width = qrSize
    m.qrImage.height = qrSize
    m.qrImage.translation = [qrCenterX, qrOffsetY]
end sub

sub setupGeometricBg()
    sw = m.screenWidth
    sh = m.screenHeight

    configs = [
        { idx: 0, x: int(sw * 0.55), y: 0, w: int(sw * 0.25), h: int(sh * 0.35) },
        { idx: 1, x: int(sw * 0.70), y: int(sh * 0.10), w: int(sw * 0.30), h: int(sh * 0.30) },
        { idx: 2, x: int(sw * 0.50), y: int(sh * 0.30), w: int(sw * 0.20), h: int(sh * 0.25) },
        { idx: 3, x: int(sw * 0.65), y: int(sh * 0.35), w: int(sw * 0.35), h: int(sh * 0.30) },
        { idx: 4, x: int(sw * 0.55), y: int(sh * 0.55), w: int(sw * 0.25), h: int(sh * 0.20) },
        { idx: 5, x: int(sw * 0.75), y: int(sh * 0.60), w: int(sw * 0.25), h: int(sh * 0.40) },
        { idx: 6, x: int(sw * 0.50), y: int(sh * 0.70), w: int(sw * 0.20), h: int(sh * 0.30) },
        { idx: 7, x: int(sw * 0.60), y: int(sh * 0.50), w: int(sw * 0.15), h: int(sh * 0.15) }
    ]

    for each cfg in configs
        poly = m.geoPolys[cfg.idx]
        poly.width = cfg.w
        poly.height = cfg.h
        poly.translation = [cfg.x, cfg.y]
        poly.rotation = (cfg.idx mod 3) * 0.15
    end for
end sub

sub onCatalogLoaded(event = invalid as dynamic)
    loadSongsFromCatalog()
end sub

sub loadSongsFromCatalog()
    catalog = m.top.songCatalog

    if catalog = invalid or catalog.songs = invalid or catalog.songs.count() = 0
        m.noSongsLabel.visible = true
        return
    end if

    m.songs = catalog.songs
    m.noSongsLabel.visible = false

    buildSongList()

    m.selectedIndex = 0
    updateSelection()
    updateDetails()
end sub

sub buildSongList()
    while m.songListContainer.getChildCount() > 0
        m.songListContainer.removeChildIndex(0)
    end while
    m.songItems = []
    m.songItemBgs = []
    m.songItemTitles = []
    m.songItemAccents = []

    yPos = 0
    sf = m.scaleFactor
    arrowW = int(16 * sf)

    for i = 0 to m.songs.count() - 1
        song = m.songs[i]

        item = m.songListContainer.createChild("Group")
        item.translation = [0, yPos]

        titleBg = item.createChild("Rectangle")
        titleBg.width = m.cardWidth
        titleBg.height = m.titleBarH
        titleBg.color = m.cardBg
        titleBg.translation = [0, 0]

        titleLabel = item.createChild("Label")
        titleLabel.translation = [int(12 * sf), int(6 * sf)]
        titleLabel.text = ucase(song.title)
        titleLabel.font = "font:SmallBoldSystemFont"
        titleLabel.color = "0xFFFFFFFF"
        titleLabel.width = m.cardWidth - int(24 * sf)
        titleLabel.maxLines = 1

        pinkY = m.titleBarH
        pinkBodyW = m.cardWidth - arrowW

        pinkBar = item.createChild("Rectangle")
        pinkBar.width = pinkBodyW
        pinkBar.height = m.pinkBarH
        pinkBar.translation = [0, pinkY]
        pinkBar.color = m.accentPink

        arrowTop = item.createChild("Rectangle")
        arrowTop.width = arrowW
        arrowTop.height = int(m.pinkBarH / 2)
        arrowTop.translation = [pinkBodyW, pinkY]
        arrowTop.color = m.accentPink
        arrowTop.rotation = 0.0

        arrowBot = item.createChild("Rectangle")
        arrowBot.width = arrowW
        arrowBot.height = int(m.pinkBarH / 2)
        arrowBot.translation = [pinkBodyW, pinkY + int(m.pinkBarH / 2)]
        arrowBot.color = m.accentPink
        arrowBot.rotation = 0.0

        arrowTip = item.createChild("Rectangle")
        arrowTip.width = arrowW
        arrowTip.height = m.pinkBarH
        arrowTip.translation = [pinkBodyW, pinkY]
        arrowTip.color = m.accentPink

        diffTag = item.createChild("Label")
        diffTag.translation = [int(12 * sf), pinkY + int(5 * sf)]
        diffTag.text = "DIFFICULTY"
        diffTag.font = "font:SmallBoldSystemFont"
        diffTag.color = "0xFFFFFFDD"
        diffTag.width = int(110 * sf)

        diffNum = item.createChild("Label")
        diffNum.translation = [int(125 * sf), pinkY + int(5 * sf)]
        diffNum.text = song.difficultyRating.toStr()
        diffNum.font = "font:SmallBoldSystemFont"
        diffNum.color = "0xFFFFFFFF"
        diffNum.width = int(40 * sf)

        artistTag = item.createChild("Label")
        artistTag.translation = [int(175 * sf), pinkY + int(5 * sf)]
        artistTag.text = "ARTIST"
        artistTag.font = "font:SmallBoldSystemFont"
        artistTag.color = "0xFFFFFFDD"
        artistTag.width = int(70 * sf)

        artistVal = item.createChild("Label")
        artistVal.translation = [int(250 * sf), pinkY + int(5 * sf)]
        artistVal.text = ucase(song.artist)
        artistVal.font = "font:SmallBoldSystemFont"
        artistVal.color = "0xFFFFFFFF"
        artistVal.width = pinkBodyW - int(260 * sf)
        artistVal.maxLines = 1

        starsY = pinkY + m.pinkBarH
        starsBg = item.createChild("Rectangle")
        starsBg.width = m.cardWidth
        starsBg.height = m.starsBarH
        starsBg.translation = [0, starsY]
        starsBg.color = "0xF0F0F0FF"

        starsLabel = item.createChild("Label")
        starsLabel.translation = [int(m.cardWidth / 2) - int(80 * sf), starsY + int(4 * sf)]
        starsLabel.text = getDifficultyStars(song.difficultyRating)
        starsLabel.font = "font:SmallSystemFont"
        starsLabel.color = m.starColorActive
        starsLabel.width = int(160 * sf)
        starsLabel.horizAlign = "center"

        metaY = starsY + m.starsBarH
        metaBg = item.createChild("Rectangle")
        metaBg.width = m.cardWidth
        metaBg.height = m.metaBarH
        metaBg.translation = [0, metaY]
        metaBg.color = "0x1a1a1aDD"

        durLabel = item.createChild("Label")
        durLabel.translation = [int(12 * sf), metaY + int(3 * sf)]
        durLabel.text = formatDuration(song.length)
        durLabel.font = "font:SmallestSystemFont"
        durLabel.color = "0x999999FF"
        durLabel.width = int(60 * sf)

        diffLabel = item.createChild("Label")
        diffLabel.translation = [int(75 * sf), metaY + int(3 * sf)]
        diffLabel.text = song.difficulty
        diffLabel.font = "font:SmallestBoldSystemFont"
        diffLabel.color = m.accentPink
        diffLabel.width = m.cardWidth - int(85 * sf)

        m.songItems.push(item)
        m.songItemBgs.push(titleBg)
        m.songItemTitles.push(titleLabel)
        m.songItemAccents.push(pinkBar)

        yPos = yPos + m.cardHeight + m.cardGap
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
        titleBg = m.songItemBgs[i]
        titleLabel = m.songItemTitles[i]
        pinkBar = m.songItemAccents[i]

        if i = m.selectedIndex
            titleBg.color = "0x2a2a2aFF"
            titleLabel.color = m.selectedTextColor
            pinkBar.color = m.accentPink
        else
            titleBg.color = m.cardBg
            titleLabel.color = m.unselectedTextColor
            pinkBar.color = m.accentPinkDark
        end if
    end for

    scrollToSelected()
end sub

sub scrollToSelected()
    totalItemH = m.cardHeight + m.cardGap
    visibleHeight = m.visibleItems * totalItemH

    selectedY = m.selectedIndex * totalItemH
    containerY = m.songListContainer.translation[1]
    currentScroll = -containerY + int(6 * m.scaleFactor)

    if selectedY < currentScroll
        newScroll = selectedY
        m.songListContainer.translation = [m.cardPadX, -newScroll + int(6 * m.scaleFactor)]
    else if selectedY + totalItemH > currentScroll + visibleHeight
        newScroll = selectedY + totalItemH - visibleHeight
        m.songListContainer.translation = [m.cardPadX, -newScroll + int(6 * m.scaleFactor)]
    end if

    updateScrollIndicators()
end sub

sub updateScrollIndicators()
    if m.songs.count() <= m.visibleItems
        m.scrollUpIndicator.visible = false
        m.scrollDownIndicator.visible = false
        return
    end if

    totalItemH = m.cardHeight + m.cardGap
    containerY = m.songListContainer.translation[1]
    currentScroll = -(containerY - int(6 * m.scaleFactor))
    maxScroll = (m.songs.count() - m.visibleItems) * totalItemH

    m.scrollUpIndicator.visible = (currentScroll > 10)
    m.scrollDownIndicator.visible = (currentScroll < maxScroll - 10)
end sub

sub updateDetails()
    if m.songs.count() = 0 then return

    song = m.songs[m.selectedIndex]

    m.detailTitle.text = ucase(song.title)
    m.detailArtist.text = song.artist

    m.diffBadgeValue.text = song.difficultyRating.toStr()
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
